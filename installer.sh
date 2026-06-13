#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# zapret-desacratio — Universal DPI Circumvention Installer
# ══════════════════════════════════════════════════════════════════════════════
# Использование:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/portfolioDesacratio/zapret-desacratio/main/installer.sh)"
#
# Поддерживаемые дистрибутивы:
#   Arch, Debian, Ubuntu, Fedora, RHEL, OpenSUSE, Gentoo, Alpine, Void, Alt
# ══════════════════════════════════════════════════════════════════════════════

set -e

# ─── Colors for installer output ─────────────────────────────────────────────
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_GREEN="\033[38;5;151m"
C_RED="\033[38;5;131m"
C_YELLOW="\033[38;5;187m"
C_BLUE="\033[38;5;110m"
C_CYAN="\033[38;5;116m"
C_PURPLE="\033[38;5;139m"
C_WHITE="\033[38;5;255m"
C_NORD3="\033[38;5;241m"
BG_GREEN="\033[48;5;151m"
BG_BLUE="\033[48;5;110m"
BG_RED="\033[48;5;131m"

# ─── Symbols ─────────────────────────────────────────────────────────────────
SYM_CHECK="${C_GREEN}✓${C_RESET}"
SYM_CROSS="${C_RED}✗${C_RESET}"
SYM_ARROW="${C_CYAN}→${C_RESET}"
SYM_BULLET="${C_BLUE}●${C_RESET}"

# ─── Banner ──────────────────────────────────────────────────────────────────
show_banner() {
    cat << 'EOF'

        ███████╗ █████╗ ██████╗ ██████╗ ███████╗████████╗
        ╚══███╔╝██╔══██╗██╔══██╗██╔══██╗██╔════╝╚══██╔══╝
          ███╔╝ ███████║██████╔╝██████╔╝█████╗     ██║
         ███╔╝  ██╔══██║██╔═══╝ ██╔══██╗██╔══╝     ██║
        ███████╗██║  ██║██║     ██║  ██║███████╗   ██║
        ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝

EOF
    printf "${C_BOLD}${C_CYAN}  zapret-desacratio — Universal DPI Circumvention${C_RESET}\n"
    printf "${C_NORD3}  Установка и управление обходом блокировок${C_RESET}\n"
    printf "\n"
}

# ─── Helper Functions ────────────────────────────────────────────────────────
print_step() { printf "  ${C_BLUE}${C_BOLD}%s/%s${C_RESET} ${C_WHITE}%s${C_RESET}\n" "$1" "$2" "$3"; }
print_success() { printf "  ${C_GREEN}${C_BOLD}✓${C_RESET} ${C_WHITE}%s${C_RESET}\n" "$1"; }
print_error() { printf "  ${C_RED}${C_BOLD}✗${C_RESET} ${C_WHITE}%s${C_RESET}\n" "$1" >&2; }
print_warn() { printf "  ${C_YELLOW}${C_BOLD}▲${C_RESET} ${C_WHITE}%s${C_RESET}\n" "$1"; }
print_info() { printf "  ${C_NORD3}%s${C_RESET}\n" "$1"; }

cmd_exists() { command -v "$1" &>/dev/null; }

run_cmd() {
    local desc="$1"
    shift
    printf "  ${C_NORD3}${desc}...${C_RESET} "
    if "$@" &>/tmp/zapret-install.log; then
        printf "${C_GREEN}✓${C_RESET}\n"
        return 0
    else
        printf "${C_RED}✗${C_RESET}\n"
        tail -5 /tmp/zapret-install.log 2>/dev/null | sed 's/^/    /'
        return 1
    fi
}

# ─── Distro Detection ────────────────────────────────────────────────────────
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO="$ID"
        DISTRO_LIKE="$ID_LIKE"
    elif [[ -f /etc/arch-release ]]; then
        DISTRO="arch"
    elif [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
    elif [[ -f /etc/fedora-release ]]; then
        DISTRO="fedora"
    elif [[ -f /etc/gentoo-release ]]; then
        DISTRO="gentoo"
    elif [[ -f /etc/alpine-release ]]; then
        DISTRO="alpine"
    elif command -v termux-setup-package &>/dev/null; then
        DISTRO="termux"
    else
        DISTRO="unknown"
    fi

    # Package manager
    if cmd_exists apt-get; then PKG_MGR="apt-get"
    elif cmd_exists pacman; then PKG_MGR="pacman"
    elif cmd_exists dnf; then PKG_MGR="dnf"
    elif cmd_exists yum; then PKG_MGR="yum"
    elif cmd_exists zypper; then PKG_MGR="zypper"
    elif cmd_exists emerge; then PKG_MGR="emerge"
    elif cmd_exists apk; then PKG_MGR="apk"
    elif cmd_exists xbps-install; then PKG_MGR="xbps"
    else PKG_MGR="unknown"; fi

    # Init system
    if [[ -d /run/systemd/system ]]; then INIT="systemd"
    elif cmd_exists rc-update; then INIT="openrc"
    elif cmd_exists runsvdir; then INIT="runit"
    elif cmd_exists sv; then INIT="runit"
    else INIT="unknown"; fi
}

