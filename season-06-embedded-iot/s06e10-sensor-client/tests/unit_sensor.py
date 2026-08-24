#!/usr/bin/env python3
"""s06e10 — юнит-тесты клиента-датчика (Type D).

Проверяется ПОВЕДЕНИЕ программы, а не текст исходника: файл импортируется
как модуль, функции вызываются напрямую. Ни датчика, ни сети, ни ожидания
не требуется — время и случайность передаются снаружи.

Ожидаемые значения не зашиты: температуры вычисляются из образцов в
data/w1_samples/, пределы и схема тем — из data/.
"""

import importlib.util
import io
import json
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
SERIES = os.path.dirname(HERE)
DATA = os.path.join(SERIES, "data")


def pick_subject():
    env = os.environ.get("SUBJECT")
    if env:
        return env
    for cand in (os.path.join(SERIES, "artifacts", "sensor.py"),
                 os.path.join(SERIES, "sensor.py"),
                 os.path.join(SERIES, "solution", "sensor.py")):
        if os.path.isfile(cand):
            return cand
    return None


SUBJECT = pick_subject()


def load_kv(path):
    out = {}
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            out[k.strip()] = v.strip()
    return out


LIM = load_kv(os.path.join(DATA, "limits.txt"))
SCH = load_kv(os.path.join(DATA, "topic_schema.txt"))


def sample(name):
    with open(os.path.join(DATA, "w1_samples", name), encoding="ascii") as fh:
        return fh.read()


def expected_from_sample(name):
    """Ожидаемая температура, вычисленная из образца независимо от кода."""
    text = sample(name)
    for line in text.splitlines():
        i = line.find("t=")
        if i >= 0:
            return int(line[i + 2:].split()[0]) / 1000.0
    return None


class ImportGuard:
    """Импорт не должен ничего печатать и ничего запускать."""

    def __init__(self):
        self.module = None
        self.noise = ""

    def load(self):
        buf_out, buf_err = io.StringIO(), io.StringIO()
        old_out, old_err = sys.stdout, sys.stderr
        sys.stdout, sys.stderr = buf_out, buf_err
        try:
            spec = importlib.util.spec_from_file_location("subject_sensor", SUBJECT)
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            self.module = mod
        finally:
            sys.stdout, sys.stderr = old_out, old_err
            self.noise = buf_out.getvalue() + buf_err.getvalue()
        return self.module


GUARD = ImportGuard()
M = GUARD.load()


class TestImport(unittest.TestCase):
    def test_import_silent(self):
        self.assertEqual(GUARD.noise, "",
                         "импорт модуля что-то напечатал: работа должна "
                         "начинаться только под if __name__ == '__main__'")

    def test_api_present(self):
        for name in ("parse_w1", "plausible", "topic_for", "build_message",
                     "Backoff", "Spool", "read_device", "credentials",
                     "run_cycle"):
            self.assertTrue(hasattr(M, name), f"нет {name}")

    def test_no_secrets_in_source(self):
        with open(SUBJECT, encoding="utf-8") as fh:
            src = fh.read()
        for needle in ("MQTT_PASSWORD =", "password = \"", "password = '",
                       "S3nsor!2025"):
            self.assertNotIn(needle, src,
                             "похоже на пароль в исходнике: учётные данные "
                             "берутся из окружения")


class TestParseW1(unittest.TestCase):
    def test_ok(self):
        want = expected_from_sample("ok.txt")
        self.assertAlmostEqual(M.parse_w1(sample("ok.txt")), want, places=3,
                               msg="значение в тысячных долях градуса")

    def test_negative(self):
        want = expected_from_sample("negative.txt")
        self.assertAlmostEqual(M.parse_w1(sample("negative.txt")), want, places=3,
                               msg="отрицательная температура тоже показание")

    def test_crc_fail_is_none(self):
        self.assertIsNone(M.parse_w1(sample("crc_fail.txt")),
                          "строка с CRC=NO содержит t=, но данные битые")

    def test_garbage_is_none(self):
        self.assertIsNone(M.parse_w1(sample("garbage.txt")))

    def test_empty_and_wrong_type(self):
        self.assertIsNone(M.parse_w1(""))
        self.assertIsNone(M.parse_w1(None))

    def test_none_is_not_zero(self):
        self.assertIsNot(M.parse_w1(sample("crc_fail.txt")), 0,
                         "«нет показания» и «ноль градусов» — разные вещи")


