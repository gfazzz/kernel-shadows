#!/bin/bash

################################################################################
# EPISODE 09: Минимальный скрипт создания пользователей
# Season 3: System Administration
#
# ⚠️ ЗАДАНИЕ: Заполни TODO секции
#
# ВАЖНО: Этот скрипт делает ТОЛЬКО useradd/groupadd!
# Sudo, ACL, PAM настраиваются через конфигурационные файлы, НЕ bash!
################################################################################

set -euo pipefail  # Строгий режим

# Цвета для вывода
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Конфигурация
readonly USERS=("viktor" "alex" "anna" "dmitry")

################################################################################
# TODO 1: Функция создания пользователя
################################################################################
create_user() {
    local username="$1"

    # TODO: Проверить существование пользователя
    # Подсказка: if id "$username" &>/dev/null; then

    # ТВОЙ КОД ЗДЕСЬ:


    echo "Создаю пользователя: $username"

    # TODO: Создать пользователя с home и bash shell
    # Подсказка: sudo useradd -m -s /bin/bash -c "KERNEL SHADOWS Team" "$username"

    # ТВОЙ КОД ЗДЕСЬ:


    # TODO: Установить временный пароль
    # Подсказка: echo "$username:TempPass123!" | sudo chpasswd

    # ТВОЙ КОД ЗДЕСЬ:


    # TODO: Принудительная смена пароля при первом входе
    # Подсказка: sudo chage -d 0 "$username"

    # ТВОЙ КОД ЗДЕСЬ:


    echo -e "${GREEN}✓ Пользователь $username создан${NC}"
}

################################################################################
# TODO 2: Функция создания группы и добавления участников
################################################################################
create_group_with_members() {
    local group_name="$1"
    local members="$2"

    # TODO: Создать группу если не существует
    # Подсказка: if ! getent group "$group_name" &>/dev/null; then
    #                sudo groupadd "$group_name"

    # ТВОЙ КОД ЗДЕСЬ:


    # TODO: Добавить участников в группу
    # Подсказка: for member in $members; do
    #                sudo usermod -aG "$group_name" "$member"
    #            done

    # ТВОЙ КОД ЗДЕСЬ:

}

################################################################################
# Main функция
################################################################################
main() {
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║  EPISODE 09: Создание пользователей и групп           ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo

    # TODO 3: Создать всех пользователей
    echo "=== Шаг 1: Создание пользователей ==="

    # ТВОЙ КОД ЗДЕСЬ (используй цикл for):


    echo

    # TODO 4: Создать группы и добавить участников
    echo "=== Шаг 2: Создание групп ==="

    # Группы и их участники:
    # - operations: viktor dmitry
    # - security: alex anna
    # - forensics: anna
    # - devops: dmitry
    # - netadmin: alex

    # ТВОЙ КОД ЗДЕСЬ:
    # Подсказка: create_group_with_members "operations" "viktor dmitry"


    echo

    # TODO 5: Проверка членства в группах
    echo "=== Проверка членства ==="

    # ТВОЙ КОД ЗДЕСЬ:
    # Подсказка: for user in "${USERS[@]}"; do
    #                echo "$user: $(groups "$user")"
    #            done


    echo
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Пользователи и группы созданы!                       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo
    echo "📝 Следующие шаги:"
    echo "   1. Настрой sudo: starter/sudoers.d/ → /etc/sudoers.d/"
    echo "   2. Настрой limits: starter/security/limits.conf → /etc/security/"
    echo "   3. Настрой ACL для Anna: setfacl -m u:anna:r /var/log/auth.log"
    echo "   4. Создай shared directory: /var/operations/shared"
    echo
    echo "Референс: solution/"
    echo "Теория: README.md (Циклы 2-6)"
}

# Запуск
main "$@"

