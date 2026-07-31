#!/usr/bin/env bash

# KERNEL SHADOWS - Progress Tracker
# Отслеживание прогресса студента по сериям курса.
#
# v2.0: курс мигрирует с монолитных эпизодов (episode-NN) на атомарные серии
# (sNNeNN). Трекер работает с ОБЕИМИ схемами одновременно и обнаруживает
# единицы прохождения на диске, а не по хардкоду. Каталоги сезонов: season-NN-*.

set -euo pipefail

# Цвета
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROGRESS_FILE="$PROJECT_ROOT/.progress"

# ============================================================================
# Обнаружение единиц прохождения
# ============================================================================

# Каталог сезона по номеру (1 или 01 -> season-01-*)
season_dir() {
  local n; n=$(printf '%02d' "$((10#${1#0}))" 2>/dev/null || echo "$1")
  compgen -G "$PROJECT_ROOT/season-${n}-*" 2>/dev/null | head -1
}

# Список единиц сезона: сначала серии sNNeNN, иначе старые episode-NN
season_units() {
  local dir; dir="$(season_dir "$1")"
  [[ -z "$dir" || ! -d "$dir" ]] && return 0
  local units=()
  mapfile -t units < <(find "$dir" -maxdepth 1 -type d -name 's[0-9][0-9]e[0-9][0-9]-*' 2>/dev/null | sort)
  if [[ ${#units[@]} -eq 0 ]]; then
    mapfile -t units < <(find "$dir" -maxdepth 1 -type d -name 'episode-[0-9][0-9]-*' 2>/dev/null | sort)
  fi
  [[ ${#units[@]} -gt 0 ]] && printf '%s\n' "${units[@]}"
}

# Ключ прогресса из пути: s01e01-... -> s01e01; episode-09-... в сезоне 3 -> s03e09
unit_key() {
  local base season; base="$(basename "$1")"; season="$2"
  case "$base" in
    s[0-9][0-9]e[0-9][0-9]-*) echo "${base%%-*}" ;;
    episode-*) local ep="${base#episode-}"; ep="${ep%%-*}"; printf 's%02de%s\n' "$((10#${season#0}))" "$ep" ;;
    *) echo "$base" ;;
  esac
}

# Человекочитаемое название единицы
unit_title() {
  local base; base="$(basename "$1")"
  local name="${base#s[0-9][0-9]e[0-9][0-9]-}"; name="${name#episode-[0-9][0-9]-}"
  echo "$name" | tr '-' ' '
}

all_units_count() {
  local total=0 s
  for s in 1 2 3 4 5 6 7 8; do
    local n; n=$(season_units "$s" | wc -l | tr -d ' ')
    total=$((total + n))
  done
  echo "$total"
}

# ============================================================================
# Файл прогресса
# ============================================================================

init_progress_file() {
  if [[ ! -f "$PROGRESS_FILE" ]]; then
    cat > "$PROGRESS_FILE" << 'EOF'
# KERNEL SHADOWS Progress Tracker
# Создаётся автоматически tools/progress.sh
# Формат: sNNeNN:status:timestamp
# Статусы: not_started, in_progress, completed
EOF
  fi
}

get_status() {
  local key="$1"
  [[ -f "$PROGRESS_FILE" ]] || { echo "not_started"; return; }
  local line; line=$(grep "^${key}:" "$PROGRESS_FILE" 2>/dev/null || echo "")
  [[ -n "$line" ]] && echo "$line" | cut -d: -f2 || echo "not_started"
}

set_status() {
  local key="$1" status="$2"
  init_progress_file
  sed -i.bak "/^${key}:/d" "$PROGRESS_FILE" 2>/dev/null || sed -i "/^${key}:/d" "$PROGRESS_FILE" 2>/dev/null || true
  rm -f "${PROGRESS_FILE}.bak" 2>/dev/null || true
  echo "${key}:${status}:$(date +%Y-%m-%d)" >> "$PROGRESS_FILE"
}

# Проверка через тесты серии
check_completion() {
  local dir="$1"
  local test_script="$dir/tests/test.sh"
  [[ -f "$test_script" ]] || return 1
  ( cd "$dir" && bash "$test_script" &>/dev/null )
}

# Найти каталог единицы по ключу (s01e01) в любом сезоне
find_unit_by_key() {
  local want="$1" s dir
  for s in 1 2 3 4 5 6 7 8; do
    while IFS= read -r dir; do
      [[ -z "$dir" ]] && continue
      [[ "$(unit_key "$dir" "$s")" == "$want" ]] && { echo "$dir"; return 0; }
    done < <(season_units "$s")
  done
  return 1
}

# ============================================================================
# Вывод
# ============================================================================

print_progress_bar() {
  local completed="${1:-0}" total="${2:-1}" width=40
  [[ $total -eq 0 ]] && total=1
  local percent=$(( (completed * 100) / total ))
  local filled=$(( (completed * width) / total ))
  local empty=$(( width - filled )) i
  echo -ne "${BLUE}["
  for ((i=0; i<filled; i++)); do echo -ne "█"; done
  for ((i=0; i<empty; i++)); do echo -ne "░"; done
  echo -ne "]${NC} ${percent}%"
}

status_emoji() {
  case "$1" in
    completed)   echo -e "${GREEN}[x]${NC}" ;;
    in_progress) echo -e "${YELLOW}[~]${NC}" ;;
    *)           echo -e "${GRAY}[ ]${NC}" ;;
  esac
}

