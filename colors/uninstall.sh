#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Switches back to the colour scheme you had before and removes the Windows 2000 one.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/settings.sh"
p2k_not_root
PREV=$(p2k_recall colorscheme) || PREV=BreezeLight
plasma-apply-colorscheme "$PREV" || { PREV=BreezeLight; plasma-apply-colorscheme "$PREV"; }
rm -f "$HOME/.local/share/color-schemes/Windows2000.colors"
echo "Removed. Colour scheme: $PREV"
