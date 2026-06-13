#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# zapret-desacratio — Domain List Management
# ═══════════════════════════════════════════════════════════════

show_lists_menu() {
    while true; do
        clear_screen
        print_line
        print_title "УПРАВЛЕНИЕ СПИСКАМИ ДОМЕНОВ"
        print_line
        
        local i=1
        local items=()
        
        for f in "$ZAPRET_LISTS"/*.txt; do
            local name
            name=$(basename "$f" .txt)
            local count
            count=$(wc -l < "$f" 2>/dev/null || echo 0)
            items+=("$name")
            
            if [[ "$name" == "custom" ]]; then
                printf "  ${F_FROST2}${C_BOLD}%s)${C_RESET} ${F_PURPLE}${C_BOLD}%s${C_RESET} ${F_NORD3}(%s доменов)${C_RESET}\n" "$i" "$name" "$count"
            else
                printf "  ${F_FROST2}${C_BOLD}%s)${C_RESET} ${F_NORD6}%s${C_RESET} ${F_NORD3}(%s доменов)${C_RESET}\n" "$i" "$name" "$count"
            fi
            ((i++))
        done
        
        printf "\n  ${F_FROST2}${C_BOLD}a)${C_RESET} ${F_NORD6}Добавить домен${C_RESET}\n"
        printf "  ${F_FROST2}${C_BOLD}r)${C_RESET} ${F_NORD6}Удалить домен${C_RESET}\n"
        printf "  ${F_FROST2}${C_BOLD}s)${C_RESET} ${F_NORD6}Проверить статус домена${C_RESET}\n"
        printf "  ${F_FROST2}${C_BOLD}0)${C_RESET} ${F_NORD3}Назад${C_RESET}\n"
        
        print_footer
        
        printf "\n  ${F_NORD3}Выбери действие:${C_RESET} "
        read -r choice
        
        case "$choice" in
            0) return ;;
            a) add_domain ;;
            r) remove_domain ;;
            s) check_domain ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#items[@]} )); then
                    view_list "${items[$((choice-1))]}"
                fi
                ;;
        esac
    done
}

view_list() {
    local list_name="$1"
    local file="$ZAPRET_LISTS/${list_name}.txt"
    
    if [[ ! -f "$file" ]]; then
        print_error "Список '$list_name' не найден"
        pause
        return
    fi
    
    clear_screen
    print_line
    print_title "СПИСОК: ${list_name}"
    print_line
    
    local count=0
    while IFS= read -r domain; do
        [[ -z "$domain" || "$domain" == \#* ]] && continue
        ((count++))
        printf "  ${F_FROST2}●${C_RESET} ${F_NORD6}%s${C_RESET}\n" "$domain"
    done < "$file"
    
    if [[ $count -eq 0 ]]; then
        printf "  ${F_NORD3}Список пуст${C_RESET}\n"
    fi
    
    printf "\n  ${F_NORD3}Всего доменов: ${C_BOLD}%s${C_RESET}\n" "$count"
    print_footer
    pause
}

add_domain() {
    printf "\n  ${F_NORD3}Введи домен (например, discord.com):${C_RESET} "
    read -r domain
    
    [[ -z "$domain" ]] && return
    
    # Check if already exists
    if grep -q "^${domain}$" "$ZAPRET_LISTS/custom.txt" 2>/dev/null; then
        print_warn "Домен '$domain' уже в списке"
        pause
        return
    fi
    
    echo "$domain" >> "$ZAPRET_LISTS/custom.txt"
    print_success "Домен '$domain' добавлен в custom.txt"
    
    if confirm_action "Применить изменения сейчас?"; then
        apply_strategy "$ZAPRET_STRATEGY"
    fi
}

remove_domain() {
    printf "\n  ${F_NORD3}Введи домен для удаления:${C_RESET} "
    read -r domain
    
    [[ -z "$domain" ]] && return
    
    if grep -q "^${domain}$" "$ZAPRET_LISTS/custom.txt" 2>/dev/null; then
        grep -v "^${domain}$" "$ZAPRET_LISTS/custom.txt" > "$ZAPRET_LISTS/custom.tmp"
        mv "$ZAPRET_LISTS/custom.tmp" "$ZAPRET_LISTS/custom.txt"
        print_success "Домен '$domain' удалён"
        
        if confirm_action "Применить изменения сейчас?"; then
            apply_strategy "$ZAPRET_STRATEGY"
        fi
    else
        print_error "Домен '$domain' не найден в custom.txt"
    fi
    pause
}

check_domain() {
    printf "\n  ${F_NORD3}Введи домен для проверки:${C_RESET} "
    read -r domain
    
    [[ -z "$domain" ]] && return
    
    printf "\n"
    print_info "Проверка доступа к $domain..."
    
    # Check DNS
    if cmd_exists dig; then
        local dns_result
        dns_result=$(dig +short "$domain" 2>/dev/null | head -1)
        if [[ -n "$dns_result" ]]; then
            print_status "DNS resolved:" "$dns_result" "$F_GREEN"
        else
            print_status "DNS:" "Не резолвится" "$F_RED"
        fi
    fi
    
    # Check HTTP access
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://$domain" 2>/dev/null || echo "timeout")
    
    if [[ "$http_code" == "200" || "$http_code" == "301" || "$http_code" == "302" ]]; then
        print_status "HTTP статус:" "$http_code (доступен)" "$F_GREEN"
    elif [[ "$http_code" == "timeout" ]]; then
        print_status "HTTP статус:" "Таймаут (возможно заблокирован)" "$F_RED"
    else
        print_status "HTTP статус:" "$http_code" "$F_YELLOW"
    fi
    
    # Check ping
    if ping -c 1 -W 3 "$domain" &>/dev/null; then
        print_status "Ping:" "Доступен" "$F_GREEN"
    else
        print_status "Ping:" "Недоступен" "$F_RED"
    fi
    
    # Check if domain is in our lists
    for f in "$ZAPRET_LISTS"/*.txt; do
        if grep -q "^${domain}$" "$f" 2>/dev/null; then
            print_status "В списке:" "$(basename "$f" .txt)" "$F_PURPLE"
        fi
    done
    
    pause
}
