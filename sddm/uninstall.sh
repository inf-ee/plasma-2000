#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Switches the login screen back to the theme used before and removes the Plasma 2000 theme.
# Run with sudo.
set -e
[ "$(id -u)" = 0 ] || { echo "Run with sudo: sudo $0"; exit 1; }
CONF=/etc/sddm.conf.d/kde_settings.conf
BACKUP=/etc/sddm-kde_settings.conf.before-plasma2000   # made by install.sh
PREV=
[ -f "$BACKUP" ] && PREV=$(sed -n 's/^Current=//p' "$BACKUP" | head -n1)
case "$PREV" in plasma2000 | *[!A-Za-z0-9._-]*) PREV= ;; esac
if [ -f "$CONF" ]; then
    # the theme line from before, or none (then the distribution's own setting applies again)
    if [ -n "$PREV" ]; then sed -i "s/^Current=plasma2000\$/Current=$PREV/" "$CONF"
    else sed -i '/^Current=plasma2000$/d' "$CONF"; fi
fi
rm -f "$BACKUP"
rm -rf /usr/share/sddm/themes/plasma2000
echo "Removed. Active theme: $(grep '^Current=' "$CONF" 2>/dev/null)"
