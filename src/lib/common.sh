#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# zapret-desacratio — Common Functions & Theme
# ═══════════════════════════════════════════════════════════════

# ─── Nord Theme Colors (256-bit ANSI) ──────────────────────────
NORD_POLAR_NIGHT_0=0x2e3440
NORD_POLAR_NIGHT_1=0x3b4252
NORD_POLAR_NIGHT_2=0x434c5e
NORD_POLAR_NIGHT_3=0x4c566a
NORD_SNOW_STORM_0=0xd8dee9
NORD_SNOW_STORM_1=0xe5e9f0
NORD_SNOW_STORM_2=0xeceff4
NORD_FROST_0=0x8fbcbb
NORD_FROST_1=0x88c0d0
NORD_FROST_2=0x81a1c1
NORD_FROST_3=0x5e81ac
NORD_AURORA_RED=0xbf616a
NORD_AURORA_ORANGE=0xd08770
NORD_AURORA_YELLOW=0xebcb8b
NORD_AURORA_GREEN=0xa3be8c
NORD_AURORA_PURPLE=0xb48ead

# ─── ANSI Escape Codes ─────────────────────────────────────────
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_ITALIC="\033[3m"
C_UNDERLINE="\033[4m"
C_BLINK="\033[5m"
C_REVERSE="\033[7m"

# Foreground (256-color)
F_NORD0="\033[38;5;237m"    # 2e3440
F_NORD1="\033[38;5;239m"    # 3b4252
F_NORD2="\033[38;5;240m"    # 434c5e
F_NORD3="\033[38;5;241m"    # 4c566a
F_NORD4="\033[38;5;253m"    # d8dee9
F_NORD5="\033[38;5;254m"    # e5e9f0
F_NORD6="\033[38;5;255m"    # eceff4
F_FROST0="\033[38;5;109m"   # 8fbcbb
F_FROST1="\033[38;5;116m"   # 88c0d0
F_FROST2="\033[38;5;110m"   # 81a1c1
F_FROST3="\033[38;5;67m"    # 5e81ac
F_RED="\033[38;5;131m"      # bf616a
F_ORANGE="\033[38;5;173m"   # d08770
F_YELLOW="\033[38;5;187m"   # ebcb8b
F_GREEN="\033[38;5;151m"    # a3be8c
F_PURPLE="\033[38;5;139m"   # b48ead

# Background (256-color)
B_NORD0="\033[48;5;237m"
B_FROST2="\033[48;5;110m"
B_GREEN="\033[48;5;151m"
B_RED="\033[48;5;131m"

# ─── Box-Drawing Characters ────────────────────────────────────
# Using Unicode box drawing for beautiful borders
H_LINE="─"
V_LINE="│"
TL_CORNER="┌"
TR_CORNER="┐"
BL_CORNER="└"
BR_CORNER="┘"
TEE_DOWN="┬"
TEE_UP="┴"
TEE_RIGHT="├"
TEE_LEFT="┤"
CROSS="┼"

# ─── Symbols ───────────────────────────────────────────────────
SYM_CHECK="✓"
SYM_CROSS="✗"
SYM_ARROW="→"
SYM_BULLET="●"
SYM_STAR="★"
SYM_BLOCK="█"
SYM_DOT="·"
SYM_RUNNING="${F_GREEN}●${C_RESET}"
SYM_STOPPED="${F_RED}●${C_RESET}"
SYM_WARN="${F_YELLOW}▲${C_RESET}"

# ─── Paths ─────────────────────────────────────────────────────
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

# ─── Terminal Detection ────────────────────────────────────────
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
HAS_TRUECOLOR=false
if [[ "$COLORTERM" == "truecolor" || "$COLORTERM" == "24bit" ]]; then
    HAS_TRUECOLOR=true
fi

# ─── Helper Functions ──────────────────────────────────────────

