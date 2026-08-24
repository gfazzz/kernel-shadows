#!/usr/bin/env bash
# Строит эталонный перечень: путь относительно корня + контрольная сумма.
set -eu
R="$1"
hash_of() {
    if   command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
    elif command -v shasum    >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1
    else openssl dgst -sha256 "$1" | awk '{print $NF}'; fi
}
cd "$R"
find . -type f | LC_ALL=C sort | while read -r f; do
    printf '%s  %s\n' "${f#./}" "$(hash_of "$f")"
done