show_overall_progress() {
  echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${PURPLE}║  KERNEL SHADOWS - Progress Tracker                           ║${NC}"
  echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""

  local total completed=0 in_progress=0
  total="$(all_units_count)"
  # grep -c при нуле совпадений печатает 0 И возвращает код 1 — поэтому
  # без `|| true` сработал бы фолбэк и склеил бы "0" + "0" в "00".
  if [[ -f "$PROGRESS_FILE" ]]; then
    completed=$(grep -c ":completed:" "$PROGRESS_FILE" 2>/dev/null || true)
    in_progress=$(grep -c ":in_progress:" "$PROGRESS_FILE" 2>/dev/null || true)
  fi
  completed=$(printf '%s' "${completed:-0}" | head -1 | tr -cd '0-9'); : "${completed:=0}"
  in_progress=$(printf '%s' "${in_progress:-0}" | head -1 | tr -cd '0-9'); : "${in_progress:=0}"

  echo -e "${CYAN}Общий прогресс:${NC}"
  echo -ne "  "; print_progress_bar "$completed" "$total"
  echo " ($completed/$total единиц курса)"
  echo ""
  echo -e "${CYAN}Статистика:${NC}"
  echo -e "  ${GREEN}Завершено:${NC}  $completed"
  echo -e "  ${YELLOW}В процессе:${NC} $in_progress"
  echo -e "  ${GRAY}Не начато:${NC}  $((total - completed - in_progress))"
  echo ""
  echo -e "${GRAY}Курс мигрирует на атомарные серии (sNNeNN); сезоны без миграции${NC}"
  echo -e "${GRAY}считаются по монолитным эпизодам.${NC}"
  echo ""
}

