#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Removes the tray box widget from all panels and uninstalls it.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/detect.sh"; . "$HERE/../lib/settings.sh"
p2k_not_root
# the widget must come off the panels first, or they keep a broken placeholder
pgrep -u "$(id -u)" -x plasmashell >/dev/null || { echo "Plasma isn't running; run this inside your Plasma session."; exit 1; }
ID=io.github.inf_ee.plasma2000.trayframe
$P2K_QDBUS org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
panels().forEach(function (p) { p.widgets("'"$ID"'").forEach(function (w) { w.remove(); }); });' >/dev/null
kpackagetool6 -t Plasma/Applet -r "$ID" >/dev/null 2>&1 || true
echo "Removed."
