#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Installs the Windows 2000 lock screen as a per-user override of the Plasma desktop shell.
# Only the lockscreen/ folder is real; everything else links to the system shell, so
# Plasma upgrades still update the rest of the shell.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/detect.sh"; . "$HERE/../lib/branding.sh"; . "$HERE/../lib/icons.sh"; . "$HERE/../lib/settings.sh"
p2k_not_root

# a lock screen copy per Plasma version (qml-6.7/ …); qml/ is the newest tested one
SRC="$HERE/qml"
[ -d "$HERE/qml-$P2K_PLASMA" ] && SRC="$HERE/qml-$P2K_PLASMA"
TESTED=$(cat "$HERE/TESTED")
case " $TESTED " in
    *" $P2K_PLASMA "*) ;;
    *) echo "Note: tested on Plasma $TESTED, you have $P2K_PLASMA. If it fails to load, Plasma shows its basic lock screen; run ./uninstall.sh." ;;
esac

SYS=/usr/share/plasma/shells/org.kde.plasma.desktop
ME="$HOME/.local/share/plasma/shells/org.kde.plasma.desktop"
if [ -e "$ME/metadata.json" ] && [ ! -L "$ME/metadata.json" ]; then
    echo "$ME is another override of the desktop shell, not Plasma 2000's; leaving it alone."
    exit 1
fi
mkdir -p "$ME/contents"
# links that point nowhere after a Plasma upgrade
for l in "$ME"/contents/*; do [ -L "$l" ] && [ ! -e "$l" ] && rm -f "$l"; done
ln -sfn "$SYS/metadata.json" "$ME/metadata.json"
for d in "$SYS"/contents/*; do
    [ "$(basename "$d")" = lockscreen ] || ln -sfn "$d" "$ME/contents/"
done
rm -rf "$ME/contents/lockscreen"
cp -r "$SRC" "$ME/contents/lockscreen"
p2k_write_branding "$ME/contents/lockscreen"
p2k_install_icon system-lock-screen 48 "$ME/contents/lockscreen/icons/system-lock-screen-48.png"
p2k_install_icon dialog-warning 48 "$ME/contents/lockscreen/icons/dialog-warning-48.png"
rm -rf "$HOME/.cache/kscreenlocker_greet/qmlcache"
echo "Installed ($P2K_NAME). Preview: $P2K_LIBEXEC/kscreenlocker_greet --testing"
