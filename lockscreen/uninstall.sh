#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Removes the Windows 2000 lock screen; Plasma's own is used again.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/settings.sh"
p2k_not_root
ME="$HOME/.local/share/plasma/shells/org.kde.plasma.desktop"
if [ -e "$ME/metadata.json" ] && [ ! -L "$ME/metadata.json" ]; then
    echo "$ME isn't Plasma 2000's lock screen; leaving it alone."
    exit 1
fi
rm -rf "$ME"
rm -rf "$HOME/.cache/kscreenlocker_greet/qmlcache"
echo "Removed. The stock Plasma lock screen is back."
