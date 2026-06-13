#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# zapret-desacratio — Strategy Management
# ═══════════════════════════════════════════════════════════════

apply_strategy() {
  local strategy="${1:-$ZAPRET_STRATEGY}"
  local file="$ZAPRET_STRATEGIES/${strategy}.conf"
  if [[ ! -f "$file" ]]; then
    fail "стратегия '$strategy' не найдена"
    return 1
  fi

  source "$file"
  ZAPRET_STRATEGY="$strategy"
  save_config

  info "применяю ${C_BOLD}${strategy}${C_RESET}…"
  service_stop

  # clean old firewall rules
  /sbin/iptables -F ZAPRET 2>/dev/null; /sbin/iptables -X ZAPRET 2>/dev/null
  /sbin/ip6tables -F ZAPRET 2>/dev/null; /sbin/ip6tables -X ZAPRET 2>/dev/null

  local mode="${NFQWS_MODE:-nfqws}"
  local qnum="${NFQWS_QNUM:-200}"

  # build nfqws command
  if [[ -n "$NFQWS_ARGS" ]]; then
    NFQWS_CMD="/opt/zapret/bin/$mode --qnum=$qnum $NFQWS_ARGS"
  else
    local desync="${NFQWS_DESYNC:---dpi-desync=fake}"
    local wssize="${NFQWS_WSSIZE:---wssize=1:6}"
    NFQWS_CMD="/opt/zapret/bin/$mode --qnum=$qnum $desync $wssize"
    [[ -n "$NFQWS_EXTRA" ]] && NFQWS_CMD="$NFQWS_CMD $NFQWS_EXTRA"
  fi
  [[ "$ZAPRET_DEBUG" == "true" ]] && NFQWS_CMD="$NFQWS_CMD --debug=1"

  # ─── Firewall rules ──────────────────────────────────
  # chain
  /sbin/iptables -N ZAPRET 2>/dev/null
  /sbin/ip6tables -N ZAPRET 2>/dev/null

  # redirect TCP 80,443
  /sbin/iptables -I OUTPUT -p tcp -m multiport --dports 80,443 -j ZAPRET
  /sbin/iptables -A ZAPRET -j NFQUEUE --queue-num "$qnum" --queue-bypass
  /sbin/ip6tables -I OUTPUT -p tcp -m multiport --dports 80,443 -j ZAPRET
  /sbin/ip6tables -A ZAPRET -j NFQUEUE --queue-num "$qnum" --queue-bypass

  # DROP QUIC (UDP 443) — force TCP fallback
  /sbin/iptables -I OUTPUT -p udp --dport 443 -j DROP 2>/dev/null || true
  /sbin/ip6tables -I OUTPUT -p udp --dport 443 -j DROP 2>/dev/null || true

  echo "$NFQWS_CMD" > "$ZAPRET_CONFIG/current_params"
  service_start
  ok "стратегия '$strategy' — ${mode} работает"
}

list_strategies() {
  local current="$ZAPRET_STRATEGY"
  header "Стратегии"

  local i=1 items=()
  for f in "$ZAPRET_STRATEGIES"/*.conf; do
    local name; name=$(basename "$f" .conf)
    local desc; desc=$(grep "^# DESC:" "$f" 2>/dev/null | head -1 | sed 's/^# DESC://')
    [[ -z "$desc" ]] && desc="—"
    items+=("$name")

    if [[ "$name" == "$current" ]]; then
      printf "  ${F_FROST2}${C_BOLD}%2s${C_RESET}  ${F_GREEN}%s${C_RESET}  ${F_FROST2}[✓]${C_RESET}  ${F_NORD3}%s${C_RESET}
" "$i" "$name" "$desc"
    else
      printf "  ${F_FROST2}${C_BOLD}%2s${C_RESET}  ${F_NORD6}%s${C_RESET}            ${F_NORD3}%s${C_RESET}
" "$i" "$name" "$desc"
    fi
    ((i++))
  done

  footer
  printf "  ${F_NORD3}номер стратегии (0 — отмена):${C_RESET} "
  read -r c
  [[ "$c" == "0" || -z "$c" ]] && return
  if [[ "$c" =~ ^[0-9]+$ ]] && (( c >= 1 && c <= ${#items[@]} )); then
    apply_strategy "${items[$((c-1))]}"
  fi
}

create_custom_strategy() {
  header "Новая стратегия"
  printf "  ${F_NORD3}название:${C_RESET} "
  read -r name
  [[ -z "$name" ]] && { fail "ну хоть что-то"; return; }
  name="${name,,}"; name="${name// /-}"
  local file="$ZAPRET_STRATEGIES/${name}.conf"
  [[ -f "$file" ]] && { fail "'$name' уже есть"; return; }
  printf "  ${F_NORD3}описание:${C_RESET} "
  read -r desc
  printf "  ${F_NORD3}режим (nfqws/tpws) [nfqws]:${C_RESET} "
  read -r mode; [[ -z "$mode" ]] && mode="nfqws"
  printf "  ${F_NORD3}аргументы nfqws (полная строка):${C_RESET} "
  read -r args
  cat > "$file" << STRAT_END
# Стратегия: $name
# DESC: $desc
NFQWS_MODE="$mode"
NFQWS_QNUM="200"
NFQWS_ARGS="$args"
STRAT_END
  ok "'$name' создана"
  confirm "применить сейчас?" && apply_strategy "$name"
  footer
}

edit_current_strategy() {
  local file="$ZAPRET_STRATEGIES/${ZAPRET_STRATEGY}.conf"
  if [[ ! -f "$file" ]]; then
    fail "файл не найден: $file"
    return
  fi
  if   cmd_exists nano; then nano "$file"
  elif cmd_exists vim; then vim "$file"
  elif cmd_exists vi;  then vi "$file"
  else fail "нет редактора (nano/vim)"; return
  fi
  confirm "перезагрузить?" && apply_strategy "$ZAPRET_STRATEGY"
}
