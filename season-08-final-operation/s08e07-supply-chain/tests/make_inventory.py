#!/usr/bin/env python3
"""Строит инвентарь образов и перечень издателя.

    make_inventory.py <каталог> [seed]

Печатает истину: по строке «<категория> <образ>», отсортировано.
Категории: MISMATCH, UNPINNED, UNKNOWN, MIRROR.

Один образ может попасть в несколько категорий — так и в жизни.
"""
import os, random, sys

REGISTRIES_OK = ["registry.aurora.internal", "ghcr.io"]
BAD_REGISTRY = "registry-aurora.internal"      # дефис вместо точки

BASE = [
    ("aurora-api",        "2.8.4"),
    ("aurora-worker",     "2.8.4"),
    ("nginx-module-upload","2.4.1"),
    ("postgres",          "16.2"),
    ("redis",             "7.2.4"),
    ("node-exporter",     "1.7.0"),
    ("alertmanager",      "0.27.0"),
    ("prometheus",        "2.50.1"),
    ("fluent-bit",        "2.2.2"),
    ("cert-manager",      "1.14.4"),
]

def digest(rnd):
    return "sha256:" + "".join(rnd.choice("0123456789abcdef") for _ in range(64))

def main(argv):
    if len(argv) < 2:
        print("usage: make_inventory.py <каталог> [seed]", file=sys.stderr); return 2
    out = argv[1]; rnd = random.Random(int(argv[2]) if len(argv) > 2 else 20261125)
    os.makedirs(out, exist_ok=True)

    official, deployed, truth = [], [], []
    # Три образа портятся, остальные — в порядке. Какие именно — от seed.
    idx = list(range(len(BASE))); rnd.shuffle(idx)
    i_mismatch, i_unpinned, i_unknown, i_mirror = idx[0], idx[1], idx[2], idx[3]

    for i, (name, ver) in enumerate(BASE):
        d = digest(rnd)
        reg = REGISTRIES_OK[0] if i % 3 else REGISTRIES_OK[1]
        if i != i_unknown:
            official.append(f"{reg}/{name}:{ver} {d}")
        dep_reg, dep_dig, ref = reg, d, f"{reg}/{name}:{ver}"
        if i == i_mismatch:
            dep_dig = digest(rnd)
            truth.append(("MISMATCH", f"{reg}/{name}:{ver}"))
        if i == i_unpinned:
            dep_dig = "-"
            truth.append(("UNPINNED", f"{reg}/{name}:{ver}"))
        if i == i_unknown:
            truth.append(("UNKNOWN", f"{reg}/{name}:{ver}"))
        if i == i_mirror:
            dep_reg = BAD_REGISTRY
            ref = f"{dep_reg}/{name}:{ver}"
            truth.append(("MIRROR", ref))
            truth.append(("UNKNOWN", ref))   # в перечне издателя такого пути нет
        deployed.append(f"node{rnd.randint(1,50):02d} {ref} {dep_dig}")

    rnd.shuffle(deployed)
    with open(os.path.join(out, "deployed_images.txt"), "w", encoding="utf-8") as fh:
        fh.write("# Что реально запущено на узлах. Снято обходом кластера:\n"
                 "#   kubectl get pods -A -o jsonpath=… | sort -u\n"
                 "#\n"
                 "# Прочерк вместо отпечатка означает, что образ подтянут по метке:\n"
                 "# кластер не записал, что именно он скачал.\n"
                 "#\n# узел образ отпечаток\n")
        fh.write("\n".join(deployed) + "\n")
    with open(os.path.join(out, "official_digests.txt"), "w", encoding="utf-8") as fh:
        fh.write("# Перечень издателя: что и с каким отпечатком опубликовано.\n"
                 "# Получено из подписанного индекса реестра, не из кластера.\n"
                 "#\n# образ отпечаток\n")
        fh.write("\n".join(sorted(official)) + "\n")
    with open(os.path.join(out, "allowed_registries.txt"), "w", encoding="utf-8") as fh:
        fh.write("# Реестры, из которых разрешено тянуть образы.\n"
                 "# Список закрытый: всё остальное — находка, а не мелочь.\n#\n")
        fh.write("\n".join(REGISTRIES_OK) + "\n")

    for cat, ref in sorted(set(truth)):
        print(f"{cat} {ref}")
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
