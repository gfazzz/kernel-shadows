#!/usr/bin/env bash

# LILITH - AI помощник KERNEL SHADOWS
# Linux Infrastructure & Low-level Intelligence Threat Hunter
#
# Интерактивный CLI tool для студентов курса

set -euo pipefail

# Цвета для вывода
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Путь к корню проекта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# ASCII Art LILITH
print_logo() {
  echo -e "${PURPLE}"
  cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║    ██╗     ██╗██╗     ██╗████████╗██╗  ██╗                  ║
║    ██║     ██║██║     ██║╚══██╔══╝██║  ██║                  ║
║    ██║     ██║██║     ██║   ██║   ███████║                  ║
║    ██║     ██║██║     ██║   ██║   ██╔══██║                  ║
║    ███████╗██║███████╗██║   ██║   ██║  ██║                  ║
║    ╚══════╝╚═╝╚══════╝╚═╝   ╚═╝   ╚═╝  ╚═╝                  ║
║                                                              ║
║    Linux Infrastructure & Low-level Intelligence             ║
║    Threat Hunter                                             ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
  echo -e "${NC}"
}

# Случайные цитаты LILITH
get_random_quote() {
  local quotes=(
    "Я родилась в тенях. Unix — мой родной язык."
    "Root — это не привилегия. Это оружие."
    "Логи не врут. Люди — врут."
    "Каждый sudo — это ответственность."
    "Автоматизация — не лень. Это выживание."
    "Man pages существуют не просто так. Читай их."
    "Chmod 777 — признак паники или некомпетентности."
    "SSH без ключей? Ты шутишь?"
    "Backup есть. Проверка backup есть. Ты готов."
    "Kernel panic? Не паникуй. Смотри логи."
  )

  local random_index=$((RANDOM % ${#quotes[@]}))
  echo -e "${PURPLE}> ${quotes[$random_index]}${NC}"
}

# Помощь
show_help() {
  print_logo
  echo -e "${CYAN}Использование:${NC}"
  echo "  lilith.sh <команда> [аргументы]"
  echo ""
  echo -e "${CYAN}Команды:${NC}"
  echo "  help          Показать эту справку"
  echo "  quote         Случайная цитата LILITH"
  echo "  hint <ep>     Подсказка для эпизода (например: hint 01)"
  echo "  check <ep>    Проверить решение эпизода"
  echo "  status        Статус текущего эпизода"
  echo "  next          Показать следующий эпизод"
  echo "  version       Версия курса"
  echo ""
  echo -e "${CYAN}Примеры:${NC}"
  echo "  lilith.sh quote"
  echo "  lilith.sh hint 01"
  echo "  lilith.sh check 01"
  echo ""
  get_random_quote
}

# Подсказка для эпизода
# Найти каталог серии по её идентификатору: s03e07, s03e07-slug или 07
# (последнее — только для Season 1, ради совместимости со старым вызовом).
find_series() {
  local id="${1:-}"
  [[ -n "$id" ]] || return 1

  # Голый номер: считаем, что речь о первом сезоне.
  if [[ "$id" =~ ^[0-9]{1,2}$ ]]; then
    id="s01e$(printf '%02d' "$((10#$id))")"
  fi

  local hit
  hit=$(find "$PROJECT_ROOT"/season-*/ -maxdepth 1 -type d -name "${id}*" 2>/dev/null | sort | head -1)
  [[ -n "$hit" ]] || return 1
  printf '%s\n' "$hit"
}

show_hint() {
  local series="${1:-s01e01}"
  local ep_dir

  if ! ep_dir=$(find_series "$series"); then
    echo -e "${RED}✗ Серия $series не найдена${NC}"
    echo -e "${YELLOW}Формат: s03e07 или 07 (для первого сезона)${NC}"
    return 1
  fi

  local readme_file="$ep_dir/README.md"
  if [[ ! -f "$readme_file" ]]; then
    echo -e "${RED}✗ README.md не найден в $(basename "$ep_dir")${NC}"
    return 1
  fi

  echo -e "${PURPLE}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${PURPLE}║  LILITH HINT: $(basename "$ep_dir")${NC}"
  echo -e "${PURPLE}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""

  # В сериях v2.0 подсказка — это вопрос, который задаёт LILITH; ответ лежит
  # рядом под спойлером. Печатаем вопросы, ответы оставляем в README.
  if grep -q '^\*\*LILITH:\*\*' "$readme_file"; then
    echo -e "${YELLOW}Вопросы серии (ответы — в README под спойлерами):${NC}"
    grep '^\*\*LILITH:\*\*' "$readme_file" \
      | sed 's/^\*\*LILITH:\*\* \*«/  · /; s/»\*$//' | fold -s -w 72
  else
    echo -e "${YELLOW}Общие подсказки:${NC}"
    echo ""
    echo "1. Прочитай README.md серии целиком — задача в разделе «Задание»"
    echo "2. Критерии приёмки и диагностика — в mission.md"
    echo "3. Углубление и книги — в theory.md"
    echo "4. Запусти bash tests/test.sh: он говорит, чего не хватает"
    echo "5. Не спеши — понимание важнее скорости"
  fi

  echo ""
  get_random_quote
}

# Проверить решение серии
check_episode() {
  local series="${1:-s01e01}"
  local ep_dir

  if ! ep_dir=$(find_series "$series"); then
    echo -e "${RED}✗ Серия $series не найдена${NC}"
    echo -e "${YELLOW}Формат: s03e07 или 07 (для первого сезона)${NC}"
    return 1
  fi

  local test_script="$ep_dir/tests/test.sh"
  if [[ ! -f "$test_script" ]]; then
    echo -e "${YELLOW}⚠ Тесты не найдены в $(basename "$ep_dir")${NC}"
    return 1
  fi

  echo -e "${PURPLE}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${PURPLE}║  LILITH CHECK: $(basename "$ep_dir")${NC}"
  echo -e "${PURPLE}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""

  # Запустить тесты
  cd "$ep_dir" || exit 1
  bash "$test_script"

  local exit_code=$?

  echo ""
  if [[ $exit_code -eq 0 ]]; then
    echo -e "${GREEN}✓ Все тесты пройдены!${NC}"
    get_random_quote
  else
    echo -e "${RED}✗ Некоторые тесты провалились${NC}"
    echo -e "${YELLOW}Совет: Прочитай ошибки внимательно. Они говорят правду.${NC}"
  fi

  return $exit_code
}

# Статус текущего эпизода
show_status() {
  echo -e "${PURPLE}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${PURPLE}║  LILITH STATUS                                            ${NC}"
  echo -e "${PURPLE}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""

  # Определить текущий эпизод по pwd
  local current_dir=$(pwd)

  if [[ "$(basename "$current_dir")" =~ ^s[0-9][0-9]e[0-9][0-9]- ]]; then
    local episode_name=$(basename "$current_dir")
    echo -e "${CYAN}Текущая директория:${NC} $episode_name"

    # Проверить наличие файлов (v0.1.3: интегрированная структура)
    if [[ -f "README.md" ]]; then
      echo -e "${GREEN}✓${NC} README.md найден (интегрированное руководство)"

      # Проверить что это интегрированная версия
      if grep -q "🎯 Задание" "README.md"; then
        echo -e "${CYAN}  └─ ${NC}Интегрированная структура (v0.1.3+)"
      fi
    fi

    if [[ -f "starter.sh" ]]; then
      echo -e "${GREEN}✓${NC} starter.sh найден"
    fi

    if [[ -d "tests" ]]; then
      echo -e "${GREEN}✓${NC} tests/ директория найдена"
    fi

    if [[ -d "solution" ]]; then
      echo -e "${GREEN}✓${NC} solution/ директория найдена"
    fi
  else
    echo -e "${YELLOW}⚠ Вы не в директории эпизода${NC}"
    echo -e "Перейдите в: ${CYAN}season-NN-*/sNNeNN-*/${NC}"
  fi

  echo ""
  get_random_quote
}

# Следующий эпизод
show_next() {
  echo -e "${PURPLE}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${PURPLE}║  LILITH NEXT                                              ${NC}"
  echo -e "${PURPLE}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""

  # Определить текущий эпизод
  local current_dir=$(pwd)

  if [[ "$current_dir" == *"s01e01"* ]]; then
    echo -e "${CYAN}Следующий эпизод:${NC} Episode 02 - Shell Scripting Basics"
    echo -e "${YELLOW}Статус:${NC} В разработке"
  else
    echo -e "${YELLOW}⚠ Определение следующего эпизода...${NC}"
    echo -e "Пока доступен только Episode 01"
  fi

  echo ""
  get_random_quote
}

# Версия
show_version() {
  echo -e "${PURPLE}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${PURPLE}║  KERNEL SHADOWS                                           ${NC}"
  echo -e "${PURPLE}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${CYAN}Версия:${NC} 0.1.1 (Phase 2 Complete)"
  echo -e "${CYAN}Эпизодов готово:${NC} 1/32 (Episode 01)"
  echo -e "${CYAN}Прогресс:${NC} 12%"
  echo ""
  get_random_quote
}

# Главная функция
main() {
  local command="${1:-help}"

  case "$command" in
    help|--help|-h)
      show_help
      ;;
    quote)
      get_random_quote
      ;;
    hint)
      shift
      show_hint "$@"
      ;;
    check)
      shift
      check_episode "$@"
      ;;
    status)
      show_status
      ;;
    next)
      show_next
      ;;
    version|--version|-v)
      show_version
      ;;
    *)
      echo -e "${RED}✗ Неизвестная команда: $command${NC}"
      echo ""
      show_help
      exit 1
      ;;
  esac
}

# Запуск
main "$@"

