#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Puts stock Kickoff back on the panel and removes the Plasma 2000 Start menu.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ID=io.github.inf_ee.plasma2000.start
"$HERE/use.sh" --revert
if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx "$ID"; then
    kpackagetool6 -t Plasma/Applet -r "$ID" >/dev/null
fi
rm -rf "$HERE/build" "$HOME/.cache/plasmashell/qmlcache"
echo "Removed."