show_season_progress() {
  local season="${1:-1}"
  local dir; dir="$(season_dir "$season")"

  echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
  printf "${PURPLE}║  Season %-53s║${NC}\n" "$season"
  echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""

  if [[ -z "$dir" ]]; then
    echo -e "  ${GRAY}Сезон не найден${NC}"; echo ""; return
  fi

  local units=() u key status total=0 done_n=0
  mapfile -t units < <(season_units "$season")
  total=${#units[@]}

  if [[ $total -eq 0 ]]; then
    echo -e "  ${GRAY}Единиц прохождения не найдено${NC}"; echo ""; return
  fi

  for u in "${units[@]}"; do
    key="$(unit_key "$u" "$season")"
    status="$(get_status "$key")"
    [[ "$status" == "completed" ]] && ((done_n++)) || true
    printf "  %b %-10s %s\n" "$(status_emoji "$status")" "$key" "$(unit_title "$u")"
  done

  echo ""
  echo -e "${CYAN}Прогресс сезона:${NC}"
  echo -ne "  "; print_progress_bar "$done_n" "$total"
  echo " ($done_n/$total)"
  echo ""
}

show_all_seasons() {
  show_overall_progress
  echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
  echo ""
  local s
  for s in 1 2 3 4 5 6 7 8; do
    [[ -n "$(season_dir "$s")" ]] && show_season_progress "$s"
  done
  echo -e "${PURPLE}> Продолжай работать. Каждая серия — шаг к мастерству.${NC}"
}

# ============================================================================
# Команды
# ============================================================================

resolve_key() {   # принимает "s01e01" ЛИБО "<season> <episode>"
  if [[ "${1:-}" =~ ^s[0-9]{2}e[0-9]{2}$ ]]; then echo "$1"; return 0; fi
  [[ $# -lt 2 ]] && return 1
  printf 's%02de%02d\n' "$((10#${1#0}))" "$((10#${2#0}))"
}

mark_started() {
  local key; key="$(resolve_key "$@")" || { echo -e "${YELLOW}Использование: progress.sh start s01e01${NC}"; exit 1; }
  set_status "$key" "in_progress"
  echo -e "${YELLOW}$key помечена как 'в процессе'${NC}"
}

mark_completed() {
  local key; key="$(resolve_key "$@")" || { echo -e "${YELLOW}Использование: progress.sh complete s01e01${NC}"; exit 1; }
  local dir; dir="$(find_unit_by_key "$key" || true)"
  if [[ -n "$dir" ]] && check_completion "$dir"; then
    set_status "$key" "completed"
    echo -e "${GREEN}$key завершена — тесты пройдены${NC}"
  else
    set_status "$key" "in_progress"
    if [[ -z "$dir" ]]; then
      echo -e "${YELLOW}$key: каталог не найден; отмечено как 'в процессе'${NC}"
    else
      echo -e "${YELLOW}$key: тесты не пройдены; отмечено как 'в процессе'${NC}"
    fi
  fi
}

reset_progress() {
  if [[ -f "$PROGRESS_FILE" ]]; then
    rm -f "$PROGRESS_FILE"; echo -e "${GREEN}Прогресс сброшен${NC}"
  else
    echo -e "${YELLOW}Файл прогресса не найден${NC}"
  fi
}

show_help() {
  echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${PURPLE}║  KERNEL SHADOWS - Progress Tracker                           ║${NC}"
  echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${CYAN}Использование:${NC}"
  echo "  progress.sh [команда] [аргументы]"
  echo ""
  echo -e "${CYAN}Команды:${NC}"
  echo "  (нет)                Общий прогресс"
  echo "  season <N>           Прогресс сезона N (1-8)"
  echo "  all                  Все сезоны"
  echo "  start <key>          Отметить начатой:    progress.sh start s01e01"
  echo "  complete <key>       Отметить завершённой (запускает тесты серии)"
  echo "  reset                Сбросить прогресс"
  echo "  help                 Эта справка"
  echo ""
  echo -e "${CYAN}Ключи:${NC}"
  echo "  sNNeNN — серия v2.0 (s01e01). Для несмигрированных сезонов ключ"
  echo "  строится из номера эпизода: episode-09 в сезоне 3 -> s03e09."
  echo "  Допускается и старая форма: progress.sh start 1 01"
  echo ""
}

main() {
  init_progress_file
  local command="${1:-default}"
  case "$command" in
    default)  show_overall_progress ;;
    all)      show_all_seasons ;;
    season)   shift; show_season_progress "${1:-1}" ;;
    start)    shift; mark_started "$@" ;;
    complete) shift; mark_completed "$@" ;;
    reset)    reset_progress ;;
    help|--help|-h) show_help ;;
    *)
      echo -e "${YELLOW}Неизвестная команда: $command${NC}"; echo ""; show_help; exit 1 ;;
  esac
}

main "$@"
