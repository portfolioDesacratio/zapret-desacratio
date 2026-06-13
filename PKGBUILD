# Maintainer: portfolioDesacratio <desacratio@gmail.com>
# ═══════════════════════════════════════════════════════════════
# PKGBUILD for zapret-desacratio
# AUR package: yay -S zapret-desacratio
# ═══════════════════════════════════════════════════════════════

pkgname=zapret-desacratio
pkgver=1.0.0
pkgrel=1
pkgdesc="Universal DPI circumvention tool with beautiful TUI control panel. Wraps bol-van/zapret with easy install, strategy management, and domain lists."
arch=('x86_64' 'aarch64')
url="https://github.com/portfolioDesacratio/zapret-desacratio"
license=('GPL3')
depends=(
    'bash'
    'glibc'
    'libcap'
    'iptables'
    'ip6tables'
)
makedepends=(
    'git'
    'gcc'
    'make'
    'base-devel'
    'libnetfilter_queue'
)
conflicts=('zapret')
provides=('zapret')
source=("${pkgname}-${pkgver}.tar.gz::https://github.com/portfolioDesacratio/${pkgname}/archive/v${pkgver}.tar.gz")
sha256sums=('SKIP')

build() {
    cd "${srcdir}/${pkgname}-${pkgver}"
    
    # Clone and build bol-van/zapret core
    git clone --depth=1 https://github.com/bol-van/zapret.git zapret-core
    cd zapret-core
    
    msg2 "Compiling zapret core..."
    make -j$(nproc)
    
    cd ..
}

package() {
    cd "${srcdir}/${pkgname}-${pkgver}"
    
    # ─── Install binaries ─────────────────────────────────────
    install -dm755 "${pkgdir}/opt/zapret/bin"
    install -m755 zapret-core/nfqws/nfqws "${pkgdir}/opt/zapret/bin/"
    install -m755 zapret-core/tpws/tpws "${pkgdir}/opt/zapret/bin/"
    install -m755 zapret-core/ip2net/ip2net "${pkgdir}/opt/zapret/bin/"
    install -m755 zapret-core/mdig/mdig "${pkgdir}/opt/zapret/bin/"
    
    # Symlinks for CLI
    install -dm755 "${pkgdir}/usr/local/bin"
    ln -s /opt/zapret/bin/nfqws "${pkgdir}/usr/local/bin/nfqws"
    ln -s /opt/zapret/bin/tpws "${pkgdir}/usr/local/bin/tpws"
    
    # ─── Install TUI control panel ────────────────────────────
    install -dm755 "${pkgdir}/opt/zapret/lib"
    install -m755 src/zapret "${pkgdir}/usr/bin/zapret"
    
    for lib in src/lib/*.sh; do
        install -m644 "$lib" "${pkgdir}/opt/zapret/lib/"
    done
    
    # ─── Install strategies ───────────────────────────────────
    install -dm755 "${pkgdir}/opt/zapret/strategies"
    for strat in strategies/*.conf; do
        install -m644 "$strat" "${pkgdir}/opt/zapret/strategies/"
    done
    
    # ─── Install domain lists ─────────────────────────────────
    install -dm755 "${pkgdir}/opt/zapret/lists"
    for list in lists/*.txt; do
        install -m644 "$list" "${pkgdir}/opt/zapret/lists/"
    done
    
    # ─── Install themes ───────────────────────────────────────
    install -dm755 "${pkgdir}/opt/zapret/themes"
    for theme in themes/*.sh; do
        install -m644 "$theme" "${pkgdir}/opt/zapret/themes/"
    done
    
    # ─── Default config ───────────────────────────────────────
    install -dm755 "${pkgdir}/etc/zapret"
    cat > "${pkgdir}/etc/zapret/config.sh" << 'CONFIGEOF'
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
    
    # ─── Systemd service ──────────────────────────────────────
    install -dm755 "${pkgdir}/usr/lib/systemd/system"
    cat > "${pkgdir}/usr/lib/systemd/system/zapret.service" << 'SERVICEEOF'
[Unit]
Description=zapret-desacratio — DPI circumvention daemon
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/opt/zapret/bin/nfqws --daemon --qnum=200 --dpi-desync=fake --wssize=1:6
ExecStop=/usr/bin/pkill -f nfqws
Restart=on-failure
RestartSec=10
KillMode=process
Nice=-10

[Install]
WantedBy=multi-user.target
SERVICEEOF
    
    # ─── .SRCINFO ─────────────────────────────────────────────
    cat > "${pkgdir}/usr/share/${pkgname}/.SRCINFO" << 'SRCINFOEOF'
pkgbase = zapret-desacratio
pkgdesc = Universal DPI circumvention tool with beautiful TUI control panel
pkgver = 1.0.0
pkgrel = 1
url = https://github.com/portfolioDesacratio/zapret-desacratio
arch = x86_64
arch = aarch64
license = GPL3
depends = bash
depends = glibc
depends = libcap
depends = iptables
depends = ip6tables
makedepends = git
makedepends = gcc
makedepends = make
makedepends = base-devel
conflicts = zapret
provides = zapret
SRCINFOEOF
    
    # ─── Post-install message ─────────────────────────────────
    cat > "${pkgdir}/usr/share/${pkgname}/post-install.txt" << 'POSTEOF'
╔══════════════════════════════════════════════════════════════╗
║              zapret-desacratio установлен!                    ║
╚══════════════════════════════════════════════════════════════╝

Для запуска панели управления:
    zapret

Для ручного запуска:
    sudo systemctl start zapret

Логи:
    /var/log/zapret.log

Конфигурация:
    /etc/zapret/config.sh
POSTEOF
}
