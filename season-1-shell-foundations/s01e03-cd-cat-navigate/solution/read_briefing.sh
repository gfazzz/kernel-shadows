#!/usr/bin/env bash
#
# read_briefing.sh — s01e03 «Дойти и прочитать»
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Концепт: cd — перемещение по дереву; cat — прочитать файл.
# Type A — Bash Automation: скрипт заходит на "сервер" и читает три файла миссии.
#
# Требования среды: bash + coreutils, без root, без сети.

set -euo pipefail

# База — директория "сервера"; по умолчанию текущая.
base="${1:-.}"

# Навигация: телепортируемся внутрь (cd меняет директорию процесса-скрипта).
cd "${base}"
echo "=== Я здесь: $(pwd) ==="

# Читаем брифинг из поддиректории (относительный путь).
echo "=== documents/briefing.txt ==="
cat documents/briefing.txt

# Возвращаться не нужно: скрытые файлы — рядом, в текущей директории.
echo "=== .secret_location ==="
cat .secret_location

echo "=== .next_server ==="
cat .next_server
