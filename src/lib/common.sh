#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# zapret-desacratio — снежинка Fluffy стиль
# ═══════════════════════════════════════════════════════════════

# ─── ANSI через $'...' чтоб работало ─────────────────────────
C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_DIM=$'\033[2m'
C_ITALIC=$'\033[3m'
C_UNDERLINE=$'\033[4m'
C_BLINK=$'\033[5m'
C_REVERSE=$'\033[7m'

# ─── Nord palette ─────────────────────────────────────────────
F_NORD0=$'\033[38;5;237m'    # 2e3440
F_NORD1=$'\033[38;5;239m'    # 3b4252
F_NORD2=$'\033[38;5;240m'    # 434c5e
F_NORD3=$'\033[38;5;241m'    # 4c566a — серый, для подсказок
F_NORD4=$'\033[38;5;245m'    # подписи
F_NORD5=$'\033[38;5;251m'    # основной текст
F_NORD6=$'\033[38;5;255m'    # яркий белый
F_FROST0=$'\033[38;5;109m'   # 8fbcbb
F_FROST1=$'\033[38;5;116m'   # 88c0d0 — голубой
F_FROST2=$'\033[38;5;110m'   # 81a1c1 — синий
F_FROST3=$'\033[38;5;67m'    # 5e81ac
F_RED=$'\033[38;5;131m'      # bf616a
F_ORANGE=$'\033[38;5;173m'   # d08770
F_YELLOW=$'\033[38;5;187m'   # ebcb8b
F_GREEN=$'\033[38;5;151m'    # a3be8c
F_PURPLE=$'\033[38;5;139m'   # b48ead

B_NORD0=$'\033[48;5;237m'
B_FROST2=$'\033[48;5;110m'
B_GREEN=$'\033[48;5;151m'
B_RED=$'\033[48;5;131m'

# ─── Иконки ───────────────────────────────────────────────────
SYM_OK="${F_GREEN}✓${C_RESET}"
SYM_NO="${F_RED}✗${C_RESET}"
SYM_ARROW="${F_FROST2}→${C_RESET}"
SYM_DOT="${F_NORD3}·${C_RESET}"
SYM_BULLET="${F_FROST2}●${C_RESET}"
SYM_RUNNING="${F_GREEN}●${C_RESET}"
SYM_STOPPED="${F_RED}●${C_RESET}"
SYM_WARN="${F_YELLOW}▲${C_RESET}"

# ─── Пути ─────────────────────────────────────────────────────
ZAPRET_BASE="/opt/zapret"
ZAPRET_BIN="$ZAPRET_BASE/bin"
ZAPRET_CONFIG="/etc/zapret"
ZAPRET_CONFIG_FILE="$ZAPRET_CONFIG/config.sh"
ZAPRET_STRATEGIES="$ZAPRET_CONFIG/strategies"
ZAPRET_LISTS="$ZAPRET_CONFIG/lists"
ZAPRET_LOG="/var/log/zapret.log"
ZAPRET_SERVICE="zapret"
ZAPRET_THEME_DIR="$ZAPRET_CONFIG/themes"
ZAPRET_CURRENT_THEME="$ZAPRET_CONFIG/current_theme"

# ─── Размер терминала ─────────────────────────────────────────
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)

# ─── Простая рамка ────────────────────────────────────────────
header() {
  local txt="$1"
  local color="${2:-$F_FROST2}"
  local w=$(( TERM_WIDTH - 4 ))
  printf "\n  ${color}┌─ ${C_BOLD}%s${C_RESET} ${color}%s${C_RESET}\n" "$txt" "$(printf '─%.0s' $(seq 1 $(( w - ${#txt} - 2 ))))"
}

header_smol() {
  local txt="$1"
  local color="${2:-$F_NORD3}"
  printf "  ${color}%s${C_RESET}\n" "$txt"
}

footer() {
  local color="${1:-$F_FROST2}"
  local w=$(( TERM_WIDTH - 4 ))
  printf "  ${color}%s${C_RESET}\n\n" "$(printf '─%.0s' $(seq 1 $(( w + 2 ))))"
}

sep() {
  printf "  ${F_NORD3}%s${C_RESET}\n" "$(printf '· %.0s' $(seq 1 $(( (TERM_WIDTH - 6) / 2 ))))"
}

# ─── Принтеры ─────────────────────────────────────────────────
item() {
  local num="$1"
  local text="$2"
  local desc="$3"
  printf "  ${F_FROST2}${C_BOLD}%2s${C_RESET}  ${F_NORD6}%s${C_RESET}\n" "$num" "$text"
  if [[ -n "$desc" ]]; then
    printf "      ${F_NORD3}%s${C_RESET}\n" "$desc"
  fi
}

info()  { printf "  ${F_NORD4}%s${C_RESET}\n" "$*"; }
dim()   { printf "  ${F_NORD3}%s${C_RESET}\n" "$*"; }
ok()    { printf "  ${SYM_OK}  ${F_NORD6}%s${C_RESET}\n" "$*"; }
fail()  { printf "  ${SYM_NO}  ${F_NORD6}%s${C_RESET}\n" "$*" >&2; }
warn()  { printf "  ${SYM_WARN}  ${F_NORD6}%s${C_RESET}\n" "$*"; }

# ─── Подтверждение ────────────────────────────────────────────
confirm() {
  printf "\n  ${F_YELLOW}▲${C_RESET} ${F_NORD6}%s${C_RESET} " "$*"
  printf "[${F_GREEN}y${C_RESET}/${F_RED}N${C_RESET}]: "
  read -r resp
  [[ "$resp" == "y" || "$resp" == "Y" || "$resp" == "yes" ]]
}

# ─── Спиннер для установки ────────────────────────────────────
run_with_spinner() {
  local msg="$1"; shift
  printf "  ${F_NORD4}${msg}...${C_RESET} "
  if "$@" &>/tmp/zapret-install.log; then
    printf "${SYM_OK}\n"
    return 0
  else
    printf "${SYM_NO}\n"
    tail -5 /tmp/zapret-install.log 2>/dev/null | sed 's/^/    /'
    return 1
  fi
}

# ─── Утилиты ──────────────────────────────────────────────────
check_root() {
  if [[ $EUID -ne 0 ]]; then
    fail "Требуются права root. Запусти с sudo."
    exit 1
  fi
}

cmd_exists() { command -v "$1" &>/dev/null; }

clear_screen() { printf "\033[2J\033[H"; }

pause() {
  printf "\n  ${F_NORD3}жми enter →${C_RESET} "
  read -rsn1
}
