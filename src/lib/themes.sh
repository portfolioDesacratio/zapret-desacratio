#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# zapret-desacratio — Theme Management
# ═══════════════════════════════════════════════════════════════

switch_theme() {
    clear_screen
    print_line
    print_title "ВЫБОР ТЕМЫ ОФОРМЛЕНИЯ"
    print_line
    
    local themes=()
    local i=1
    
    for f in "$ZAPRET_THEME_DIR"/*.sh; do
        local name
        name=$(basename "$f" .sh)
        themes+=("$name")
        
        local mark=""
        [[ "$name" == "$ZAPRET_THEME" ]] && mark=" ${F_FROST2}[АКТИВНА]${C_RESET}"
        
        # Get description
        local desc=""
        desc=$(grep "^# DESC:" "$f" 2>/dev/null | head -1 | sed 's/^# DESC://')
        [[ -z "$desc" ]] && desc="Без описания"
        
        printf "  ${F_FROST2}${C_BOLD}%s)${C_RESET} ${F_NORD6}%s${C_RESET}${mark} ${F_NORD3}— %s${C_RESET}\n" "$i" "$name" "$desc"
        ((i++))
    done
    
    printf "\n  ${F_FROST2}${C_BOLD}0)${C_RESET} ${F_NORD3}Назад${C_RESET}\n"
    print_footer
    
    printf "\n  ${F_NORD3}Выбери тему (0 — отмена):${C_RESET} "
    read -r choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#themes[@]} )); then
        local selected="${themes[$((choice-1))]}"
        ZAPRET_THEME="$selected"
        save_config
        print_success "Тема '$selected' активирована"
        pause
    fi
}
