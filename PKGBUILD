# Maintainer: Stefan Zipproth <s.zipproth@ditana.org>

pkgname=xfce-display-config-observer
pkgver=1.007
pkgrel=1
pkgdesc="A systemd service that monitors changes to the XFCE display configuration to automatically adjust the font DPI to match the display DPI. It also adjusts the height of the XFCE panel."
arch=(any)
url="https://github.com/acrion/xfce-display-config-observer"
license=('AGPL-3.0-or-later')
conflicts=()
install=xfce-display-config-observer.install
depends=(
    bc
    findutils # for xargs
    grep
    inotify-tools
    procps-ng # for pgrep
    xfconf
    xmlstarlet
    xorg-xrandr
)
makedepends=()
source=(
    xfce-display-config-observer.1
    xfce-display-config-observer.service
    observer.sh
    updater.sh
)
sha256sums=(
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
)

package() {
    install -Dm644 "$srcdir/xfce-display-config-observer.1"       "$pkgdir/usr/share/man/man1/xfce-display-config-observer.1"
    install -Dm644 "$srcdir/xfce-display-config-observer.service" "$pkgdir/usr/lib/systemd/user/xfce-display-config-observer.service"
    install -Dm755 "$srcdir/observer.sh"                          "$pkgdir/usr/lib/xfce4/display-config-observer/observer.sh"
    install -Dm755 "$srcdir/updater.sh"                           "$pkgdir/usr/lib/xfce4/display-config-observer/updater.sh"
}
