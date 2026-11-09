#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Switches back to the panel style you had before and removes the Plasma 2000 one.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/settings.sh"
p2k_not_root
PREV=$(p2k_recall desktoptheme) || PREV=default
plasma-apply-desktoptheme "$PREV" || { PREV=default; plasma-apply-desktoptheme default; }
rm -rf "$HOME/.local/share/plasma/desktoptheme/plasma2000"
echo "Removed. Panel style: $PREV"
