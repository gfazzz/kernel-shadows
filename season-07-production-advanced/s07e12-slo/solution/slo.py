#!/usr/bin/env python3
"""slo.py — бюджет ошибок и скорость его расхода (ЭТАЛОН).

    slo.py <slo.conf> <measurements.txt>

Отвечает на два разных вопроса. Первый: уложились ли за окно — это про
прошлое и про разговор с заказчиком. Второй: с какой скоростью тратим
сейчас — это про то, будить ли человека.

Вся арифметика целочисленная, в миллионных долях. Проценты с плавающей
точкой между машинами и локалями не сравнивают (сквозное правило курса).

Код возврата: 0 — уложились, 1 — SLO нарушено, 2 — вход не разобран.
"""

import sys

PPM = 1_000_000


def read_conf(path):
    """Читает соглашение: окно, порог предупреждения, показатели, скорости."""
    conf = {"slos": [], "burns": [], "window_days": None, "budget_warn_pct": None}
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            parts = line.split()
            key = parts[0]
            if key == "window_days":
                conf["window_days"] = int(parts[1])
            elif key == "budget_warn_pct":
                conf["budget_warn_pct"] = int(parts[1])
            elif key == "slo":
                kv = dict(p.split("=", 1) for p in parts[2:] if "=" in p)
                conf["slos"].append({
                    "name": parts[1],
                    "target_ppm": int(kv["target_ppm"]),
                    "sli": kv["sli"],
                })
            elif key == "burn":
                kv = dict(p.split("=", 1) for p in parts[2:] if "=" in p)
                conf["burns"].append({"window": parts[1], "rate_x100": int(kv["rate_x100"])})
    if not conf["slos"] or conf["window_days"] is None or conf["budget_warn_pct"] is None:
        raise ValueError(f"{path}: соглашение неполно")
    return conf


def read_measurements(path):
    """Читает наблюдения по окнам: window <имя> <4 счётчика>."""
    windows = {}
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.split("#", 1)[0].strip()
            if not line.startswith("window "):
                continue
            _, name, rt, rg, lt, lg = line.split()
            windows[name] = {
                "requests": (int(rt), int(rg)),
                "latency": (int(lt), int(lg)),
            }
    if not windows:
        raise ValueError(f"{path}: не найдено ни одного окна")
    return windows


def budget(total, good, target_ppm):
    """Возвращает (допустимо плохих, фактически плохих, доля расхода в %).

    Допустимо плохих — это и есть бюджет ошибок: сколько запросов можно
    провалить, не нарушив обещания. Величина не моральная, а расчётная.
    """
    allowed = total * (PPM - target_ppm) // PPM
    bad = total - good
    used_pct = (bad * 100 // allowed) if allowed else (0 if bad == 0 else 100)
    return allowed, bad, used_pct


def main(argv):
    if len(argv) != 3:
        print(f"usage: {argv[0].split('/')[-1]} <slo.conf> <measurements.txt>", file=sys.stderr)
        return 2
    try:
        conf = read_conf(argv[1])
        windows = read_measurements(argv[2])
    except (OSError, ValueError, KeyError) as exc:
        print(str(exc), file=sys.stderr)
        return 2

    long_window = f"{conf['window_days']}d"
    if long_window not in windows:
        print(f"нет наблюдений за окно {long_window}", file=sys.stderr)
        return 2

    violated = False
    at_risk = False

    for slo in conf["slos"]:
        total, good = windows[long_window][slo["sli"]]
        if total == 0:
            print(f"пустое окно у показателя {slo['name']}", file=sys.stderr)
            return 2
        actual_ppm = good * PPM // total
        allowed, bad, used_pct = budget(total, good, slo["target_ppm"])
        if bad > allowed:
            verdict, violated = "violated", True
        elif used_pct >= conf["budget_warn_pct"]:
            verdict, at_risk = "burning", True
        else:
            verdict = "met"
        print(f"SLO {slo['name']} target_ppm={slo['target_ppm']} actual_ppm={actual_ppm} "
              f"budget_allowed={allowed} budget_spent={bad} budget_pct={used_pct} "
              f"verdict={verdict}")

    for burn in conf["burns"]:
        win = burn["window"]
        if win not in windows:
            continue
        for slo in conf["slos"]:
            total, good = windows[win][slo["sli"]]
            if total == 0:
                continue
            bad = total - good
            # Скорость расхода: доля плохих, делённая на допустимую долю.
            # Умножение на 100 — чтобы остаться в целых числах.
            allowed_ppm = PPM - slo["target_ppm"]
            rate_x100 = bad * PPM * 100 // (total * allowed_ppm)
            alert = "yes" if rate_x100 >= burn["rate_x100"] else "no"
            if alert == "yes":
                at_risk = True
            print(f"BURN {slo['name']} window={win} rate_x100={rate_x100} "
                  f"threshold_x100={burn['rate_x100']} alert={alert}")

    result = "violated" if violated else ("at-risk" if at_risk else "ok")
    print(f"VERDICT {result}")
    return 1 if violated else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
