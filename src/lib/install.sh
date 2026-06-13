#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# zapret-desacratio — Installation Logic (lib)
# ═══════════════════════════════════════════════════════════════

install_zapret_core() {
  header "Установка zapret"

  # ─── Step 1 ──────────────────────────────────────────────────
  info "1/5 · зависимости для сборки…"
  local deps; deps=$(get_build_deps)
  local cmd; cmd=$(get_install_cmd)
  if [[ "$cmd" == "unknown" ]]; then
    fail "неизвестный пакетный менеджер"
    info "установи вручную: $deps"
    return 1
  fi
  run_with_spinner "пакеты ($deps)" bash -c "$cmd $deps" || warn "продолжаем…"

  # ─── Step 2 ──────────────────────────────────────────────────
  info "2/5 · директории…"
  mkdir -p /opt/zapret/{bin,config,lists,strategies,themes,init.d}
  mkdir -p "$ZAPRET_CONFIG"
  ok "директории готовы"

  # ─── Step 3 ──────────────────────────────────────────────────
  info "3/5 · сборка bol-van/zapret…"
  rm -rf /tmp/zapret-build
  run_with_spinner "клонирование" git clone --depth=1 \
    https://github.com/bol-van/zapret.git /tmp/zapret-build || {
    fail "git clone не удался"
    return 1
  }
  cd /tmp/zapret-build
  run_with_spinner "компиляция" make -j$(nproc) || {
    fail "make не удалась"
    return 1
  }

  # ─── Step 4 ──────────────────────────────────────────────────
  info "4/5 · бинарники…"
  if [[ -d binaries/my ]]; then
    cp -f binaries/my/* /opt/zapret/bin/
  else
    cp -f nfq/nfqws /opt/zapret/bin/ 2>/dev/null
    cp -f tpws/tpws /opt/zapret/bin/ 2>/dev/null
    cp -f ip2net/ip2net /opt/zapret/bin/ 2>/dev/null
    cp -f mdig/mdig /opt/zapret/bin/ 2>/dev/null
  fi
  chmod +x /opt/zapret/bin/*
  ln -sf /opt/zapret/bin/nfqws /usr/local/bin/nfqws
  ln -sf /opt/zapret/bin/tpws /usr/local/bin/tpws
  ok "бинарники в /opt/zapret/bin"

  # ─── Step 5 ──────────────────────────────────────────────────
  info "5/5 · конфиги…"
  local src_dir; src_dir="$(dirname "$(dirname "$(dirname "$(realpath "$0")")")")"
  cp -r "$src_dir/strategies/"* "$ZAPRET_STRATEGIES/" 2>/dev/null || true
  cp -r "$src_dir/lists/"*      "$ZAPRET_LISTS/" 2>/dev/null || true
  cp -r "$src_dir/themes/"*     "$ZAPRET_THEME_DIR/" 2>/dev/null || true
  ok "конфиги скопированы"

  # ─── Service ─────────────────────────────────────────────────
  case "$INIT_SYSTEM" in
    systemd) create_systemd_service; ok "systemd сервис" ;;
    openrc)  create_openrc_service;  ok "openrc сервис" ;;
    *) warn "init $INIT_SYSTEM — настрой сервис вручную" ;;
  esac

  # ─── Cleanup ─────────────────────────────────────────────────
  rm -rf /tmp/zapret-build
  ZAPRET_AUTOSTART=true
  ZAPRET_STRATEGY="default"
  save_config

  echo ""
  ok "${C_BOLD}всё готово!${C_RESET}"
  info "команда: ${C_BOLD}zapret${C_RESET} · логи: $ZAPRET_LOG"
  footer
}

uninstall_zapret() {
  confirm "Точно удалить? Сервис остановится, файлы сотрутся." || return
  info "чистим…"

  # stop & disable
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

  rm -rf /opt/zapret
  rm -rf "$ZAPRET_CONFIG"
  rm -f /usr/local/bin/nfqws /usr/local/bin/tpws /usr/bin/zapret

  iptables -F ZAPRET 2>/dev/null;  iptables -X ZAPRET 2>/dev/null
  ip6tables -F ZAPRET 2>/dev/null; ip6tables -X ZAPRET 2>/dev/null

  ok "zapret удалён"
}

update_strategies() {
  info "обновление стратегий и списков…"
  local tmp="/tmp/zapret-update"
  rm -rf "$tmp"
  git clone --depth=1 https://github.com/portfolioDesacratio/zapret-desacratio.git "$tmp" 2>/dev/null || {
    fail "не удалось загрузить"
    return 1
  }
  cp "$ZAPRET_LISTS/custom.txt" /tmp/zapret-custom.txt 2>/dev/null || true
  cp -r "$tmp/strategies/"* "$ZAPRET_STRATEGIES/" 2>/dev/null
  cp -r "$tmp/lists/"*      "$ZAPRET_LISTS/" 2>/dev/null
  cp -r "$tmp/themes/"*     "$ZAPRET_THEME_DIR/" 2>/dev/null
  cp /tmp/zapret-custom.txt "$ZAPRET_LISTS/custom.txt" 2>/dev/null || true
  rm -rf "$tmp"
  ok "стратегии и списки обновлены"
}
