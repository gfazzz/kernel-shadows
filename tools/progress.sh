#!/usr/bin/env bash

# KERNEL SHADOWS - Progress Tracker
# Отслеживание прогресса студента по эпизодам

set -euo pipefail

# Цвета
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m'

# Путь к проекту
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Файл для сохранения прогресса
PROGRESS_FILE="$PROJECT_ROOT/.progress"

# Создать файл прогресса если не существует
init_progress_file() {
  if [[ ! -f "$PROGRESS_FILE" ]]; then
    cat > "$PROGRESS_FILE" << 'EOF'
# KERNEL SHADOWS Progress Tracker
# Этот файл автоматически создаётся tools/progress.sh
# Формат: season-episode:status:timestamp
# Статусы: not_started, in_progress, completed
EOF
  fi
}

# Получить статус эпизода
get_episode_status() {
  local season="$1"
  local episode="$2"
  local key="s${season}-e${episode}"

  if [[ -f "$PROGRESS_FILE" ]]; then
    local line=$(grep "^$key:" "$PROGRESS_FILE" 2>/dev/null || echo "")
    if [[ -n "$line" ]]; then
      echo "$line" | cut -d: -f2
      return 0
    fi
  fi

  echo "not_started"
}

# Установить статус эпизода
set_episode_status() {
  local season="$1"
  local episode="$2"
  local status="$3"
  local key="s${season}-e${episode}"
  local timestamp=$(date +%Y-%m-%d)

  init_progress_file

  # Удалить старую запись если есть
  sed -i "/^$key:/d" "$PROGRESS_FILE" 2>/dev/null || true

  # Добавить новую запись
  echo "$key:$status:$timestamp" >> "$PROGRESS_FILE"
}

# Проверить завершённость эпизода (по тестам)
check_episode_completion() {
  local season="$1"
  local episode="$2"

  local episode_path="$PROJECT_ROOT/season-${season}-*/episode-${episode}-*"

  if ! compgen -G "$episode_path" > /dev/null; then
    return 1
  fi

  local ep_dir=$(compgen -G "$episode_path" | head -1)
  local test_script="$ep_dir/tests/test.sh"

  if [[ ! -f "$test_script" ]]; then
    return 1
  fi

  # Запустить тесты тихо
  cd "$ep_dir" || return 1
  bash "$test_script" &>/dev/null

  return $?
}

# Прогресс бар
print_progress_bar() {
  local completed="${1:-0}"
  local total="${2:-32}"
  local width=40

  # Защита от деления на 0
  [[ $total -eq 0 ]] && total=1

  # Безопасные вычисления
  local percent=$(( (completed * 100) / total ))
  local filled=$(( (completed * width) / total ))
  local empty=$(( width - filled ))

  echo -ne "${BLUE}["

  # Заполненная часть
  local i
  for ((i=0; i<filled; i++)); do
    echo -ne "█"
  done

  # Пустая часть
  for ((i=0; i<empty; i++)); do
    echo -ne "░"
  done

  echo -ne "]${NC} ${percent}%"
}

# Эмодзи статуса
get_status_emoji() {
  local status="$1"
  case "$status" in
    completed)
      echo -e "${GREEN}✅${NC}"
      ;;
    in_progress)
      echo -e "${YELLOW}⏳${NC}"
      ;;
    not_started)
      echo -e "${GRAY}⭕${NC}"
      ;;
    *)
      echo -e "${GRAY}❓${NC}"
      ;;
  esac
}

# Показать общий прогресс
show_overall_progress() {
  echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${PURPLE}║  KERNEL SHADOWS - Progress Tracker                           ║${NC}"
  echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""

  local total_episodes=32
  local completed=0
  local in_progress=0

  # Подсчитать завершённые эпизоды
  if [[ -f "$PROGRESS_FILE" ]]; then
    completed=$(grep -c ":completed:" "$PROGRESS_FILE" 2>/dev/null)
    in_progress=$(grep -c ":in_progress:" "$PROGRESS_FILE" 2>/dev/null)
  fi

  # Убедиться что переменные числовые (удалить любые не-цифры)
  completed=$(echo "$completed" | tr -cd '0-9')
  in_progress=$(echo "$in_progress" | tr -cd '0-9')

  # Если пустые - установить 0
  : ${completed:=0}
  : ${in_progress:=0}

  echo -e "${CYAN}Общий прогресс:${NC}"
  echo -ne "  "
  print_progress_bar "$completed" "$total_episodes"
  echo " ($completed/$total_episodes эпизодов)"
  echo ""

  echo -e "${CYAN}Статистика:${NC}"
  echo -e "  ${GREEN}✅ Завершено:${NC} $completed"
  echo -e "  ${YELLOW}⏳ В процессе:${NC} $in_progress"
  echo -e "  ${GRAY}⭕ Не начато:${NC} $((total_episodes - completed - in_progress))"
  echo ""
}