class TestPlausible(unittest.TestCase):
    def setUp(self):
        self.lo = float(LIM["plausible_min_c"])
        self.hi = float(LIM["plausible_max_c"])
        self.por = float(LIM["power_on_reset_c"])

    def test_normal_passes(self):
        self.assertTrue(M.plausible(expected_from_sample("ok.txt"), self.lo, self.hi))

    def test_none_fails(self):
        self.assertFalse(M.plausible(None, self.lo, self.hi))

    def test_out_of_range(self):
        self.assertFalse(M.plausible(self.hi + 1, self.lo, self.hi))
        self.assertFalse(M.plausible(self.lo - 1, self.lo, self.hi))

    def test_bounds_inclusive(self):
        self.assertTrue(M.plausible(self.lo, self.lo, self.hi))
        self.assertTrue(M.plausible(self.hi, self.lo, self.hi))

    def test_power_on_reset_rejected(self):
        por = expected_from_sample("power_on_reset.txt")
        self.assertEqual(por, self.por, "образец должен содержать 85.0")
        self.assertFalse(M.plausible(por, self.lo, self.hi),
                         "85.0 проходит CRC, но это ответ ещё не мерившего датчика")


class TestTopicAndMessage(unittest.TestCase):
    def test_topic_matches_schema(self):
        got = M.topic_for(SCH["telemetry"], "shadow-node-07", "temp")
        self.assertEqual(got, "shadow/shadow-node-07/telemetry/temp")

    def test_topic_uses_schema_not_hardcode(self):
        got = M.topic_for("iot/{node}/{sensor}", "n1", "hum")
        self.assertEqual(got, "iot/n1/hum",
                         "схема приходит извне: она задана в acl брокера")

    def test_message_is_json_with_required_fields(self):
        raw = M.build_message("shadow-node-07", "temp", 23.062, 1731920400, 5,
                              LIM["unit"])
        obj = json.loads(raw)
        for key in ("node", "sensor", "value", "unit", "ts", "seq"):
            self.assertIn(key, obj, f"в сообщении нет поля {key}")
        self.assertIsInstance(obj["value"], (int, float),
                              "значение должно быть числом, а не строкой")
        self.assertIsInstance(obj["ts"], int, "метка времени — целое")
        self.assertEqual(obj["unit"], LIM["unit"])
        self.assertEqual(obj["node"], "shadow-node-07")

    def test_message_is_deterministic(self):
        a = M.build_message("n", "temp", 1.5, 100, 1)
        b = M.build_message("n", "temp", 1.5, 100, 1)
        self.assertEqual(a, b, "одинаковые данные — одинаковый результат")


class TestBackoff(unittest.TestCase):
    def mk(self, rand):
        return M.Backoff(float(LIM["backoff_base_s"]),
                         float(LIM["backoff_cap_s"]),
                         float(LIM["backoff_factor"]),
                         float(LIM["backoff_jitter"]),
                         rand=rand)

    def test_grows(self):
        b = self.mk(lambda: 0.5)          # 0.5 -> без смещения
        d = [b.next_delay() for _ in range(4)]
        for prev, cur in zip(d, d[1:]):
            self.assertGreater(cur, prev, "задержка должна расти")

    def test_cap(self):
        b = self.mk(lambda: 1.0)          # максимальный разброс вверх
        cap = float(LIM["backoff_cap_s"])
        for _ in range(20):
            self.assertLessEqual(b.next_delay(), cap + 1e-9,
                                 "задержка не должна превышать потолок")

    def test_jitter_spreads(self):
        lo = self.mk(lambda: 0.0).next_delay()
        hi = self.mk(lambda: 1.0).next_delay()
        self.assertNotAlmostEqual(lo, hi, places=6,
                                  msg="без разброса все узлы вернутся одновременно")
        self.assertGreaterEqual(lo, 0.0)

    def test_reset(self):
        b = self.mk(lambda: 0.5)
        first = b.next_delay()
        for _ in range(5):
            b.next_delay()
        b.reset()
        self.assertAlmostEqual(b.next_delay(), first, places=6)


