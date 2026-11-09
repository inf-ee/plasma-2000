#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Installs everything that doesn't need root, in the right order, then prints the
# two commands for the login and boot screens (they need sudo).
#   ./install.sh            keep your panels, add the Plasma 2000 widgets to them
#   ./install.sh --layout   replace your panels with the Windows 2000 taskbar
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib/detect.sh"
[ "$(id -u)" != 0 ] || { echo "Run as your user, not with sudo."; exit 1; }
case "$P2K_PLASMA" in
    6.*) ;;
    *) echo "Plasma 6 is required (found: ${P2K_PLASMA:-none})."; exit 1 ;;
esac
for t in SE98C ModernXP2; do
    [ -e "$HOME/.local/share/icons/$t" ] || [ -e "$HOME/.icons/$t" ] || [ -e "/usr/share/icons/$t" ] || \
        echo "Note: $t is not installed yet (see README: install it from the KDE Store, then re-run)."
done

run() { echo; echo "== $1"; shift; "$@"; }
run "Colour scheme" "$HERE/colors/install.sh"
run "Title bars" "$HERE/aurorae/install.sh"
run "Panel style" "$HERE/plasma-style/install.sh"
run "Start button (downloads Plasma's Start menu source)" "$HERE/start-button/build.sh" \
    || echo "Start button skipped; Plasma's own Start menu stays. See start-button/README.md."
run "Sunken tray box" "$HERE/tray-frame/install.sh"
run "Lock screen" "$HERE/lockscreen/install.sh"
run "Global theme" "$HERE/global-theme/install.sh" "$@"
run "Desktop settings" "$HERE/apply-settings.sh"

echo
echo "Done. For the login and boot screens run:"
echo "    sudo $HERE/sddm/install.sh"
echo "    sudo $HERE/plymouth/install.sh"
echo "Then log out and back in."