# Print a centered text in a given width
center_text() {
    local text="$1"
    local width="${2:-$TERM_WIDTH}"
    local pad=$(( (width - ${#text}) / 2 ))
    printf "%${pad}s%s" "" "$text"
}

# Print a horizontal line with box-drawing character
print_line() {
    printf "${F_FROST2}%s${C_RESET}\n" "$(printf '%*s' "$TERM_WIDTH" '' | tr ' ' "$H_LINE")"
}

# Print a bordered box title
print_title() {
    local title="$1"
    local color="${2:-$F_FROST1}"
    local len=${#title}
    local total=$TERM_WIDTH
    local content=" ${title} "
    local left=$(( (total - len - 2) / 2 ))
    
    printf "${F_FROST2}${TL_CORNER}"
    printf "${H_LINE}%.0s" $(seq 1 $((left - 1)))
    printf "${C_RESET}${color}${C_BOLD}%s${C_RESET}${F_FROST2}" " ${title} "
    printf "${H_LINE}%.0s" $(seq 1 $((total - left - len - 3)))
    printf "${TR_CORNER}${C_RESET}\n"
}

# Print a footer line
print_footer() {
    printf "${F_FROST2}${BL_CORNER}"
    printf "${H_LINE}%.0s" $(seq 1 $((TERM_WIDTH - 2)))
    printf "${BR_CORNER}${C_RESET}\n"
}

# Print a menu item
print_menu_item() {
    local num="$1"
    local text="$2"
    local desc="$3"
    local selected="${4:-false}"
    
    if [[ "$selected" == "true" ]]; then
        printf "${B_FROST2}${F_NORD0}${C_BOLD}  %s) %s${C_RESET}\n" "$num" "$text"
        if [[ -n "$desc" ]]; then
            printf "${B_FROST2}${F_NORD0}${C_DIM}     %s${C_RESET}\n" "$desc"
        fi
    else
        printf "  ${F_FROST2}${C_BOLD}%s${C_RESET}) ${F_NORD6}%s${C_RESET}\n" "$num" "$text"
        if [[ -n "$desc" ]]; then
            printf "     ${F_NORD3}%s${C_RESET}\n" "$desc"
        fi
    fi
}

# Print a status line
print_status() {
    local label="$1"
    local value="$2"
    local value_color="${3:-$F_NORD6}"
    
    printf "  ${F_FROST2}${C_BOLD}%-20s${C_RESET} ${value_color}%s${C_RESET}\n" "$label" "$value"
}

# Print an info line
print_info() {
    printf "  ${F_NORD3}%s${C_RESET}\n" "$1"
}

# Print success message
print_success() {
    printf "  ${F_GREEN}${SYM_CHECK}${C_RESET} ${F_NORD6}%s${C_RESET}\n" "$1"
}

# Print error message
print_error() {
    printf "  ${F_RED}${SYM_CROSS}${C_RESET} ${F_NORD6}%s${C_RESET}\n" "$1" >&2
}

# Print warning message
print_warn() {
    printf "  ${F_YELLOW}${SYM_WARN}${C_RESET} ${F_NORD6}%s${C_RESET}\n" "$1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Этот скрипт требует прав root. Запусти с sudo."
        exit 1
    fi
}

# Check command exists
cmd_exists() {
    command -v "$1" &>/dev/null
}

# Run with progress indicator
run_with_spinner() {
    local msg="$1"
    shift
    local cmd=("$@")
    
    printf "  ${F_NORD3}${msg}...${C_RESET} "
    
    if "${cmd[@]}" &>/tmp/zapret-install.log; then
        printf "${F_GREEN}${SYM_CHECK}${C_RESET}\n"
        return 0
    else
        printf "${F_RED}${SYM_CROSS}${C_RESET}\n"
        return 1
    fi
}

# Confirm action
confirm_action() {
    local msg="$1"
    printf "\n  ${F_YELLOW}${SYM_WARN}${C_RESET} ${F_NORD6}%s${C_RESET} " "$msg"
    printf "[${F_GREEN}y${C_RESET}/${F_RED}N${C_RESET}]: "
    read -r resp
    [[ "$resp" == "y" || "$resp" == "Y" || "$resp" == "yes" ]]
}

# Clear screen and reset cursor
clear_screen() {
    printf "\033[2J\033[H"
}

# Pause and wait for keypress
pause() {
    printf "\n  ${F_NORD3}Нажми любую клавишу чтобы продолжить...${C_RESET}"
    read -rsn1
}
