#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# zapret-desacratio — Strategy Management
# ═══════════════════════════════════════════════════════════════

apply_strategy() {
    local strategy="${1:-$ZAPRET_STRATEGY}"
    local strategy_file="$ZAPRET_STRATEGIES/${strategy}.conf"
    
    if [[ ! -f "$strategy_file" ]]; then
        print_error "Стратегия '$strategy' не найдена"
        return 1
    fi
    
    source "$strategy_file"
    
    # Save current strategy to config
    ZAPRET_STRATEGY="$strategy"
    save_config
    
    # Apply iptables rules and restart service
    print_info "Применение стратегии: ${C_BOLD}${strategy}${C_RESET}"
    
    # Stop current service
    service_stop
    
    # Flush old rules
    iptables -F ZAPRET 2>/dev/null
    iptables -X ZAPRET 2>/dev/null
    ip6tables -F ZAPRET 2>/dev/null
    ip6tables -X ZAPRET 2>/dev/null
    
    # Create new chain
    iptables -N ZAPRET 2>/dev/null
    ip6tables -N ZAPRET 2>/dev/null
    
    # Apply rules based on strategy config
    local mode="${NFQWS_MODE:-nfqws}"
    local qnum="${NFQWS_QNUM:-200}"
    local desync="${NFQWS_DESYNC:---dpi-desync=fake}"
    local wssize="${NFQWS_WSSIZE:---wssize=1:6}"
    
    # Build nfqws command
    NFQWS_CMD="/opt/zapret/bin/nfqws --qnum=$qnum $desync $wssize"
    [[ -n "$NFQWS_EXTRA" ]] && NFQWS_CMD="$NFQWS_CMD $NFQWS_EXTRA"
    [[ "$ZAPRET_DEBUG" == "true" ]] && NFQWS_CMD="$NFQWS_CMD --debug=1"
    
    # Apply iptables rules
    local ports="${ZAPRET_PORT_RANGE:-80,443}"
    
    iptables -I OUTPUT -p tcp -m multiport --dports "$ports" -j ZAPRET
    iptables -A ZAPRET -j NFQUEUE --queue-num "$qnum"
    
    ip6tables -I OUTPUT -p tcp -m multiport --dports "$ports" -j ZAPRET
    ip6tables -A ZAPRET -j NFQUEUE --queue-num "$qnum"
    
    # Write nfqws params
    echo "$NFQWS_CMD" > "$ZAPRET_CONFIG/current_params"
    
    # Start service
    service_start
    
    print_success "Стратегия '$strategy' применена"
}

list_strategies() {
    local current="$ZAPRET_STRATEGY"
    print_line
    print_title "ДОСТУПНЫЕ СТРАТЕГИИ"
    print_line
    
    local i=1
    local items=()
    
    for f in "$ZAPRET_STRATEGIES"/*.conf; do
        local name
        name=$(basename "$f" .conf)
        local desc=""
        
        # Extract description from the strategy file
        desc=$(grep "^# DESC:" "$f" 2>/dev/null | head -1 | sed 's/^# DESC://')
        [[ -z "$desc" ]] && desc="Без описания"
        
        items+=("$name")
        
        if [[ "$name" == "$current" ]]; then
            printf "  ${F_FROST2}${C_BOLD}%s)${C_RESET} ${F_GREEN}${C_BOLD}%s${C_RESET} ${F_FROST2}[АКТИВНА]${C_RESET} ${F_NORD3}— %s${C_RESET}\n" "$i" "$name" "$desc"
        else
            printf "  ${F_FROST2}${C_BOLD}%s)${C_RESET} ${F_NORD6}%s${C_RESET} ${F_NORD3}— %s${C_RESET}\n" "$i" "$name" "$desc"
        fi
        ((i++))
    done
    
    print_footer
    
    printf "\n  ${F_NORD3}Выбери стратегию (0 — отмена):${C_RESET} "
    read -r choice
    
    if [[ "$choice" == "0" || -z "$choice" ]]; then
        return
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#items[@]} )); then
        apply_strategy "${items[$((choice-1))]}"
    fi
}

create_custom_strategy() {
    printf "\n"
    print_line
    print_title "СОЗДАНИЕ КАСТОМНОЙ СТРАТЕГИИ"
    print_line
    
    printf "  ${F_NORD3}Название стратегии:${C_RESET} "
    read -r name
    
    [[ -z "$name" ]] && { print_error "Название не может быть пустым"; return; }
    
    name="${name,,}"
    name="${name// /-}"
    
    local file="$ZAPRET_STRATEGIES/${name}.conf"
    if [[ -f "$file" ]]; then
        print_error "Стратегия '$name' уже существует"
        return
    fi
    
    printf "  ${F_NORD3}Описание:${C_RESET} "
    read -r desc
    
    printf "  ${F_NORD3}Режим (nfqws/tpws) [nfqws]:${C_RESET} "
    read -r mode
    [[ -z "$mode" ]] && mode="nfqws"
    
    printf "  ${F_NORD3}Метод обхода (fake/fakeknown/hostcase/hostnospace/methodeol/multisplit) [fake]:${C_RESET} "
    read -r desync
    [[ -z "$desync" ]] && desync="fake"
    
    printf "  ${F_NORD3}Размер окна (wssize) [1:6]:${C_RESET} "
    read -r wssize
    [[ -z "$wssize" ]] && wssize="1:6"
    
    printf "  ${F_NORD3}Дополнительные параметры:${C_RESET} "
    read -r extra
    
    cat > "$file" << EOF
# ═══════════════════════════════════════════════════════════════
# Стратегия: $name
# DESC: $desc
# ═══════════════════════════════════════════════════════════════

# Режим работы: nfqws или tpws
NFQWS_MODE="$mode"

# Номер очереди NFQUEUE
NFQWS_QNUM="200"

# Размер окна (TCP window size)
NFQWS_WSSIZE="--wssize=$wssize"

# Метод десинхронизации DPI
NFQWS_DESYNC="--dpi-desync=$desync"

# Дополнительные параметры
NFQWS_EXTRA="$extra"

# Список доменов (если используется hostlist)
# NFQWS_HOSTLIST="$ZAPRET_LISTS/${name}.txt"
EOF
    
    print_success "Стратегия '$name' создана"
    
    if confirm_action "Применить новую стратегию сейчас?"; then
        apply_strategy "$name"
    fi
}

edit_current_strategy() {
    local file="$ZAPRET_STRATEGIES/${ZAPRET_STRATEGY}.conf"
    
    if [[ ! -f "$file" ]]; then
        print_error "Файл стратегии не найден: $file"
        return
    fi
    
    if cmd_exists nano; then
        nano "$file"
    elif cmd_exists vim; then
        vim "$file"
    elif cmd_exists vi; then
        vi "$file"
    else
        print_error "Не найден текстовый редактор"
        return
    fi
    
    if confirm_action "Перезагрузить стратегию?"; then
        apply_strategy "$ZAPRET_STRATEGY"
    fi
}