# ─── Pre-Install Checks ──────────────────────────────────────────────────────
pre_checks() {
    print_info "Проверка системы..."
    
    if [[ $EUID -ne 0 ]]; then
        print_error "Этот скрипт требует прав root. Запусти с sudo."
        exit 1
    fi
    
    if [[ "$DISTRO" == "unknown" ]]; then
        print_warn "Не удалось определить дистрибутив. Установка продолжится,"
        print_warn "но некоторые шаги могут потребовать ручного вмешательства."
    fi
    
    if [[ "$PKG_MGR" == "unknown" ]]; then
        print_error "Не удалось определить пакетный менеджер."
        exit 1
    fi
    
    if ! cmd_exists curl && ! cmd_exists wget; then
        print_warn "Не найден curl или wget. Попытка установить curl..."
        case "$PKG_MGR" in
            apt-get) apt-get install -y curl ;;
            pacman) pacman -S --noconfirm curl ;;
            dnf) dnf install -y curl ;;
            apk) apk add curl ;;
            *) print_error "Установи curl вручную и запусти скрипт снова"; exit 1 ;;
        esac
    fi
    
    if ! cmd_exists git; then
        print_warn "Не найден git. Попытка установить..."
        case "$PKG_MGR" in
            apt-get) apt-get install -y git ;;
            pacman) pacman -S --noconfirm git ;;
            dnf) dnf install -y git ;;
            apk) apk add git ;;
            *) print_error "Установи git вручную"; exit 1 ;;
        esac
    fi
    
    print_success "Система: ${C_BOLD}${DISTRO}${C_RESET} (${PKG_MGR}, ${INIT})"
}

# ─── Install Build Dependencies ──────────────────────────────────────────────
install_deps() {
    case "$DISTRO" in
        arch|artix|manjaro|endeavour|garuda|cachyos)
            DEPS="base-devel libcap git libnetfilter_queue iptables"
            PRECMD="$PKG_MGR -Sy"
            INSTALL_CMD="$PKG_MGR -S --noconfirm"
            ;;
        debian|ubuntu|mint|kali|pop|zorin)
            DEPS="build-essential libcap-dev git libnetfilter-queue-dev libpcap-dev"
            INSTALL_CMD="DEBIAN_FRONTEND=noninteractive $PKG_MGR install -y"
            ;;
        fedora|nobara)
            DEPS="gcc make libcap-devel git libnetfilter_queue-devel libpcap-devel"
            INSTALL_CMD="$PKG_MGR install -y"
            ;;
        rhel|centos|rocky|alma|oracle)
            DEPS="gcc make libcap-devel git libnetfilter_queue-devel libpcap-devel"
            INSTALL_CMD="$PKG_MGR install -y"
            ;;
        opensuse|suse|sled|sles)
            DEPS="gcc make libcap-progs git libnetfilter_queue-devel libpcap-devel"
            INSTALL_CMD="$PKG_MGR install -y"
            ;;
        gentoo)
            DEPS="sys-devel/base-devel sys-libs/libcap git"
            INSTALL_CMD="$PKG_MGR"
            print_warn "Gentoo: установи зависимости вручную: emerge $DEPS"
            return 0
            ;;
        alpine)
            DEPS="build-base libcap-dev git linux-headers"
            INSTALL_CMD="$PKG_MGR add"
            ;;
        void)
            DEPS="base-devel libcap-devel git"
            INSTALL_CMD="$PKG_MGR install -S -y"
            ;;
        alt)
            DEPS="gcc make libcap-devel git"
            INSTALL_CMD="$PKG_MGR install -y"
            ;;
        *)
            DEPS="gcc make libcap-dev git"
            INSTALL_CMD="$PKG_MGR install -y"
            print_warn "Дистрибутив '$DISTRO' может потребовать ручной установки зависимостей."
            ;;
    esac
    
    run_cmd "Установка зависимостей сборки" bash -c "${PRECMD:+$PRECMD && }$INSTALL_CMD $DEPS" || {
        print_warn "Некоторые пакеты не установились. Продолжаем..."
    }
}

