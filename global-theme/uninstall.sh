#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Switches back to the global theme you had before (its colours, icons, cursors, splash
# and title bars) and removes Plasma 2000's. Panels are kept as they are.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/settings.sh"
p2k_not_root
PREV=$(p2k_recall lookandfeel) || PREV=org.kde.breeze.desktop
plasma-apply-lookandfeel --apply "$PREV" || { PREV=org.kde.breeze.desktop; plasma-apply-lookandfeel --apply "$PREV"; }
p2k_restore kdeglobals KDE widgetStyle
p2k_restore kdeglobals Icons Theme
# still ours: let the global theme decide again
[ "$(kreadconfig6 --file kdeglobals --group KDE --key widgetStyle)" = Windows ] \
    && kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle --delete
rm -rf "$HOME/.local/share/plasma/look-and-feel/io.github.inf_ee.plasma2000"
echo "Removed. Global theme: $PREV"
