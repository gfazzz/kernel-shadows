#!/usr/bin/env python3
"""blackhole.py — что отдать в blackhole, когда канал уже забит (ЭТАЛОН).

    blackhole.py <prefixes.txt> <policy.txt>

Задача не техническая, а решающая: фильтровать нечем — трафик не доходит
до узла, он умирает в канале провайдера. Единственное, что можно сделать
за минуту, — попросить провайдера перестать передавать в нашу сторону
трафик к части адресов. Он перестанет передавать **весь** трафик к ним,
включая законный: blackhole не различает.

Значит, вопрос сводится к выбору: какие префиксы отдать, чтобы остаток
влез в канал, а потеря ценности была наименьшей.

Выбор считается перебором подмножеств. Их 2^N, и при девяти префиксах это
512 вариантов — быстрее, чем произнести слово «эвристика». Жадный выбор
(сначала самое дешёвое за мегабит) считается тоже — чтобы было видно, на
сколько он хуже.

Вся арифметика целочисленная: мегабиты и условные единицы — счётные
величины, дробям здесь взяться неоткуда.

Часть префиксов неприкосновенна: их нельзя отдать по договору, и в
перебор они не входят. Отсюда же берётся случай «решение не принимается
здесь»: если неприкосновенное само по себе шире канала, выбирать нечего.

Код возврата: 0 — остаток влезает, 1 — не влезает ни при каком выборе,
2 — вход не разобран.
"""

import sys


def read_table(path):
    """Читает префиксы: prefix service total legit value."""
    rows = []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            parts = line.split()
            if len(parts) != 6:
                raise ValueError(f"{path}: строка не из шести полей: {line}")
            if parts[5] not in ("yes", "no"):
                raise ValueError(f"{path}: признак неприкосновенности не yes/no: {line}")
            rows.append({
                "prefix": parts[0],
                "service": parts[1],
                "total": int(parts[2]),
                "legit": int(parts[3]),
                "value": int(parts[4]),
                "critical": parts[5] == "yes",
            })
    if not rows:
        raise ValueError(f"{path}: ни одного префикса")
    return rows


def read_policy(path):
    """Читает пределы: ёмкость канала и допустимую занятость."""
    conf = {}
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            k, v = line.split()
            conf[k] = int(v)
    for key in ("uplink_capacity_mbps", "max_util_pct"):
        if key not in conf:
            raise ValueError(f"{path}: нет ключа {key}")
    # Ёмкость нулевого канала — не крайний случай, а испорченный вход:
    # делить на неё нечего, и решать в такой постановке тоже нечего.
    if conf["uplink_capacity_mbps"] <= 0:
        raise ValueError(f"{path}: ёмкость канала должна быть положительной")
    if not 1 <= conf["max_util_pct"] <= 100:
        raise ValueError(f"{path}: допустимая занятость вне диапазона 1..100")
    return conf


def best_choice(rows, limit):
    """Наименьшая потеря ценности среди наборов, после которых остаток влезает.

    Перебор подмножеств. При равной потере предпочитается тот набор, где
    меньше сброшено законного трафика, а при равенстве и этого — где
    меньше префиксов: решение должно быть одним и тем же при каждом
    запуске, иначе его нельзя ни проверить, ни объяснить.
    """
    total = sum(r["total"] for r in rows)
    # Неприкосновенные префиксы в перебор не входят: договор — такое же
    # ограничение задачи, как ёмкость канала, и обходить его нельзя.
    movable = [i for i, r in enumerate(rows) if not r["critical"]]
    best = None
    for mask in range(1 << len(movable)):
        idx = [movable[k] for k in range(len(movable)) if mask >> k & 1]
        dropped = sum(rows[i]["total"] for i in idx)
        if total - dropped > limit:
            continue
        cost = (sum(rows[i]["value"] for i in idx),
                sum(rows[i]["legit"] for i in idx),
                len(idx))
        if best is None or cost < best[0]:
            best = (cost, idx)
    return best


def greedy_choice(rows, limit):
    """То же жадно: сначала самое дешёвое за мегабит.

    Считается не ради результата, а ради сравнения: жадный выбор кажется
    очевидным и на этих данных теряет на четверть больше.
    """
    total = sum(r["total"] for r in rows)
    order = sorted((i for i, r in enumerate(rows) if not r["critical"]),
                   key=lambda i: (rows[i]["value"] * 10000 // rows[i]["total"],
                                  rows[i]["prefix"]))
    dropped, picked = 0, []
    for i in order:
        if total - dropped <= limit:
            break
        dropped += rows[i]["total"]
        picked.append(i)
    if total - dropped > limit:
        return None
    return sum(rows[i]["value"] for i in picked)


def main(argv):
    if len(argv) != 3:
        print(f"usage: {argv[0].split('/')[-1]} <prefixes.txt> <policy.txt>", file=sys.stderr)
        return 2
    try:
        rows = read_table(argv[1])
        conf = read_policy(argv[2])
    except (OSError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        return 2

    capacity = conf["uplink_capacity_mbps"]
    limit = capacity * conf["max_util_pct"] // 100
    total = sum(r["total"] for r in rows)

    best = best_choice(rows, limit)
    if best is None:
        # Не влезает даже при сбросе всего, что разрешено отдавать:
        # неприкосновенные службы сами по себе шире канала. Решение здесь
        # не принимается — оно выше по течению: фильтрующий центр,
        # flowspec, дополнительная ёмкость.
        for r in rows:
            print(f"PREFIX {r['prefix']} service={r['service']} total_mbps={r['total']} "
                  f"legit_mbps={r['legit']} value={r['value']} action=keep")
        print(f"TOTAL before_mbps={total} after_mbps={total} capacity_mbps={capacity} "
              f"limit_mbps={limit} headroom_pct=0")
        print("VERDICT impossible")
        return 1

    (lost_value, lost_legit, _), chosen = best
    drop = set(chosen)
    after = total - sum(rows[i]["total"] for i in chosen)

    for i, r in enumerate(rows):
        action = "blackhole" if i in drop else "keep"
        print(f"PREFIX {r['prefix']} service={r['service']} total_mbps={r['total']} "
              f"legit_mbps={r['legit']} value={r['value']} action={action}")

    headroom = (capacity - after) * 100 // capacity
    print(f"TOTAL before_mbps={total} after_mbps={after} capacity_mbps={capacity} "
          f"limit_mbps={limit} headroom_pct={headroom}")
    print(f"LOST value={lost_value} legit_mbps={lost_legit} prefixes={len(chosen)}")

    greedy = greedy_choice(rows, limit)
    if greedy is not None:
        print(f"GREEDY value={greedy} worse_by={greedy - lost_value}")
    print("VERDICT fits")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
