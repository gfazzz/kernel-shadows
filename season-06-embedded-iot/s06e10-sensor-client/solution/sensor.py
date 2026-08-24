#!/usr/bin/env python3
"""sensor.py — клиент-датчик узла shadow_mesh (ЭТАЛОН, s06e10).

Читает DS18B20 через 1-wire, публикует телеметрию в брокер, переживает
обрывы связи. Ввод-вывод отделён от логики: всё, что можно проверить без
датчика и без сети, — обычные функции и классы без побочных эффектов.

Запуск:  sensor.py --node shadow-node-07 --sensor temp --device /sys/...
"""

import argparse
import json
import os
import random
import sys
import time

# Строка CRC от драйвера 1-wire заканчивается YES или NO. NO означает,
# что данные пришли битыми: длинный провод, наводка, плохой контакт.
CRC_OK = "YES"

# Значение, которым DS18B20 отвечает сразу после подачи питания, если
# измерения ещё не было. Оно проходит CRC и выглядит правдоподобно.
POWER_ON_RESET_C = 85.0

DEFAULT_UNIT = "C"


# ── Разбор показаний ────────────────────────────────────────────────

def parse_w1(text):
    """Разобрать вывод w1_slave. Вернуть градусы Цельсия или None.

    Формат драйвера — две строки:
        <9 байт> : crc=79 YES
        <9 байт> t=23062

    Вторая строка содержит температуру в ТЫСЯЧНЫХ долях градуса.
    None означает «показания нет», а не «ноль градусов»: разница
    принципиальная, ноль — валидная температура.
    """
    if not isinstance(text, str):
        return None
    lines = [ln.strip() for ln in text.strip().splitlines() if ln.strip()]
    if len(lines) < 2:
        return None
    # Проверка CRC — первое, что делаем. Битую строку разбирать нельзя:
    # 't=' в ней есть, и без проверки мы опубликуем мусор.
    if not lines[0].endswith(CRC_OK):
        return None
    marker = lines[1].find("t=")
    if marker < 0:
        return None
    raw = lines[1][marker + 2:].split()[0]
    try:
        milli = int(raw)
    except ValueError:
        return None
    return milli / 1000.0


def plausible(value, lo, hi, por=POWER_ON_RESET_C):
    """Похоже ли значение на настоящее измерение.

    Отсекает выход за физический диапазон площадки и особое значение
    85.0 — ответ датчика, который ещё не мерил.
    """
    if value is None:
        return False
    if value == por:
        return False
    return lo <= value <= hi


# ── Сообщение ───────────────────────────────────────────────────────

def topic_for(schema, node, sensor):
    """Тема по схеме сети. Схема приходит извне: она задана в acl брокера,
    и дублировать её в коде — значит однажды разойтись с ней."""
    return schema.format(node=node, sensor=sensor)


def build_message(node, sensor, value, ts, seq, unit=DEFAULT_UNIT):
    """Собрать полезную нагрузку.

    Метка времени — обязательна и ставится ЗДЕСЬ, а не потребителем:
    сообщение может пролежать в очереди часы, а брокер отдаст его как
    retained и через сутки. Без ts получатель не отличит свежее от
    протухшего — ровно та ошибка, что разобрана в s06e08.
    """
    payload = {
        "node": node,
        "sensor": sensor,
        "value": round(float(value), 3),
        "unit": unit,
        "ts": int(ts),
        "seq": int(seq),
    }
    # sort_keys — чтобы одинаковые данные давали одинаковый байт-в-байт
    # результат: так его можно сравнивать и кешировать.
    return json.dumps(payload, sort_keys=True, separators=(",", ":"))


# ── Переподключение ─────────────────────────────────────────────────

class Backoff:
    """Экспоненциальная задержка со случайным разбросом и потолком.

    Разброс (джиттер) обязателен: без него двадцать семь узлов, потерявших
    связь одновременно, вернутся тоже одновременно — и уронят брокер ровно
    в тот момент, когда он поднялся.
    """

    def __init__(self, base=1.0, cap=60.0, factor=2.0, jitter=0.5, rand=None):
        self.base = float(base)
        self.cap = float(cap)
        self.factor = float(factor)
        self.jitter = float(jitter)
        self._rand = rand or random.random
        self.attempt = 0

    def next_delay(self):
        raw = self.base * (self.factor ** self.attempt)
        raw = min(raw, self.cap)
        self.attempt += 1
        # разброс в обе стороны: [raw*(1-j), raw*(1+j)], но не выше потолка
        spread = raw * self.jitter
        delay = raw - spread + 2 * spread * self._rand()
        return max(0.0, min(delay, self.cap))

    def reset(self):
        self.attempt = 0


