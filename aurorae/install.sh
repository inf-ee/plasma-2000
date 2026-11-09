#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Installs the Windows 2000 window decoration (Aurorae) and makes it active.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/detect.sh"; . "$HERE/../lib/settings.sh"
p2k_not_root
DEST="$HOME/.local/share/aurorae/themes/windows2000-aurorae"
rm -rf "$DEST"; mkdir -p "$(dirname "$DEST")"
cp -r "$HERE/windows2000-aurorae" "$DEST"
p2k_set kwinrc org.kde.kdecoration2 library "$P2K_AURORAE"
p2k_set kwinrc org.kde.kdecoration2 theme __aurorae__svg__windows2000-aurorae
$P2K_QDBUS org.kde.KWin /KWin reconfigure 2>/dev/null || true
echo "Installed. If an older copy was active, switch to another decoration and back to reload it."
