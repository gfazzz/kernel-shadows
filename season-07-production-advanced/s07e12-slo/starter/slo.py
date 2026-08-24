#!/usr/bin/env python3
"""slo.py — бюджет ошибок и скорость его расхода (СТАРТЕР).

С Season 7 каркас содержит только договор. Как считать — решаешь сам.

ВЫЗОВ
    slo.py <slo.conf> <measurements.txt>

ВХОД
    slo.conf — соглашение с заказчиком:
        window_days <n>
        budget_warn_pct <n>
        slo <имя> target_ppm=<n> sli=<requests|latency>
        burn <окно> rate_x100=<n>

    measurements.txt — счётчики по окнам:
        window <имя> <requests_total> <requests_good> <latency_total> <latency_good>

    Всё в целых числах и в миллионных долях: 995000 ppm — это 99.5 %.
    Проценты с плавающей точкой между машинами и локалями не сравнивают.

ВЫВОД
    По строке на каждый показатель за длинное окно:

        SLO <имя> target_ppm=<n> actual_ppm=<n> budget_allowed=<n>
                  budget_spent=<n> budget_pct=<n> verdict=<met|burning|violated>

    По строке на каждую пару «показатель × окно скорости»:

        BURN <имя> window=<окно> rate_x100=<n> threshold_x100=<n> alert=<yes|no>

    И одна итоговая:

        VERDICT <ok|at-risk|violated>

КОД ВОЗВРАТА
    0 — уложились, 1 — SLO нарушено, 2 — вход не разобран

ЧТО СЧИТАТЬ
    Бюджет ошибок — сколько запросов можно провалить, не нарушив обещания:

        allowed = total * (1e6 - target_ppm) / 1e6
        spent   = total - good
        pct     = spent * 100 / allowed

    Приговор показателя:
        violated  spent > allowed
        burning   pct >= budget_warn_pct
        met       иначе

    Скорость расхода за короткое окно — во сколько раз доля плохих больше
    допустимой доли. Умножается на 100, чтобы остаться в целых:

        rate_x100 = spent * 1e6 * 100 / (total * (1e6 - target_ppm))

    Итог: violated, если нарушен хоть один показатель; at-risk, если
    что-то горит или превышена скорость; иначе ok.

ЧТО ОТВЕРГАТЬ (код 2)
    - аргументов не два
    - файла нет
    - в соглашении нет ни одного показателя, окна или порога
    - в наблюдениях нет длинного окна
"""

import sys


def read_conf(path):
    """TODO: вернуть окно, порог предупреждения, список показателей и скоростей."""
    raise NotImplementedError


def read_measurements(path):
    """TODO: вернуть счётчики по окнам и показателям."""
    raise NotImplementedError


def budget(total, good, target_ppm):
    """TODO: вернуть (допустимо плохих, фактически плохих, доля расхода в %)."""
    raise NotImplementedError


def main(argv):
    if len(argv) != 3:
        print(f"usage: {argv[0].split('/')[-1]} <slo.conf> <measurements.txt>", file=sys.stderr)
        return 2
    # TODO: прочитать оба файла, посчитать бюджет за длинное окно,
    #       скорость расхода за короткие, напечатать строки и вернуть код.
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