# ── Очередь на время обрыва ─────────────────────────────────────────

class Spool:
    """Ограниченная очередь сообщений.

    При переполнении отбрасывается САМОЕ СТАРОЕ. Для телеметрии свежее
    ценнее: потребителю нужна текущая температура, а не позавчерашняя.
    Для команд или платежей правило было бы обратным — и это решение
    принимают по смыслу данных, а не по удобству реализации.
    """

    def __init__(self, capacity):
        self.capacity = int(capacity)
        self._items = []
        self.dropped = 0

    def __len__(self):
        return len(self._items)

    def add(self, item):
        self._items.append(item)
        while len(self._items) > self.capacity:
            self._items.pop(0)
            self.dropped += 1
        return self.dropped

    def drain(self):
        items, self._items = self._items, []
        return items


# ── Ввод-вывод: тонкий слой поверх логики ───────────────────────────

def read_device(path):
    """Единственное место, где программа трогает файловую систему."""
    try:
        with open(path, "r", encoding="ascii", errors="replace") as fh:
            return fh.read()
    except OSError:
        return None


def load_kv(path):
    """Прочитать файл вида ключ=значение."""
    out = {}
    try:
        with open(path, "r", encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                out[k.strip()] = v.strip()
    except OSError:
        pass
    return out


def credentials(env=None):
    """Учётные данные — из окружения, никогда из исходника.

    Пароль в коде уезжает в систему контроля версий, оттуда в образ, а из
    образа — к тому, кто снял узел со столба.
    """
    env = os.environ if env is None else env
    return env.get("MQTT_USER"), env.get("MQTT_PASSWORD")


def run_cycle(state, raw_text, publish, now):
    """Один шаг работы: разобрать, проверить, отправить или отложить.

    publish(topic, payload) -> bool; False означает «связи нет».
    Возвращает словарь с тем, что произошло, — так шаг проверяется
    целиком, без сети и без датчика.
    """
    value = parse_w1(raw_text)
    if not plausible(value, state["lo"], state["hi"]):
        state["bad"] += 1
        return {"sent": 0, "spooled": 0, "skipped": 1}

    state["seq"] += 1
    topic = topic_for(state["schema"], state["node"], state["sensor"])
    payload = build_message(state["node"], state["sensor"], value,
                            now, state["seq"], state["unit"])

    pending = state["spool"].drain() + [(topic, payload)]
    sent = 0
    for i, (t, p) in enumerate(pending):
        if publish(t, p):
            sent += 1
            continue
        # связь пропала — остальное обратно в очередь, по порядку
        for item in pending[i:]:
            state["spool"].add(item)
        return {"sent": sent, "spooled": len(pending) - sent, "skipped": 0}
    state["backoff"].reset()
    return {"sent": sent, "spooled": 0, "skipped": 0}


def main(argv=None):
    p = argparse.ArgumentParser(description="клиент-датчик shadow_mesh")
    p.add_argument("--node", required=True)
    p.add_argument("--sensor", default="temp")
    p.add_argument("--device", required=True)
    p.add_argument("--limits", default="data/limits.txt")
    p.add_argument("--schema", default="data/topic_schema.txt")
    p.add_argument("--interval", type=float, default=10.0)
    p.add_argument("--once", action="store_true")
    args = p.parse_args(argv)

    lim = load_kv(args.limits)
    sch = load_kv(args.schema)
    state = {
        "node": args.node,
        "sensor": args.sensor,
        "schema": sch.get("telemetry", "shadow/{node}/telemetry/{sensor}"),
        "unit": lim.get("unit", DEFAULT_UNIT),
        "lo": float(lim.get("plausible_min_c", -40.0)),
        "hi": float(lim.get("plausible_max_c", 60.0)),
        "seq": 0,
        "bad": 0,
        "spool": Spool(int(lim.get("spool_capacity", 200))),
        "backoff": Backoff(float(lim.get("backoff_base_s", 1.0)),
                           float(lim.get("backoff_cap_s", 60.0)),
                           float(lim.get("backoff_factor", 2.0)),
                           float(lim.get("backoff_jitter", 0.5))),
    }

    def publish(topic, payload):           # заглушка вместо брокера
        print(f"{topic} {payload}")
        return True

    while True:
        raw = read_device(args.device)
        run_cycle(state, raw, publish, time.time())
        if args.once:
            return 0
        time.sleep(args.interval)


if __name__ == "__main__":
    sys.exit(main())