# ─── Clone and Build zapret ──────────────────────────────────────────────────
build_zapret() {
    local tmpdir="/tmp/zapret-build-$$"
    
    print_info "Загрузка исходников bol-van/zapret..."
    if ! git clone --depth=1 https://github.com/bol-van/zapret.git "$tmpdir" 2>/dev/null; then
        print_error "Не удалось клонировать репозиторий."
        print_info "Проверь соединение с GitHub."
        exit 1
    fi
    
    cd "$tmpdir"
    print_info "Компиляция zapret..."
    
    if ! make -j$(nproc) 2>/tmp/zapret-make.log; then
        print_error "Ошибка компиляции. Лог:"
        tail -10 /tmp/zapret-make.log | sed 's/^/    /'
        exit 1
    fi
    
    print_success "zapret скомпилирован"
    
    # Install binaries
    print_info "Установка бинарных файлов..."
    mkdir -p /opt/zapret/bin
    # The Makefile's "all" target moves built exes to binaries/my/
    if [ -d "binaries/my" ]; then
        cp -f binaries/my/* /opt/zapret/bin/
    else
        # Fallback: copy from subdirs directly (unlikely but safe)
        cp -f nfq/nfqws /opt/zapret/bin/ 2>/dev/null
        cp -f tpws/tpws /opt/zapret/bin/ 2>/dev/null
        cp -f ip2net/ip2net /opt/zapret/bin/ 2>/dev/null
        cp -f mdig/mdig /opt/zapret/bin/ 2>/dev/null
    fi
    chmod +x /opt/zapret/bin/*
    
    # Symlinks
    ln -sf /opt/zapret/bin/nfqws /usr/local/bin/nfqws
    ln -sf /opt/zapret/bin/tpws /usr/local/bin/tpws
    
    # Cleanup (cd out first so we don't hold a reference to a deleted dir)
    cd /
    rm -rf "$tmpdir"
    print_success "Бинарные файлы установлены в ${C_BOLD}/opt/zapret/bin${C_RESET}"
}

# ─── Install Control Script and Configs ──────────────────────────────────────
install_control() {
    local repo_url="https://github.com/portfolioDesacratio/zapret-desacratio.git"
    local tmpdir="/tmp/zapret-control-$$"
    
    print_info "Загрузка панели управления..."
    git clone --depth=1 "$repo_url" "$tmpdir" 2>/dev/null || {
        print_error "Не удалось загрузить файлы управления."
        print_info "Проверь репозиторий: $repo_url"
        exit 1
    }
    
    # Create directories
    mkdir -p /opt/zapret/{lib,strategies,lists,themes,config}
    mkdir -p /etc/zapret
    
    # Install libraries
    cp -r "$tmpdir/src/lib/"* /opt/zapret/lib/
    
    # Install strategies, lists, themes
    cp -r "$tmpdir/strategies/"* /opt/zapret/strategies/
    cp -r "$tmpdir/lists/"* /opt/zapret/lists/
    cp -r "$tmpdir/themes/"* /opt/zapret/themes/
    
    # Install main control script
    cp "$tmpdir/src/zapret" /usr/bin/zapret
    chmod +x /usr/bin/zapret
    
    # Create default config
    cat > /etc/zapret/config.sh << 'CONFIGEOF'
# ═══════════════════════════════════════════════════════════════
# zapret-desacratio Configuration
# ═══════════════════════════════════════════════════════════════
ZAPRET_MODE="nfqws"
ZAPRET_STRATEGY="default"
ZAPRET_AUTOSTART="true"
ZAPRET_DEBUG="false"
ZAPRET_PORT_RANGE="80,443"
ZAPRET_THEME="nord"
ZAPRET_LAST_UPDATE="$(date '+%Y-%m-%d %H:%M:%S')"
CONFIGEOF

    # Create fake TLS/QUIC files directory
    mkdir -p /etc/zapret/files/fake
    cp -r "$tmpdir/files/fake/"* /etc/zapret/files/fake/ 2>/dev/null || true
    
    # Copy installer to /opt/zapret/ for reinstall
    cp "$0" /opt/zapret/installer.sh 2>/dev/null || true
    
    rm -rf "$tmpdir"
    print_success "Панель управления установлена"
}

# ─── Create Systemd Service ──────────────────────────────────────────────────
setup_service() {
    if [[ "$INIT" != "systemd" ]]; then
        print_warn "Система инициализации '$INIT' не поддерживает systemd."
        print_info "Настрой сервис вручную или используй 'zapret' для ручного управления."
        return
    fi
    
    cat > /etc/systemd/system/zapret.service << 'SERVICEEOF'
[Unit]
Description=zapret-desacratio — DPI circumvention daemon
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStartPre=/bin/bash -c '/sbin/iptables -N ZAPRET 2>/dev/null; /sbin/iptables -F ZAPRET 2>/dev/null; /sbin/iptables -I OUTPUT -p tcp -m multiport --dports 80,443 -j ZAPRET 2>/dev/null; /sbin/iptables -A ZAPRET -j NFQUEUE --queue-num 200 --queue-bypass 2>/dev/null; /sbin/ip6tables -N ZAPRET 2>/dev/null; /sbin/ip6tables -F ZAPRET 2>/dev/null; /sbin/ip6tables -I OUTPUT -p tcp -m multiport --dports 80,443 -j ZAPRET 2>/dev/null; /sbin/ip6tables -A ZAPRET -j NFQUEUE --queue-num 200 --queue-bypass 2>/dev/null; /sbin/iptables -I OUTPUT -p udp --dport 443 -j DROP 2>/dev/null; /sbin/ip6tables -I OUTPUT -p udp --dport 443 -j DROP 2>/dev/null; true'
ExecStart=/opt/zapret/bin/nfqws --qnum=200 --filter-tcp=80 --dpi-desync=split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new --filter-tcp=443 --dpi-desync=fake --dpi-desync-fooling=badsum
ExecStop=/usr/bin/pkill -f nfqws
ExecStopPost=/bin/bash -c '/sbin/iptables -F ZAPRET 2>/dev/null; /sbin/iptables -X ZAPRET 2>/dev/null; /sbin/ip6tables -F ZAPRET 2>/dev/null; /sbin/ip6tables -X ZAPRET 2>/dev/null; /sbin/iptables -D OUTPUT -p udp --dport 443 -j DROP 2>/dev/null; /sbin/ip6tables -D OUTPUT -p udp --dport 443 -j DROP 2>/dev/null; true'
Restart=on-failure
RestartSec=10
KillMode=mixed
Nice=-10

[Install]
WantedBy=multi-user.target
SERVICEEOF

    systemctl daemon-reload 2>/dev/null || true
    systemctl enable zapret 2>/dev/null && print_success "Автозапуск zapret включён" || print_warn "Не удалось включить автозапуск"
    
    print_success "Systemd сервис создан"
}

# ─── Post-Install Notes ──────────────────────────────────────────────────────
show_finish() {
    cat << EOF

    ${C_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}
    ${C_BOLD}${C_CYAN}          Установка zapret-desacratio завершена!${C_RESET}
    ${C_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}

    ${C_WHITE}Команда для управления:${C_RESET}
    ${C_BOLD}       zapret${C_RESET}

    ${C_WHITE}Запустить сейчас:${C_RESET}
    ${C_BOLD}       sudo zapret${C_RESET}

    ${C_NORD3}Подробнее: https://github.com/portfolioDesacratio/zapret-desacratio${C_RESET}
    ${C_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}

EOF
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    clear
    show_banner
    detect_distro
    
    echo "  ${C_NORD3}Дистрибутив:${C_RESET} ${C_WHITE}${DISTRO}${C_RESET}"
    echo "  ${C_NORD3}Пакетный менеджер:${C_RESET} ${C_WHITE}${PKG_MGR}${C_RESET}"
    echo "  ${C_NORD3}Система инициализации:${C_RESET} ${C_WHITE}${INIT}${C_RESET}"
    echo ""
    
    pre_checks
    
    echo ""
    print_info "Начинается установка..."
    echo ""
    
    # Installation steps
    TOTAL=5
    
    printf "\n  ${C_BOLD}${C_BLUE}[ ШАГ 1/${TOTAL} ]${C_RESET} ${C_WHITE}Установка зависимостей${C_RESET}\n"
    install_deps
    
    echo ""
    printf "\n  ${C_BOLD}${C_BLUE}[ ШАГ 2/${TOTAL} ]${C_RESET} ${C_WHITE}Сборка zapret${C_RESET}\n"
    build_zapret
    
    echo ""
    printf "\n  ${C_BOLD}${C_BLUE}[ ШАГ 3/${TOTAL} ]${C_RESET} ${C_WHITE}Установка панели управления${C_RESET}\n"
    install_control
    
    echo ""
    printf "\n  ${C_BOLD}${C_BLUE}[ ШАГ 4/${TOTAL} ]${C_RESET} ${C_WHITE}Настройка сервиса${C_RESET}\n"
    setup_service
    
    echo ""
    printf "\n  ${C_BOLD}${C_BLUE}[ ШАГ 5/${TOTAL} ]${C_RESET} ${C_WHITE}Завершение${C_RESET}\n"
    show_finish
}

main "$@"
