#!/usr/bin/env bash
#
# build_workspace.sh — s01e04 «Рабочее место» (ЭТАЛОН)
# Открывать после своей попытки.
#
# Это НЕ артефакт серии: артефакт — состояние файловой системы. Скрипт лишь
# показывает те же команды, что ты выполняешь руками, собранными в одном месте,
# и позволяет пересоздать результат одной строкой:
#
#   bash solution/build_workspace.sh
#
# Запускать из корня серии.

set -euo pipefail

SRV="../data/test_environment"                  # «сервер» Виктора
WS="${WS_OVERRIDE:-artifacts/workspace}"        # рабочее пространство операции
                                                # (WS_OVERRIDE использует тест для проверки
                                                #  эталона во временном каталоге)

# 1. Каркас каталогов. -p создаёт всю цепочку и не ругается, если каталог уже есть.
mkdir -p "${WS}/intel" "${WS}/tools" "${WS}/logs"

# 2. Копии добытых файлов. Оригиналы на «сервере» трогать нельзя — только cp.
cp "${SRV}/documents/briefing.txt"     "${WS}/intel/briefing.txt"
cp "${SRV}/documents/.secret_location" "${WS}/intel/meeting.txt"   # копия с говорящим именем
cp "${SRV}/.next_server"               "${WS}/intel/access.txt"

# 3. Журнал операции: пустой файл под будущие записи.
touch "${WS}/logs/operation.log"

# 4. Черновик, который создали и передумали — удаляем.
touch "${WS}/tmp_draft.txt"
rm -f "${WS}/tmp_draft.txt"

# 5. Инструмент из первой серии переезжает в tools/ (если он у тебя есть).
if [ -f "../s01e01-terminal-awakening/artifacts/whereami.sh" ]; then
    cp "../s01e01-terminal-awakening/artifacts/whereami.sh" "${WS}/tools/whereami.sh"
fi

echo "Рабочее пространство собрано: ${WS}"
find "${WS}" | sort
