#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Installs and applies the Windows 2000 colour scheme.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/settings.sh"
p2k_not_root
CUR=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)
[ "$CUR" = Windows2000 ] || p2k_remember colorscheme "$CUR"
mkdir -p "$HOME/.local/share/color-schemes"
cp "$HERE/Windows2000.colors" "$HOME/.local/share/color-schemes/"
plasma-apply-colorscheme Windows2000
