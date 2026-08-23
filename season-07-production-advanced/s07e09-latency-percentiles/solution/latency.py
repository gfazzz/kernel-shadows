#!/usr/bin/env python3
"""latency.py — перцентили по гистограмме и честный вывод о регрессии (ЭТАЛОН).

    latency.py <до.txt> <после.txt>

Считает p50, p95 и p99 тем же способом, что и histogram_quantile: находит
корзину, в которую попал перцентиль, и линейно интерполирует внутри неё.
Вместе с числом печатает границы этой корзины — то есть то, чего сама
функция PromQL не показывает, а без чего число нельзя сравнивать.

Вывод в миллисекундах, целыми: доли миллисекунды здесь — шум интерполяции,
а не измерение (§4.3 плана курса).

Код возврата: 0 — разобрано, 1 — обнаружена регрессия, 2 — вход не понят.
"""

import re
import sys

BUCKET = re.compile(r'^([a-zA-Z_:][a-zA-Z0-9_:]*)_bucket\{le="([^"]+)"\}\s+(\d+)')
PLAIN = re.compile(r'^([a-zA-Z_:][a-zA-Z0-9_:]*)_(count|sum)\s+([0-9.]+)')

QUANTILES = (0.50, 0.95, 0.99)


def read_histogram(path):
    """Возвращает (список пар (граница, накопленный счёт), общее число).

    Границы сортируются по возрастанию, +Inf становится бесконечностью.
    Порядок строк в выдаче не гарантирован, полагаться на него нельзя.
    """
    buckets, total = [], None
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            if line.startswith("#"):
                continue
            m = BUCKET.match(line)
            if m:
                le = float("inf") if m.group(2) == "+Inf" else float(m.group(2))
                buckets.append((le, int(m.group(3))))
                continue
            m = PLAIN.match(line)
            if m and m.group(2) == "count":
                total = int(float(m.group(3)))
    if not buckets:
        raise ValueError(f"{path}: не найдено ни одной корзины _bucket")
    buckets.sort(key=lambda p: p[0])
    if total is None:
        total = buckets[-1][1]
    if buckets[-1][0] != float("inf"):
        raise ValueError(f"{path}: нет корзины le=\"+Inf\" — хвост неизвестен")
    if buckets[-1][1] != total:
        raise ValueError(f"{path}: +Inf={buckets[-1][1]}, а _count={total}")
    return buckets, total


def quantile(buckets, total, q):
    """Перцентиль и границы корзины, в которую он попал.

    Возвращает (значение_с, нижняя_граница_с, верхняя_граница_с).
    Ровно та же арифметика, что в histogram_quantile: линейная
    интерполяция внутри найденной корзины.
    """
    target = q * total
    lo_bound, lo_count = 0.0, 0
    for le, cum in buckets:
        if cum >= target:
            if le == float("inf"):
                # Всё, что известно про хвост: он за последней конечной
                # границей. Прибавить к ней нечего — интерполировать не в чем.
                return lo_bound, lo_bound, float("inf")
            if cum == lo_count:
                return lo_bound, lo_bound, le
            frac = (target - lo_count) / (cum - lo_count)
            return lo_bound + (le - lo_bound) * frac, lo_bound, le
        lo_bound, lo_count = le, cum
    return lo_bound, lo_bound, float("inf")


def ms(seconds):
    """Секунды в целые миллисекунды. Бесконечность печатается словом."""
    if seconds == float("inf"):
        return "inf"
    return str(int(seconds * 1000))


def verdict(before, after):
    """Сравнение по границам корзин, а не по интерполированным числам.

    Пересекающиеся корзины означают, что разница меньше разрешения
    измерения: сказать по ней ничего нельзя.
    """
    b_val, b_lo, b_hi = before
    a_val, a_lo, a_hi = after
    if b_lo == a_lo and b_hi == a_hi and int(b_val * 1000) == int(a_val * 1000):
        return "no-change"
    if a_lo >= b_hi:
        return "regression"
    if b_lo >= a_hi:
        return "improvement"
    return "inconclusive"


def main(argv):
    if len(argv) != 3:
        print(f"usage: {argv[0].split('/')[-1]} <до.txt> <после.txt>", file=sys.stderr)
        return 2
    try:
        b_buckets, b_total = read_histogram(argv[1])
        a_buckets, a_total = read_histogram(argv[2])
    except (OSError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        return 2

    b = {q: quantile(b_buckets, b_total, q) for q in QUANTILES}
    a = {q: quantile(a_buckets, a_total, q) for q in QUANTILES}

    print("BEFORE " + " ".join(f"p{int(q * 100)}={ms(b[q][0])}" for q in QUANTILES))
    print("AFTER  " + " ".join(f"p{int(q * 100)}={ms(a[q][0])}" for q in QUANTILES))
    for q in QUANTILES:
        print(f"BOUNDS p{int(q * 100)} before=[{ms(b[q][1])},{ms(b[q][2])}] "
              f"after=[{ms(a[q][1])},{ms(a[q][2])}]")

    result = verdict(b[0.95], a[0.95])
    print(f"VERDICT {result}")
    return 1 if result == "regression" else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
