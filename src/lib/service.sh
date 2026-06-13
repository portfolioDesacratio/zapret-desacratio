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
  info "запуск zapret…"
  case "$INIT_SYSTEM" in
    systemd) systemctl start "$ZAPRET_SERVICE" ;;
    openrc)  rc-service "$ZAPRET_SERVICE" start ;;
    runit)   sv start "$ZAPRET_SERVICE" ;;
    *)       /opt/zapret/init.d/sysv/zapret start ;;
  esac
  if [[ "$(get_service_status)" == "running" ]]; then
    ok "zapret запущен"
  else
    fail "не удалось запустить zapret"
  fi
}

service_stop() {
  info "остановка zapret…"
  case "$INIT_SYSTEM" in
    systemd) systemctl stop "$ZAPRET_SERVICE" ;;
    openrc)  rc-service "$ZAPRET_SERVICE" stop ;;
    runit)   sv stop "$ZAPRET_SERVICE" ;;
    *)       /opt/zapret/init.d/sysv/zapret stop ;;
  esac
  if [[ "$(get_service_status)" == "stopped" ]]; then
    ok "zapret остановлен"
  else
    fail "не удалось остановить zapret"
  fi
}

service_restart() {
  info "перезапуск zapret…"
  case "$INIT_SYSTEM" in
    systemd) systemctl restart "$ZAPRET_SERVICE" ;;
    openrc)  rc-service "$ZAPRET_SERVICE" restart ;;
    runit)   sv restart "$ZAPRET_SERVICE" ;;
    *)       /opt/zapret/init.d/sysv/zapret restart ;;
  esac
  if [[ "$(get_service_status)" == "running" ]]; then
    ok "zapret перезапущен"
  else
    fail "не удалось перезапустить zapret"
  fi
}

service_enable() {
  info "автозапуск zapret…"
  case "$INIT_SYSTEM" in
    systemd) systemctl enable "$ZAPRET_SERVICE" ;;
    openrc)  rc-update add "$ZAPRET_SERVICE" default ;;
    runit)   ln -sf /etc/sv/"$ZAPRET_SERVICE" /var/service/ ;;
    *)       warn "автозапуск не поддерживается для $INIT_SYSTEM"; return 1 ;;
  esac
  ok "автозапуск включён"
}

service_disable() {
  info "отключение автозапуска…"
  case "$INIT_SYSTEM" in
    systemd) systemctl disable "$ZAPRET_SERVICE" ;;
    openrc)  rc-update del "$ZAPRET_SERVICE" default ;;
    runit)   rm -f /var/service/"$ZAPRET_SERVICE" ;;
    *)       warn "автозапуск не поддерживается для $INIT_SYSTEM"; return 1 ;;
  esac
  ok "автозапуск отключён"
}

create_systemd_service() {
  cat > /etc/systemd/system/zapret.service << 'EOSERVICE'
[Unit]
Description=zapret-desacratio — DPI circumvention daemon
After=network.target

[Service]
Type=simple
ExecStart=/opt/zapret/bin/nfqws --qnum=200 --dpi-desync=fake --wssize=1:6
ExecStop=/usr/bin/pkill -f nfqws
Restart=on-failure
RestartSec=10
KillMode=mixed
Nice=-10

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
command_args="--qnum=200 --dpi-desync=fake --wssize=1:6"
pidfile="/run/${RC_SVCNAME}.pid"
depend() { need net; }
start_pre() { checkpath -d -m 0755 -o root:root /run; }
EOOPENRC
  chmod +x /etc/init.d/zapret
}

show_service_status() {
  local s; s=$(get_service_status)
  header "Статус"

  case "$s" in
    running) info "состояние     ${SYM_RUNNING} работает" ;;
    stopped) info "состояние     ${SYM_STOPPED} остановлен" ;;
    enabled) info "состояние     ${SYM_WARN} включён (не запущен)" ;;
  esac

  info "init          $INIT_SYSTEM"
  info "дистрибутив   $DISTRO ($DISTRO_FAMILY)"

  if [[ "$s" == "running" ]]; then
    local pids; pids=$(pgrep -f "nfqws|tpws" | tr '\n' ' ')
    info "pid           $pids"
    if [[ "$INIT_SYSTEM" == "systemd" ]]; then
      local uptime
      uptime=$(systemctl show "$ZAPRET_SERVICE" -p ActiveEnterTimestamp --value 2>/dev/null || echo "N/A")
      info "запущен       $uptime"
    fi
    local mem
    mem=$(ps -o rss= -p $pids 2>/dev/null | awk '{sum+=$1} END {printf "%.1f MB", sum/1024}')
    info "память        $mem"
  fi

  if [[ -f "$ZAPRET_LOG" ]]; then
    local log_size; log_size=$(du -h "$ZAPRET_LOG" 2>/dev/null | cut -f1)
    info "лог           $log_size"
  fi

  footer
}
