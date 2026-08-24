#!/usr/bin/env python3
"""timeline.py — одна хронология из пяти журналов (ЭТАЛОН).

    timeline.py <каталог-журналов> <sources.conf>

Задача не в разборе форматов, а в приведении к одной оси. Пять источников
называют время четырьмя разными способами, и три из них не самодостаточны:
syslog не знает года, журнал ядра считает от загрузки, локальное время не
знает своего смещения. Недостающее лежит в sources.conf.

Вывод — по строке на событие, отсортировано по времени:

    EVENT <epoch> <источник> <хост> <текст>
    SUMMARY first=<epoch> last=<epoch> events=<n> sources=<k>

Код возврата: 0 — разобрано, 2 — вход не разобран.

Всё время внутри — целые секунды эпохи UTC. Понятие «местное время» в
хронологии инцидента не участвует вовсе: оно нужно только на входе, чтобы
прочитать строку, и на выходе, чтобы показать человеку.
"""

import calendar
import os
import re
import sys

MONTHS = {m: i + 1 for i, m in enumerate(
    ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"])}


def to_epoch(year, month, day, hh, mm, ss, offset_min):
    """Гражданское время плюс смещение — в секунды эпохи.

    calendar.timegm трактует набор как UTC; вычитание смещения переводит
    местное время в UTC. Именно вычитание: +01:00 означает, что местные
    часы впереди, значит момент наступил раньше по UTC.
    """
    return calendar.timegm((year, month, day, hh, mm, ss, 0, 0, 0)) - offset_min * 60


def parse_offset(tz):
    """«+0100» или «-0530» — в минуты. «utc» — ноль."""
    if tz in ("utc", "UTC", "Z", "+0000"):
        return 0
    m = re.fullmatch(r"([+-])(\d{2}):?(\d{2})", tz)
    if not m:
        raise ValueError(f"не разобрано смещение: {tz}")
    sign = 1 if m.group(1) == "+" else -1
    return sign * (int(m.group(2)) * 60 + int(m.group(3)))


def read_conf(path):
    conf = {"sources": [], "year": None, "boot_epoch": None}
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            parts = line.split()
            if parts[0] == "year":
                conf["year"] = int(parts[1])
            elif parts[0] == "boot_epoch":
                conf["boot_epoch"] = int(parts[1])
            elif parts[0] == "source":
                kv = dict(p.split("=", 1) for p in parts[2:] if "=" in p)
                conf["sources"].append({"file": parts[1], "format": kv["format"],
                                        "tz": kv.get("tz", "utc"), "host": kv["host"]})
    if not conf["sources"]:
        raise ValueError(f"{path}: не описано ни одного источника")
    return conf


RE_SYSLOG  = re.compile(r"^(\w{3})\s+(\d{1,2})\s+(\d{2}):(\d{2}):(\d{2})\s+\S+\s+[^:]+:\s*(.*)$")
RE_CLF     = re.compile(r'^(\S+) \S+ \S+ \[(\d{2})/(\w{3})/(\d{4}):(\d{2}):(\d{2}):(\d{2}) ([+-]\d{4})\]'
                        r' "([^"]*)" (\d{3}) (\S+)')
RE_AUDITD  = re.compile(r"^type=(\S+)\s+msg=audit\((\d+)\.\d+:\d+\):\s*(.*)$")
RE_RFC3339 = re.compile(r"^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z\s+(\S+)\s+(.*)$")
RE_UPTIME  = re.compile(r"^\[\s*(\d+)\.\d+\]\s*(.*)$")


def parse_file(path, src, conf):
    """Возвращает список (epoch, источник, хост, текст)."""
    kind = src["format"]
    name = {"syslog": "auth", "clf": "nginx", "auditd": "audit",
            "rfc3339": "k8s", "uptime": "firewall"}[kind]
    out = []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            if kind == "syslog":
                m = RE_SYSLOG.match(line)
                if not m:
                    continue
                # Года в строке нет — берётся из конфигурации узла.
                epoch = to_epoch(conf["year"], MONTHS[m.group(1)], int(m.group(2)),
                                 int(m.group(3)), int(m.group(4)), int(m.group(5)),
                                 parse_offset(src["tz"]))
                text = m.group(6)
            elif kind == "clf":
                m = RE_CLF.match(line)
                if not m:
                    continue
                # Смещение — в самой строке; конфигурация здесь не нужна.
                epoch = to_epoch(int(m.group(4)), MONTHS[m.group(3)], int(m.group(2)),
                                 int(m.group(5)), int(m.group(6)), int(m.group(7)),
                                 parse_offset(m.group(8)))
                text = f"{m.group(9)} {m.group(10)} {m.group(11)}"
            elif kind == "auditd":
                m = RE_AUDITD.match(line)
                if not m:
                    continue
                # Уже эпоха: ничего переводить не надо, и это единственный
                # формат из пяти, который самодостаточен.
                epoch = int(m.group(2))
                text = f"{m.group(1)} {m.group(3)}"
            elif kind == "rfc3339":
                m = RE_RFC3339.match(line)
                if not m:
                    continue
                epoch = to_epoch(int(m.group(1)), int(m.group(2)), int(m.group(3)),
                                 int(m.group(4)), int(m.group(5)), int(m.group(6)), 0)
                text = m.group(8)
            else:  # uptime
                m = RE_UPTIME.match(line)
                if not m:
                    continue
                # Секунды с загрузки. Момент загрузки — из конфигурации.
                if conf["boot_epoch"] is None:
                    raise ValueError("для журнала ядра нужен boot_epoch")
                epoch = conf["boot_epoch"] + int(m.group(1))
                text = m.group(2)
            out.append((epoch, name, src["host"], text))
    return out


def main(argv):
    if len(argv) != 3:
        print(f"usage: {os.path.basename(argv[0])} <каталог-журналов> <sources.conf>",
              file=sys.stderr)
        return 2
    logdir, confpath = argv[1], argv[2]
    try:
        conf = read_conf(confpath)
        if not os.path.isdir(logdir):
            raise ValueError(f"{logdir}: нет такого каталога")
        events = []
        for src in conf["sources"]:
            path = os.path.join(logdir, src["file"])
            if not os.path.isfile(path):
                raise ValueError(f"{path}: нет файла источника")
            events.extend(parse_file(path, src, conf))
    except (OSError, ValueError, KeyError) as exc:
        print(str(exc), file=sys.stderr)
        return 2

    if not events:
        print("ни одного события не разобрано", file=sys.stderr)
        return 2

    # Порядок фиксирован полностью: при совпадении времени сравниваются
    # источник и текст. Иначе вывод зависел бы от порядка чтения файлов.
    events.sort(key=lambda e: (e[0], e[1], e[3]))
    for epoch, name, host, text in events:
        print(f"EVENT {epoch} {name} {host} {text}")
    print(f"SUMMARY first={events[0][0]} last={events[-1][0]} "
          f"events={len(events)} sources={len(conf['sources'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
