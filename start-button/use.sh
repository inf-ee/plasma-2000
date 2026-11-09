#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Swaps the panel's Kickoff for the Plasma 2000 Start menu (or back with --revert),
# keeping the same widget id, position, settings and favourites. Restarts plasmashell.
set -e
NEW=io.github.inf_ee.plasma2000.start
RC="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
if [ "$1" = "--revert" ]; then FROM=$NEW; TO=org.kde.plasma.kickoff
else
    FROM=org.kde.plasma.kickoff; TO=$NEW
    # without the package the panel would show an error instead of a Start menu
    kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx "$NEW" \
        || { echo "The Plasma 2000 Start menu isn't installed yet; run $(dirname "$0")/build.sh first."; exit 1; }
fi
grep -Eq "^plugin=($FROM)$" "$RC" || { echo "Nothing to swap: no $FROM widget on the panel."; exit 0; }
systemctl --user stop plasma-plasmashell.service
# bring the desktop back even if the edit fails
trap 'systemctl --user start plasma-plasmashell.service' EXIT
sed -i -E "s/^plugin=($FROM)$/plugin=$TO/" "$RC"
trap - EXIT
systemctl --user start plasma-plasmashell.service
echo "Panel now uses $TO."
