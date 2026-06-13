#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# zapret-desacratio — Service Management
# ═══════════════════════════════════════════════════════════════

get_service_status() {
    case "$INIT_SYSTEM" in
        systemd)
            if systemctl is-active --quiet "$ZAPRET_SERVICE" 2>/dev/null; then
                echo "running"
            elif systemctl is-enabled --quiet "$ZAPRET_SERVICE" 2>/dev/null; then
                echo "enabled"
            else
                echo "stopped"
            fi
            ;;
        openrc)
            if rc-service "$ZAPRET_SERVICE" status 2>/dev/null | grep -q "started"; then
                echo "running"
            else
                echo "stopped"
            fi
            ;;
        runit)
            if sv status "$ZAPRET_SERVICE" 2>/dev/null | grep -q "run"; then
                echo "running"
            else
                echo "stopped"
            fi
            ;;
        *)
            if pgrep -f "nfqws|tpws" &>/dev/null; then
                echo "running"
            else
                echo "stopped"
            fi
            ;;
    esac
}

service_start() {
    print_info "Запуск zapret..."
    case "$INIT_SYSTEM" in
        systemd)
            systemctl start "$ZAPRET_SERVICE"
            ;;
        openrc)
            rc-service "$ZAPRET_SERVICE" start
            ;;
        runit)
            sv start "$ZAPRET_SERVICE"
            ;;
        *)
            /opt/zapret/init.d/sysv/zapret start
            ;;
    esac
    
    local status=$(get_service_status)
    if [[ "$status" == "running" ]]; then
        print_success "zapret запущен"
    else
        print_error "Не удалось запустить zapret"
    fi
}

service_stop() {
    print_info "Остановка zapret..."
    case "$INIT_SYSTEM" in
        systemd)
            systemctl stop "$ZAPRET_SERVICE"
            ;;
        openrc)
            rc-service "$ZAPRET_SERVICE" stop
            ;;
        runit)
            sv stop "$ZAPRET_SERVICE"
            ;;
        *)
            /opt/zapret/init.d/sysv/zapret stop
            ;;
    esac
    
    local status=$(get_service_status)
    if [[ "$status" == "stopped" ]]; then
        print_success "zapret остановлен"
    else
        print_error "Не удалось остановить zapret"
    fi
}

service_restart() {
    print_info "Перезапуск zapret..."
    case "$INIT_SYSTEM" in
        systemd)
            systemctl restart "$ZAPRET_SERVICE"
            ;;
        openrc)
            rc-service "$ZAPRET_SERVICE" restart
            ;;
        runit)
            sv restart "$ZAPRET_SERVICE"
            ;;
        *)
            /opt/zapret/init.d/sysv/zapret restart
            ;;
    esac
    
    local status=$(get_service_status)
    if [[ "$status" == "running" ]]; then
        print_success "zapret перезапущен"
    else
        print_error "Не удалось перезапустить zapret"
    fi
}

service_enable() {
    print_info "Включение автозапуска zapret..."
    case "$INIT_SYSTEM" in
        systemd)
            systemctl enable "$ZAPRET_SERVICE"
            ;;
        openrc)
            rc-update add "$ZAPRET_SERVICE" default
            ;;
        runit)
            ln -sf /etc/sv/"$ZAPRET_SERVICE" /var/service/
            ;;
        *)
            print_warn "Автозапуск не поддерживается для данной системы"
            return 1
            ;;
    esac
    print_success "Автозапуск включён"
}

service_disable() {
    print_info "Отключение автозапуска zapret..."
    case "$INIT_SYSTEM" in
        systemd)
            systemctl disable "$ZAPRET_SERVICE"
            ;;
        openrc)
            rc-update del "$ZAPRET_SERVICE" default
            ;;
        runit)
            rm -f /var/service/"$ZAPRET_SERVICE"
            ;;
        *)
            print_warn "Автозапуск не поддерживается для данной системы"
            return 1
            ;;
    esac
    print_success "Автозапуск отключён"
}

create_systemd_service() {
    cat > /etc/systemd/system/zapret.service << 'EOSERVICE'
[Unit]
Description=zapret-desacratio — DPI circumvention daemon
After=network.target

[Service]
Type=simple
ExecStart=/opt/zapret/bin/nfqws --daemon --qnum=200
ExecStop=/opt/zapret/init.d/sysv/zapret stop
Restart=on-failure
RestartSec=5
KillMode=process

[Install]
WantedBy=multi-user.target
EOSERVICE
    systemctl daemon-reload
}

create_openrc_service() {
    cat > /etc/init.d/zapret << 'EOOPENRC'
#!/sbin/openrc-run
description="zapret-desacratio — DPI circumvention daemon"

command="/opt/zapret/bin/nfqws"
command_args="--daemon --qnum=200"
pidfile="/run/${RC_SVCNAME}.pid"

depend() {
    need net
}

start_pre() {
    checkpath -d -m 0755 -o root:root /run
}
EOOPENRC
    chmod +x /etc/init.d/zapret
}

show_service_status() {
    local status=$(get_service_status)
    
    print_line
    print_title "СТАТУС ZAPRET"
    print_line
    
    case "$status" in
        running)
            print_status "Состояние:" "${SYM_RUNNING} Работает"
            ;;
        stopped)
            print_status "Состояние:" "${SYM_STOPPED} Остановлен"
            ;;
        enabled)
            print_status "Состояние:" "${SYM_WARN} Включён (не запущен)"
            ;;
    esac
    
    print_status "Система инициализации:" "$INIT_SYSTEM"
    print_status "Дистрибутив:" "$DISTRO ($DISTRO_FAMILY)"
    
    if [[ "$status" == "running" ]]; then
        # Show PIDs
        local pids
        pids=$(pgrep -f "nfqws|tpws" | tr '\n' ' ')
        print_status "PID:" "$pids"
        
        # Show uptime if systemd
        if [[ "$INIT_SYSTEM" == "systemd" ]]; then
            local uptime
            uptime=$(systemctl show "$ZAPRET_SERVICE" -p ActiveEnterTimestamp --value 2>/dev/null || echo "N/A")
            print_status "Запущен с:" "$uptime"
        fi
        
        # Check memory
        local mem
        mem=$(ps -o rss= -p $pids 2>/dev/null | awk '{sum+=$1} END {printf "%.1f MB", sum/1024}')
        print_status "Память:" "$mem"
    fi
    
    if [[ -f "$ZAPRET_LOG" ]]; then
        local log_size
        log_size=$(du -h "$ZAPRET_LOG" 2>/dev/null | cut -f1)
        print_status "Лог:" "$log_size"
    fi
    
    print_footer
}