class TestSpool(unittest.TestCase):
    def test_bounded(self):
        cap = int(LIM["spool_capacity"])
        s = M.Spool(cap)
        for i in range(cap * 2):
            s.add(i)
        self.assertEqual(len(s), cap, "очередь не должна расти выше предела")

    def test_drops_oldest(self):
        s = M.Spool(3)
        for i in range(5):
            s.add(i)
        self.assertEqual(s.drain(), [2, 3, 4],
                         "отбрасывается самое старое: свежая телеметрия ценнее")

    def test_drain_empties(self):
        s = M.Spool(3)
        s.add("a")
        s.drain()
        self.assertEqual(len(s), 0)

    def test_dropped_counted(self):
        s = M.Spool(2)
        for i in range(5):
            s.add(i)
        self.assertEqual(s.dropped, 3, "потери должны быть посчитаны")


class TestCredentials(unittest.TestCase):
    def test_from_env(self):
        u, p = M.credentials({"MQTT_USER": "shadow-node-07", "MQTT_PASSWORD": "x"})
        self.assertEqual((u, p), ("shadow-node-07", "x"))

    def test_absent_is_none(self):
        u, p = M.credentials({})
        self.assertIsNone(u)
        self.assertIsNone(p)


class TestRunCycle(unittest.TestCase):
    def mkstate(self, cap=None):
        return {
            "node": "shadow-node-07",
            "sensor": "temp",
            "schema": SCH["telemetry"],
            "unit": LIM["unit"],
            "lo": float(LIM["plausible_min_c"]),
            "hi": float(LIM["plausible_max_c"]),
            "seq": 0,
            "bad": 0,
            "spool": M.Spool(cap or int(LIM["spool_capacity"])),
            "backoff": M.Backoff(1.0, 60.0, 2.0, 0.5, rand=lambda: 0.5),
        }

    def test_publishes_good_reading(self):
        st = self.mkstate()
        seen = []
        r = M.run_cycle(st, sample("ok.txt"), lambda t, p: seen.append((t, p)) or True, 1000)
        self.assertEqual(r["sent"], 1)
        self.assertEqual(len(seen), 1)
        self.assertEqual(seen[0][0], "shadow/shadow-node-07/telemetry/temp")
        self.assertAlmostEqual(json.loads(seen[0][1])["value"],
                               expected_from_sample("ok.txt"), places=3)

    def test_skips_bad_crc(self):
        st = self.mkstate()
        seen = []
        r = M.run_cycle(st, sample("crc_fail.txt"), lambda t, p: seen.append(1) or True, 1000)
        self.assertEqual(r["skipped"], 1)
        self.assertEqual(seen, [], "битое показание не публикуется")
        self.assertEqual(st["seq"], 0, "негодное показание не тратит номер")

    def test_spools_when_offline(self):
        st = self.mkstate()
        r = M.run_cycle(st, sample("ok.txt"), lambda t, p: False, 1000)
        self.assertEqual(r["sent"], 0)
        self.assertEqual(len(st["spool"]), 1, "при обрыве сообщение откладывается")

    def test_drains_after_reconnect(self):
        st = self.mkstate()
        for _ in range(3):
            M.run_cycle(st, sample("ok.txt"), lambda t, p: False, 1000)
        self.assertEqual(len(st["spool"]), 3)
        seen = []
        r = M.run_cycle(st, sample("ok.txt"), lambda t, p: seen.append(t) or True, 2000)
        self.assertEqual(r["sent"], 4, "накопленное уходит вместе со свежим")
        self.assertEqual(len(st["spool"]), 0)

    def test_seq_increases(self):
        st = self.mkstate()
        M.run_cycle(st, sample("ok.txt"), lambda t, p: True, 1000)
        M.run_cycle(st, sample("ok.txt"), lambda t, p: True, 1001)
        self.assertEqual(st["seq"], 2)

    def test_timestamp_from_argument(self):
        st = self.mkstate()
        seen = []
        M.run_cycle(st, sample("ok.txt"), lambda t, p: seen.append(p) or True, 1731920400)
        self.assertEqual(json.loads(seen[0])["ts"], 1731920400,
                         "время передаётся снаружи — иначе шаг не проверить")

    def test_spool_bounded_during_long_outage(self):
        st = self.mkstate(cap=5)
        for i in range(20):
            M.run_cycle(st, sample("ok.txt"), lambda t, p: False, 1000 + i)
        self.assertLessEqual(len(st["spool"]), 5,
                             "долгий обрыв не должен съедать память узла")


if __name__ == "__main__":
    if SUBJECT is None:
        print("не найден sensor.py")
        sys.exit(1)
    unittest.main(verbosity=0, exit=True)
