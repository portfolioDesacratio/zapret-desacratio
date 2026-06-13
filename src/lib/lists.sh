#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# zapret-desacratio — Domain List Management
# ═══════════════════════════════════════════════════════════════

show_lists_menu() {
  while true; do
    clear_screen
    header "Списки доменов"

    local i=1 items=()
    for f in "$ZAPRET_LISTS"/*.txt; do
      local name; name=$(basename "$f" .txt)
      local count; count=$(wc -l < "$f" 2>/dev/null || echo 0)
      items+=("$name")
      if [[ "$name" == "custom" ]]; then
        printf "  ${F_FROST2}${C_BOLD}%2s${C_RESET}  ${F_PURPLE}%s${C_RESET}  ${F_NORD3}(%s)${C_RESET}\n" "$i" "$name" "$count"
      else
        printf "  ${F_FROST2}${C_BOLD}%2s${C_RESET}  ${F_NORD6}%s${C_RESET}  ${F_NORD3}(%s)${C_RESET}\n" "$i" "$name" "$count"
      fi
      ((i++))
    done

    printf "\n"
    echo "  ${F_FROST2}a${C_RESET}  ${F_NORD6}добавить домен${C_RESET}"
    echo "  ${F_FROST2}r${C_RESET}  ${F_NORD6}удалить домен${C_RESET}"
    echo "  ${F_FROST2}s${C_RESET}  ${F_NORD6}проверить домен${C_RESET}"
    echo "  ${F_FROST2}0${C_RESET}  ${F_NORD3}← назад${C_RESET}"
    footer

    printf "  > "
    read -r c
    case "$c" in
      0) return ;;
      a) add_domain ;;
      r) remove_domain ;;
      s) check_domain ;;
      *)
        if [[ "$c" =~ ^[0-9]+$ ]] && (( c >= 1 && c <= ${#items[@]} )); then
          view_list "${items[$((c-1))]}"
        fi
        ;;
    esac
  done
}

view_list() {
  local list_name="$1"
  local file="$ZAPRET_LISTS/${list_name}.txt"
  if [[ ! -f "$file" ]]; then
    fail "список '$list_name' не найден"
    pause; return
  fi

  clear_screen
  header "Список: $list_name"

  local count=0
  while IFS= read -r domain; do
    [[ -z "$domain" || "$domain" == \#* ]] && continue
    ((count++))
    printf "  ${F_FROST2}·${C_RESET} ${F_NORD6}%s${C_RESET}\n" "$domain"
  done < "$file"

  [[ $count -eq 0 ]] && info "список пуст"
  printf "\n  ${F_NORD3}всего: ${C_BOLD}%s${C_RESET}\n" "$count"
  footer
  pause
}

add_domain() {
  printf "\n  ${F_NORD3}домен (например discord.com):${C_RESET} "
  read -r domain
  [[ -z "$domain" ]] && return

  if grep -q "^${domain}$" "$ZAPRET_LISTS/custom.txt" 2>/dev/null; then
    warn "'$domain' уже есть"
    pause; return
  fi

  echo "$domain" >> "$ZAPRET_LISTS/custom.txt"
  ok "'$domain' добавлен"
  confirm "применить сейчас?" && apply_strategy "$ZAPRET_STRATEGY"
}

remove_domain() {
  printf "\n  ${F_NORD3}домен для удаления:${C_RESET} "
  read -r domain
  [[ -z "$domain" ]] && return

  if grep -q "^${domain}$" "$ZAPRET_LISTS/custom.txt" 2>/dev/null; then
    grep -v "^${domain}$" "$ZAPRET_LISTS/custom.txt" > "$ZAPRET_LISTS/custom.tmp"
    mv "$ZAPRET_LISTS/custom.tmp" "$ZAPRET_LISTS/custom.txt"
    ok "'$domain' удалён"
    confirm "применить сейчас?" && apply_strategy "$ZAPRET_STRATEGY"
  else
    fail "'$domain' не найден"
  fi
  pause
}

check_domain() {
  printf "\n  ${F_NORD3}домен для проверки:${C_RESET} "
  read -r domain
  [[ -z "$domain" ]] && return

  info "проверка $domain…"

  if cmd_exists dig; then
    local dns; dns=$(dig +short "$domain" 2>/dev/null | head -1)
    if [[ -n "$dns" ]]; then
      info "dns           ${F_GREEN}$dns${C_RESET}"
    else
      info "dns           ${F_RED}не резолвится${C_RESET}"
    fi
  fi

  local http
  http=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://$domain" 2>/dev/null || echo "таймаут")
  if [[ "$http" == "200" || "$http" == "301" || "$http" == "302" ]]; then
    info "http          ${F_GREEN}$http (ок)${C_RESET}"
  elif [[ "$http" == "таймаут" ]]; then
    info "http          ${F_RED}таймаут (блокировка?)${C_RESET}"
  else
    info "http          ${F_YELLOW}$http${C_RESET}"
  fi

  if ping -c 1 -W 3 "$domain" &>/dev/null; then
    info "ping          ${F_GREEN}доступен${C_RESET}"
  else
    info "ping          ${F_RED}недоступен${C_RESET}"
  fi

  for f in "$ZAPRET_LISTS"/*.txt; do
    if grep -q "^${domain}$" "$f" 2>/dev/null; then
      info "в списке       $(basename "$f" .txt)"
    fi
  done

  pause
}
