#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# zapret-desacratio — Theme Management
# ═══════════════════════════════════════════════════════════════

switch_theme() {
  clear_screen
  header "Темы"

  local themes=() i=1
  for f in "$ZAPRET_THEME_DIR"/*.sh; do
    local name; name=$(basename "$f" .sh)
    themes+=("$name")
    local mark=""
    [[ "$name" == "$ZAPRET_THEME" ]] && mark=" ${F_FROST2}[✓]${C_RESET}"
    local desc; desc=$(grep "^# DESC:" "$f" 2>/dev/null | head -1 | sed 's/^# DESC://')
    [[ -z "$desc" ]] && desc="—"
    printf "  ${F_FROST2}${C_BOLD}%2s${C_RESET}  ${F_NORD6}%s${C_RESET}%s  ${F_NORD3}%s${C_RESET}\n" "$i" "$name" "$mark" "$desc"
    ((i++))
  done

  printf "  ${F_FROST2} 0${C_RESET}  ${F_NORD3}← назад${C_RESET}\n"
  footer

  printf "  ${F_NORD3}номер темы:${C_RESET} "
  read -r c
  if [[ "$c" =~ ^[0-9]+$ ]] && (( c >= 1 && c <= ${#themes[@]} )); then
    local s="${themes[$((c-1))]}"
    ZAPRET_THEME="$s"
    save_config
    ok "тема '$s'"
    pause
  fi
}
