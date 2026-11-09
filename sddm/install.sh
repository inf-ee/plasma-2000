#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Installs the Windows 2000 login theme and makes it the active SDDM theme. Run with sudo.
# Needs SDDM 0.21 or newer with Qt 6.
set -e
[ "$(id -u)" = 0 ] || { echo "Run with sudo: sudo $0"; exit 1; }
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/detect.sh"; . "$HERE/../lib/branding.sh"; . "$HERE/../lib/icons.sh"
THEME=plasma2000
DEST="/usr/share/sddm/themes/$THEME"
CONF=/etc/sddm.conf.d/kde_settings.conf   # the file System Settings' Login Screen page writes
rm -rf "$DEST"
cp -r "$HERE/theme" "$DEST"
p2k_write_branding "$DEST"
p2k_install_icon dialog-warning 48 "$DEST/icons/dialog-warning-48.png"
p2k_install_icon system-shutdown 48 "$DEST/icons/system-shutdown-48.png"
chmod -R a+rX "$DEST"

mkdir -p /etc/sddm.conf.d
# Backup goes outside sddm.conf.d: SDDM reads every file in that folder.
BACKUP=/etc/sddm-kde_settings.conf.before-plasma2000
[ -f "$BACKUP" ] || { [ -f "$CONF" ] && cp "$CONF" "$BACKUP"; } || true
if [ -f "$CONF" ] && grep -q '^Current=' "$CONF"; then
    sed -i "s/^Current=.*/Current=$THEME/" "$CONF"
else
    printf '\n[Theme]\nCurrent=%s\n' "$THEME" >> "$CONF"
fi
echo "Installed ($P2K_NAME). Active theme: $(grep '^Current=' "$CONF")"
