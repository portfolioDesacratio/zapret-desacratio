#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# zapret-desacratio — Installation Logic (lib)
# ═══════════════════════════════════════════════════════════════

install_zapret_core() {
    print_line
    print_title "УСТАНОВКА ZAPRET"
    print_line
    
    # ─── Step 1: Install build dependencies ────────────────────
    print_info "Шаг 1/5: Установка зависимостей для сборки..."
    
    local deps
    deps=$(get_build_deps)
    local install_cmd
    install_cmd=$(get_install_cmd)
    
    if [[ "$install_cmd" == "unknown" ]]; then
        print_error "Не удалось определить пакетный менеджер."
        print_info "Установи зависимости вручную: $deps"
        return 1
    fi
    
    run_with_spinner "Установка пакетов ($deps)" bash -c "$install_cmd $deps" || {
        print_warn "Некоторые пакеты не установились. Продолжаем..."
    }
    
    # ─── Step 2: Create directories ───────────────────────────
    print_info "Шаг 2/5: Создание директорий..."
    mkdir -p /opt/zapret/{bin,config,lists,strategies,themes,init.d}
    mkdir -p "$ZAPRET_CONFIG"
    print_success "Директории созданы"
    
    # ─── Step 3: Clone and build zapret ────────────────────────
    print_info "Шаг 3/5: Сборка zapret из исходников..."
    
    if [[ -d /tmp/zapret-build ]]; then
        rm -rf /tmp/zapret-build
    fi
    
    run_with_spinner "Клонирование репозитория bol-van/zapret" \
        git clone --depth=1 https://github.com/bol-van/zapret.git /tmp/zapret-build || {
        print_error "Не удалось клонировать репозиторий"
        return 1
    }
    
    cd /tmp/zapret-build || return 1
    
    run_with_spinner "Компиляция" make -j$(nproc) || {
        print_error "Ошибка компиляции"
        return 1
    }
    
    # ─── Step 4: Install binaries ─────────────────────────────
    print_info "Шаг 4/5: Установка бинарных файлов..."
    
    cp -f /tmp/zapret-build/nfqws/nfqws /opt/zapret/bin/
    cp -f /tmp/zapret-build/tpws/tpws /opt/zapret/bin/
    cp -f /tmp/zapret-build/ip2net/ip2net /opt/zapret/bin/
    cp -f /tmp/zapret-build/mdig/mdig /opt/zapret/bin/
    
    chmod +x /opt/zapret/bin/*
    
    # Create symlinks
    ln -sf /opt/zapret/bin/nfqws /usr/local/bin/nfqws
    ln -sf /opt/zapret/bin/tpws /usr/local/bin/tpws
    
    print_success "Бинарные файлы установлены"
    
    # ─── Step 5: Install strategies, lists, configs ────────────
    print_info "Шаг 5/5: Установка конфигураций..."
    
    # Copy from our package
    local src_dir
    src_dir="$(dirname "$(dirname "$(dirname "$(realpath "$0")")")")"
    
    cp -r "$src_dir/strategies/"* "$ZAPRET_STRATEGIES/" 2>/dev/null || true
    cp -r "$src_dir/lists/"* "$ZAPRET_LISTS/" 2>/dev/null || true
    cp -r "$src_dir/themes/"* "$ZAPRET_THEME_DIR/" 2>/dev/null || true
    
    print_success "Конфигурации установлены"
    
    # ─── Create service ───────────────────────────────────────
    case "$INIT_SYSTEM" in
        systemd)
            create_systemd_service
            print_success "Systemd service создан"
            ;;
        openrc)
            create_openrc_service
            print_success "OpenRC service создан"
            ;;
        *)
            print_warn "Init system '$INIT_SYSTEM' не поддерживается автоматически"
            ;;
    esac
    
    # ─── Cleanup ──────────────────────────────────────────────
    rm -rf /tmp/zapret-build
    
    # ─── Save config ──────────────────────────────────────────
    ZAPRET_AUTOSTART=true
    ZAPRET_STRATEGY="default"
    save_config
    
    print_line
    print_success "${C_BOLD}Установка завершена!${C_RESET}"
    print_info "Используй команду ${C_BOLD}zapret${C_RESET} для управления"
    print_info "Логи: $ZAPRET_LOG"
    print_footer
}

uninstall_zapret() {
    if ! confirm_action "Точно удалить zapret? Это остановит сервис и удалит все файлы."; then
        return
    fi
    
    print_info "Удаление zapret..."
    
    # Stop service
    case "$INIT_SYSTEM" in
        systemd)
            systemctl stop zapret 2>/dev/null
            systemctl disable zapret 2>/dev/null
            rm -f /etc/systemd/system/zapret.service
            systemctl daemon-reload
            ;;
        openrc)
            rc-service zapret stop 2>/dev/null
            rc-update delete zapret 2>/dev/null
            rm -f /etc/init.d/zapret
            ;;
    esac
    
    # Remove files
    rm -rf /opt/zapret
    rm -rf "$ZAPRET_CONFIG"
    rm -f /usr/local/bin/nfqws
    rm -f /usr/local/bin/tpws
    rm -f /usr/bin/zapret
    
    # Flush iptables
    iptables -F ZAPRET 2>/dev/null
    iptables -X ZAPRET 2>/dev/null
    ip6tables -F ZAPRET 2>/dev/null
    ip6tables -X ZAPRET 2>/dev/null
    
    print_success "zapret полностью удалён"
}

update_strategies() {
    print_info "Обновление стратегий и списков..."
    
    local tmp_dir="/tmp/zapret-update"
    rm -rf "$tmp_dir"
    
    git clone --depth=1 https://github.com/portfolioDesacratio/zapret-desacratio.git "$tmp_dir" 2>/dev/null || {
        print_error "Не удалось загрузить обновления"
        return 1
    }
    
    # Backup current custom files
    cp "$ZAPRET_LISTS/custom.txt" /tmp/zapret-custom-backup.txt 2>/dev/null || true
    
    # Update
    cp -r "$tmp_dir/strategies/"* "$ZAPRET_STRATEGIES/" 2>/dev/null
    cp -r "$tmp_dir/lists/"* "$ZAPRET_LISTS/" 2>/dev/null
    cp -r "$tmp_dir/themes/"* "$ZAPRET_THEME_DIR/" 2>/dev/null
    
    # Restore custom
    cp /tmp/zapret-custom-backup.txt "$ZAPRET_LISTS/custom.txt" 2>/dev/null || true
    
    rm -rf "$tmp_dir"
    
    print_success "Стратегии и списки обновлены"
}
