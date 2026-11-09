#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Installs the "Plasma 2000" panel style (React Plus fork without the blue
# "popup open" strip under panel buttons) and makes it active.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/settings.sh"
p2k_not_root
CUR=$(kreadconfig6 --file plasmarc --group Theme --key name --default default)
[ "$CUR" = plasma2000 ] || p2k_remember desktoptheme "$CUR"
DEST="$HOME/.local/share/plasma/desktoptheme/plasma2000"
rm -rf "$DEST"; mkdir -p "$(dirname "$DEST")"
cp -r "$HERE/plasma2000" "$DEST"
rm -rf "$HOME"/.cache/plasma_theme_plasma2000* "$HOME"/.cache/plasma-svgelements-plasma2000* 2>/dev/null || true
plasma-apply-desktoptheme plasma2000
