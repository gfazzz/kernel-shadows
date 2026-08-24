#!/usr/bin/env python3
"""shadow_core.py — приёмка инфраструктуры (ЭТАЛОН).

    shadow_core.py <acceptance.txt> <каталог-состояния>

Не новая тема, а приёмка: двенадцать фаз, по одной на навык сезона, каждая
проверяет свойство и возвращает pass/fail. Порядок фаз фиксирован — это одна
операция. Курс заканчивается прогоном, который возвращает ноль или нет.

Вывод:
    PHASE <N> <сезон> <pass|FAIL> <описание>
    SUMMARY passed=<n> failed=<n> of=<N>

Код возврата: 0 — все фазы прошли, 1 — есть провал, 2 — вход не разобран.

Свойства, а не константы (§4.3 плана): «бюджет не превышен», «расхождений
нет», «действия внутри ордера» — не сверка с магическим числом, а проверка
инварианта, который переживёт обновление любого из сезонов.
"""

import os
import sys


def load_kv(path):
    """Файл 'ключ значение' → словарь. Комментарии и пустые строки — вон."""
    out = {}
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            parts = line.split(None, 1)
            out[parts[0]] = parts[1].strip() if len(parts) > 1 else ""
    return out


def load_lines(path):
    """Непустые некомментарные строки, отсортированы для сравнения."""
    out = []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.split("#", 1)[0].strip()
            if line:
                out.append(line)
    return sorted(out)


def check(kind, args, base):
    """Возвращает (ok, деталь). Отсутствие файла — это провал фазы, а не сбой."""
    def p(name):
        return os.path.join(base, name)

    try:
        if kind == "present":
            return (os.path.isfile(p(args[0])), args[0])
        if kind == "absent":
            return (not os.path.exists(p(args[0])), args[0])
        if kind == "kv":
            f, key, want = args[0], args[1], args[2]
            got = load_kv(p(f)).get(key)
            return (got == want, f"{key}={got}")
        if kind in ("max", "min"):
            f, key, bound = args[0], args[1], int(args[2])
            got = load_kv(p(f)).get(key)
            if got is None:
                return (False, f"{key} отсутствует")
            val = int(got)
            ok = val <= bound if kind == "max" else val >= bound
            return (ok, f"{key}={val} {'<=' if kind=='max' else '>='} {bound}")
        if kind == "same":
            a, b = load_lines(p(args[0])), load_lines(p(args[1]))
            return (a == b, "совпадают" if a == b else "есть расхождение")
        if kind == "subset":
            a, b = set(load_lines(p(args[0]))), set(load_lines(p(args[1])))
            extra = a - b
            return (not extra, "внутри" if not extra else f"вне: {sorted(extra)}")
    except (OSError, ValueError) as exc:
        return (False, str(exc))
    return (False, f"неизвестная проверка {kind}")


def read_plan(path):
    phases = []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            raw = line.rstrip("\n")
            body = raw.split("#", 1)[0].strip()
            if not body or not body.startswith("phase"):
                continue
            # phase <N> <сезон> <проверка> <аргументы...> "описание"
            desc = ""
            if '"' in raw:
                desc = raw.split('"')[1]
                body = raw.split('"')[0].strip()
            parts = body.split()
            phases.append({"n": int(parts[1]), "season": parts[2],
                           "kind": parts[3], "args": parts[4:], "desc": desc})
    if not phases:
        raise ValueError(f"{path}: ни одной фазы")
    return phases


def main(argv):
    if len(argv) != 3:
        print(f"usage: {os.path.basename(argv[0])} <acceptance.txt> <каталог-состояния>",
              file=sys.stderr)
        return 2
    plan_path, state = argv[1], argv[2]
    try:
        if not os.path.isdir(state):
            raise ValueError(f"{state}: нет каталога состояния")
        phases = read_plan(plan_path)
    except (OSError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        return 2

    passed = failed = 0
    for ph in sorted(phases, key=lambda x: x["n"]):
        ok, detail = check(ph["kind"], ph["args"], state)
        mark = "pass" if ok else "FAIL"
        if ok:
            passed += 1
        else:
            failed += 1
        print(f"PHASE {ph['n']:2d} {ph['season']:3s} {mark} {ph['desc']} [{detail}]")

    print(f"SUMMARY passed={passed} failed={failed} of={len(phases)}")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