# Показать прогресс сезона
show_season_progress() {
  local season="${1:-1}"

  echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${PURPLE}║  Season $season Progress                                          ║${NC}"
  echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""

  # Определить эпизоды сезона
  local episodes_per_season=4
  local start_ep=$(( (season - 1) * episodes_per_season + 1 ))
  local end_ep=$(( season * episodes_per_season ))

  local season_completed=0

  for ep in $(seq -w $start_ep $end_ep); do
    local status=$(get_episode_status "$season" "$ep")
    local emoji=$(get_status_emoji "$status")

    # Название эпизода (если существует)
    local episode_path="$PROJECT_ROOT/season-${season}-*/episode-${ep}-*"
    local episode_name="Episode $ep"

    if compgen -G "$episode_path" > /dev/null 2>&1; then
      local ep_dir=$(compgen -G "$episode_path" | head -1)
      episode_name=$(basename "$ep_dir" | sed 's/episode-[0-9]*-//' | tr '-' ' ' | sed 's/\b\w/\u&/g')
      episode_name="Episode $ep: $episode_name"

      if [[ "$status" == "completed" ]]; then
        ((season_completed++))
      fi
    else
      episode_name="Episode $ep: (В разработке)"
    fi

    echo -e "  $emoji  $episode_name"
  done

  echo ""
  echo -e "${CYAN}Прогресс сезона:${NC}"
  echo -ne "  "
  print_progress_bar "$season_completed" "$episodes_per_season"
  echo " ($season_completed/$episodes_per_season)"
  echo ""
}

# Показать все сезоны
show_all_seasons() {
  show_overall_progress

  echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
  echo ""

  # Season 1
  show_season_progress 1

  # Season 2-8 (заглушка)
  for season in {2..8}; do
    echo -e "${GRAY}Season $season: В разработке${NC}"
  done

  echo ""
  echo -e "${PURPLE}> Продолжай работать. Каждый эпизод — шаг к мастерству.${NC}"
}

# Отметить эпизод как начатый
mark_started() {
  local season="$1"
  local episode="$2"

  set_episode_status "$season" "$episode" "in_progress"
  echo -e "${YELLOW}⏳ Episode $episode помечен как 'в процессе'${NC}"
}

# Отметить эпизод как завершённый
mark_completed() {
  local season="$1"
  local episode="$2"

  # Проверить через тесты
  if check_episode_completion "$season" "$episode"; then
    set_episode_status "$season" "$episode" "completed"
    echo -e "${GREEN}✅ Episode $episode помечен как 'завершён'!${NC}"
  else
    echo -e "${YELLOW}⚠ Тесты не пройдены. Эпизод отмечен как 'в процессе'${NC}"
    set_episode_status "$season" "$episode" "in_progress"
  fi
}

# Сбросить прогресс
reset_progress() {
  if [[ -f "$PROGRESS_FILE" ]]; then
    rm "$PROGRESS_FILE"
    echo -e "${GREEN}✓ Прогресс сброшен${NC}"
  else
    echo -e "${YELLOW}⚠ Файл прогресса не найден${NC}"
  fi
}

# Помощь
show_help() {
  echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${PURPLE}║  KERNEL SHADOWS - Progress Tracker                           ║${NC}"
  echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${CYAN}Использование:${NC}"
  echo "  progress.sh [команда] [аргументы]"
  echo ""
  echo -e "${CYAN}Команды:${NC}"
  echo "  (нет)             Показать общий прогресс"
  echo "  season <N>        Показать прогресс сезона N"
  echo "  all               Показать все сезоны"
  echo "  start <S> <E>     Отметить эпизод как начатый (Season Episode)"
  echo "  complete <S> <E>  Отметить эпизод как завершённый"
  echo "  reset             Сбросить весь прогресс"
  echo "  help              Показать эту справку"
  echo ""
  echo -e "${CYAN}Примеры:${NC}"
  echo "  progress.sh                    # Общий прогресс"
  echo "  progress.sh season 1           # Прогресс Season 1"
  echo "  progress.sh all                # Все сезоны"
  echo "  progress.sh start 1 01         # Начать Episode 01"
  echo "  progress.sh complete 1 01      # Завершить Episode 01"
  echo ""
}

# Главная функция
main() {
  init_progress_file

  local command="${1:-default}"

  case "$command" in
    default)
      show_overall_progress
      ;;
    all)
      show_all_seasons
      ;;
    season)
      shift
      show_season_progress "${1:-1}"
      ;;
    start)
      shift
      if [[ $# -lt 2 ]]; then
        echo -e "${YELLOW}⚠ Использование: progress.sh start <season> <episode>${NC}"
        exit 1
      fi
      mark_started "$1" "$2"
      ;;
    complete)
      shift
      if [[ $# -lt 2 ]]; then
        echo -e "${YELLOW}⚠ Использование: progress.sh complete <season> <episode>${NC}"
        exit 1
      fi
      mark_completed "$1" "$2"
      ;;
    reset)
      reset_progress
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      echo -e "${YELLOW}⚠ Неизвестная команда: $command${NC}"
      echo ""
      show_help
      exit 1
      ;;
  esac
}

# Запуск
main "$@"

