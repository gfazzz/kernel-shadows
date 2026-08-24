#!/usr/bin/env python3
"""Строит журналы пяти источников из списка событий с известным временем.

    make_logs.py <каталог> [seed]

Печатает истину в stdout: по строке «<epoch> <источник> <хост> <текст>»,
отсортировано. Тест сравнивает с ней вывод проверяемой программы.

Генератор намеренно написан иначе, чем решение: он идёт от времени к
тексту, решение — от текста к времени.
"""
import os, random, sys
from datetime import datetime, timedelta, timezone

MONTHS = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
TZ_LOCAL = timezone(timedelta(hours=1))       # Europe/Zurich зимой
BOOT_EPOCH = 1763729337                        # 21 ноября 2025, 14:08:57 UTC

EVENTS = [
    ("firewall", "zurich-app3", "nft drop IN=bond0 SRC=185.220.101.47 DPT=22"),
    ("auth",     "zurich-app3", "Failed password for invalid user admin from 185.220.101.47 port 44112"),
    ("auth",     "zurich-app3", "Accepted publickey for deploy from 185.220.101.47 port 51234"),
    ("nginx",    "zurich-app3", "POST /api/upload HTTP/1.1 200 45"),
    ("audit",    "zurich-app3", "EXECVE argc=3 a0=/bin/sh a1=-c a2=curl"),
    ("audit",    "zurich-app3", "PATH name=/etc/ld.so.preload nametype=CREATE"),
    ("k8s",      "zurich-k8s1", "Normal Created pod/aurora-api-7d9f4 container aurora-api"),
    ("nginx",    "zurich-app3", "GET /api/orders HTTP/1.1 200 1841"),
    ("auth",     "zurich-app3", "session opened for user root by (uid=1001)"),
    ("audit",    "zurich-app3", "PATH name=/etc/systemd/system/dbus-broker-relay.service nametype=CREATE"),
    ("k8s",      "zurich-k8s1", "Warning BackOff pod/aurora-api-7d9f4 restarting failed container"),
    ("firewall", "zurich-app3", "nft accept IN=bond0 SRC=10.42.0.17 DPT=9100"),
]

def main(argv):
    if len(argv) < 2:
        print("usage: make_logs.py <каталог> [seed]", file=sys.stderr); return 2
    out = argv[1]
    rnd = random.Random(int(argv[2]) if len(argv) > 2 else 20261124)
    os.makedirs(out, exist_ok=True)

    base = datetime(2025, 11, 22, 13, 4, 11, tzinfo=timezone.utc)
    truth, files = [], {k: [] for k in ("auth", "nginx", "audit", "k8s", "firewall")}
    t = base
    for src, host, text in EVENTS:
        t = t + timedelta(seconds=rnd.randint(37, 900))
        epoch = int(t.timestamp())
        truth.append((epoch, src, host, text))
        loc = t.astimezone(TZ_LOCAL)
        if src == "auth":
            files["auth"].append(
                f"{MONTHS[loc.month-1]} {loc.day:2d} {loc:%H:%M:%S} {host} sshd[{rnd.randint(900,9999)}]: {text}")
        elif src == "nginx":
            m, rest = text.split(" ", 1)
            path, proto, code, size = rest.split(" ")
            files["nginx"].append(
                f'185.220.101.47 - - [{loc.day:02d}/{MONTHS[loc.month-1]}/{loc.year}:{loc:%H:%M:%S} +0100] '
                f'"{m} {path} {proto}" {code} {size}')
        elif src == "audit":
            kind, rest = text.split(" ", 1)
            files["audit"].append(
                f"type={kind} msg=audit({epoch}.{rnd.randint(100,999)}:{rnd.randint(100,999)}): {rest}")
        elif src == "k8s":
            files["k8s"].append(f"{t:%Y-%m-%dT%H:%M:%SZ} {host} {text}")
        else:
            files["firewall"].append(f"[{epoch - BOOT_EPOCH:10d}.{rnd.randint(100,999)}] {text}")

    # Порядок строк внутри файла перемешивается: программа не имеет права
    # полагаться на то, что журнал отсортирован.
    hdr = {
        "auth":     "# /var/log/auth.log, локальное время узла, года в строке нет\n",
        "nginx":    "# access.log, общий формат журнала, смещение в самой строке\n",
        "audit":    "# /var/log/audit/audit.log, время в секундах эпохи UTC\n",
        "k8s":      "# события кластера, RFC 3339, UTC\n",
        "firewall": "# журнал ядра, секунды с момента загрузки узла\n",
    }
    names = {"auth": "auth.log", "nginx": "nginx_access.log", "audit": "audit.log",
             "k8s": "k8s_events.log", "firewall": "firewall.log"}
    for k, lines in files.items():
        rnd.shuffle(lines)
        with open(os.path.join(out, names[k]), "w", encoding="utf-8") as fh:
            fh.write(hdr[k])
            fh.write("\n".join(lines) + "\n")

    with open(os.path.join(out, "sources.conf"), "w", encoding="utf-8") as fh:
        fh.write(f"""# Как читать каждый источник. Год для syslog и момент загрузки для
# журнала ядра взяты из инвентаря узла: в самих строках их нет.
year 2025
boot_epoch {BOOT_EPOCH}

# source <файл> format=<формат> tz=<смещение|utc|inline> host=<узел>
source auth.log         format=syslog   tz=+0100  host=zurich-app3
source nginx_access.log format=clf      tz=inline host=zurich-app3
source audit.log        format=auditd   tz=utc    host=zurich-app3
source k8s_events.log   format=rfc3339  tz=utc    host=zurich-k8s1
source firewall.log     format=uptime   tz=utc    host=zurich-app3
""")
    for epoch, src, host, text in sorted(truth):
        print(f"{epoch} {src} {host} {text}")
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
