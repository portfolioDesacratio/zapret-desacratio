#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# zapret-desacratio — Distro Detection
# ═══════════════════════════════════════════════════════════════

detect_distro() {
    local distro=""
    local pkg_manager=""
    local init_system=""
    
    # ─── Detect OS ─────────────────────────────────────────────
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        distro="$ID"
        [[ -n "$ID_LIKE" ]] && distro_like="$ID_LIKE"
    elif [[ -f /etc/arch-release ]]; then
        distro="arch"
    elif [[ -f /etc/debian_version ]]; then
        distro="debian"
    elif [[ -f /etc/fedora-release ]]; then
        distro="fedora"
    elif [[ -f /etc/gentoo-release ]]; then
        distro="gentoo"
    elif [[ -f /etc/SuSE-release ]]; then
        distro="opensuse"
    elif [[ -f /etc/alpine-release ]]; then
        distro="alpine"
    elif [[ -f /etc/redhat-release ]]; then
        distro="rhel"
    elif command -v termux-setup-package &>/dev/null; then
        distro="termux"
    else
        distro="unknown"
    fi
    
    # ─── Detect Package Manager ────────────────────────────────
    if cmd_exists apt-get; then
        pkg_manager="apt-get"
    elif cmd_exists pacman; then
        pkg_manager="pacman"
    elif cmd_exists dnf; then
        pkg_manager="dnf"
    elif cmd_exists yum; then
        pkg_manager="yum"
    elif cmd_exists zypper; then
        pkg_manager="zypper"
    elif cmd_exists emerge; then
        pkg_manager="emerge"
    elif cmd_exists apk; then
        pkg_manager="apk"
    elif cmd_exists xbps-install; then
        pkg_manager="xbps"
    elif cmd_exists pkg; then
        pkg_manager="pkg"
    else
        pkg_manager="unknown"
    fi
    
    # ─── Detect Init System ────────────────────────────────────
    if [[ -d /run/systemd/system ]]; then
        init_system="systemd"
    elif command -v rc-update &>/dev/null; then
        init_system="openrc"
    elif command -v runsvdir &>/dev/null; then
        init_system="runit"
    elif [[ -f /sbin/openrc ]]; then
        init_system="openrc"
    elif [[ -f /etc/init.d/functions ]]; then
        init_system="sysvinit"
    elif [[ -f /sbin/init ]] && strings /sbin/init 2>/dev/null | grep -qi "busybox"; then
        init_system="busybox"
    else
        init_system="unknown"
    fi
    
    # ─── Store Results ─────────────────────────────────────────
    echo "$distro|$pkg_manager|$init_system"
}

# Parse results
DISTRO_INFO=$(detect_distro)
DISTRO=$(echo "$DISTRO_INFO" | cut -d'|' -f1)
PKG_MANAGER=$(echo "$DISTRO_INFO" | cut -d'|' -f2)
INIT_SYSTEM=$(echo "$DISTRO_INFO" | cut -d'|' -f3)

# Map to canonical distro family
get_distro_family() {
    case "$DISTRO" in
        arch|artix|manjaro|endeavour|garuda|cachyos) echo "arch" ;;
        debian|ubuntu|mint|kali|pop|zorin|mx|elementary) echo "debian" ;;
        fedora|nobara) echo "fedora" ;;
        rhel|centos|rocky|alma|oracle) echo "rhel" ;;
        opensuse|suse|sled|sles) echo "suse" ;;
        gentoo|calculate) echo "gentoo" ;;
        alpine) echo "alpine" ;;
        void) echo "void" ;;
        alt) echo "alt" ;;
        *) echo "unknown" ;;
    esac
}

DISTRO_FAMILY=$(get_distro_family)

# Get install commands for packages
get_install_cmd() {
    case "$PKG_MANAGER" in
        apt-get)
            echo "DEBIAN_FRONTEND=noninteractive apt-get install -y"
            ;;
        pacman)
            echo "pacman -S --noconfirm"
            ;;
        dnf)
            echo "dnf install -y"
            ;;
        yum)
            echo "yum install -y"
            ;;
        zypper)
            echo "zypper install -y"
            ;;
        emerge)
            echo "emerge"
            ;;
        apk)
            echo "apk add"
            ;;
        xbps)
            echo "xbps-install -S -y"
            ;;
        pkg)
            echo "pkg install -y"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Get build dependencies for zapret
get_build_deps() {
    case "$DISTRO_FAMILY" in
        arch)
            echo "base-devel libcap git"
            ;;
        debian)
            echo "build-essential libcap-dev git libnetfilter-queue-dev libpcap-dev"
            ;;
        fedora|rhel)
            echo "gcc make libcap-devel git libnetfilter_queue-devel libpcap-devel"
            ;;
        suse)
            echo "gcc make libcap-progs git libnetfilter_queue-devel libpcap-devel"
            ;;
        gentoo)
            echo "sys-devel/base-devel sys-libs/libcap git"
            ;;
        alpine)
            echo "build-base libcap-dev git linux-headers"
            ;;
        void)
            echo "base-devel libcap-devel git"
            ;;
        alt)
            echo "gcc make libcap-devel git"
            ;;
        *)
            echo "gcc make libcap-dev git"
            ;;
    esac
}
