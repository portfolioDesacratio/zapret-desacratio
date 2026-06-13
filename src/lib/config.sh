#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# zapret-desacratio — Config Management
# ═══════════════════════════════════════════════════════════════

load_config() {
    if [[ -f "$ZAPRET_CONFIG_FILE" ]]; then
        source "$ZAPRET_CONFIG_FILE"
    fi
    
    # Default values
    ZAPRET_MODE="${ZAPRET_MODE:-nfqws}"
    ZAPRET_STRATEGY="${ZAPRET_STRATEGY:-default}"
    ZAPRET_AUTOSTART="${ZAPRET_AUTOSTART:-true}"
    ZAPRET_DEBUG="${ZAPRET_DEBUG:-false}"
    ZAPRET_PORT_RANGE="${ZAPRET_PORT_RANGE:-80,443}"
    ZAPRET_THEME="${ZAPRET_THEME:-nord}"
}

save_config() {
    cat > "$ZAPRET_CONFIG_FILE" << EOF
# ═══════════════════════════════════════════════════════════════
# zapret-desacratio Configuration
# Автоматически сгенерировано. Ручные изменения будут сохранены.
# ═══════════════════════════════════════════════════════════════

# Режим работы: nfqws, tpws
ZAPRET_MODE="$ZAPRET_MODE"

# Активная стратегия
ZAPRET_STRATEGY="$ZAPRET_STRATEGY"

# Автостарт при загрузке системы
ZAPRET_AUTOSTART="$ZAPRET_AUTOSTART"

# Режим отладки
ZAPRET_DEBUG="$ZAPRET_DEBUG"

# Порты для обработки
ZAPRET_PORT_RANGE="$ZAPRET_PORT_RANGE"

# Тема оформления TUI
ZAPRET_THEME="$ZAPRET_THEME"

# Дата последнего обновления
ZAPRET_LAST_UPDATE="$(date '+%Y-%m-%d %H:%M:%S')"
EOF
}

load_strategy() {
    local strategy="${1:-$ZAPRET_STRATEGY}"
    local strategy_file="$ZAPRET_STRATEGIES/${strategy}.conf"
    
    if [[ ! -f "$strategy_file" ]]; then
        strategy_file="$ZAPRET_STRATEGIES/default.conf"
    fi
    
    source "$strategy_file"
}

get_strategy_list() {
    local strategies=()
    for f in "$ZAPRET_STRATEGIES"/*.conf; do
        local name
        name=$(basename "$f" .conf)
        strategies+=("$name")
    done
    echo "${strategies[@]}"
}

get_theme_list() {
    local themes=()
    for f in "$ZAPRET_THEME_DIR"/*.sh; do
        local name
        name=$(basename "$f" .sh)
        themes+=("$name")
    done
    echo "${themes[@]}"
}

load_theme() {
    local theme="${1:-${ZAPRET_THEME:-nord}}"
    local theme_file="$ZAPRET_THEME_DIR/${theme}.sh"
    
    if [[ -f "$theme_file" ]]; then
        source "$theme_file"
    fi
}
