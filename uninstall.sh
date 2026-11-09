#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Removes everything ./install.sh installed, in reverse order, and puts back the
# settings it changed. The login and boot screens need sudo; the commands are
# printed at the end.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
[ "$(id -u)" != 0 ] || { echo "Run as your user, not with sudo."; exit 1; }
run() { echo; echo "== $1"; shift; "$@" || echo "   (failed, continuing)"; }
run "Desktop settings" "$HERE/apply-settings.sh" --revert
run "Global theme" "$HERE/global-theme/uninstall.sh"
run "Lock screen" "$HERE/lockscreen/uninstall.sh"
run "Sunken tray box" "$HERE/tray-frame/uninstall.sh"
run "Start button" "$HERE/start-button/uninstall.sh"
run "Panel style" "$HERE/plasma-style/uninstall.sh"
run "Title bars" "$HERE/aurorae/uninstall.sh"
run "Colour scheme" "$HERE/colors/uninstall.sh"
echo
echo "Done. If you installed the login and boot screens, also run:"
echo "    sudo $HERE/sddm/uninstall.sh"
echo "    sudo $HERE/plymouth/uninstall.sh"
echo "Then log out and back in."
