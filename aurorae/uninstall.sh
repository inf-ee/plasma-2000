#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Switches back to the window decoration you had before and removes the Windows 2000 one.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/detect.sh"; . "$HERE/../lib/settings.sh"
p2k_not_root
p2k_restore kwinrc org.kde.kdecoration2 library
p2k_restore kwinrc org.kde.kdecoration2 theme
# still ours (e.g. set by the global theme): back to Plasma's default, Breeze
if [ "$(kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme)" = __aurorae__svg__windows2000-aurorae ]; then
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library --delete
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme --delete
fi
rm -rf "$HOME/.local/share/aurorae/themes/windows2000-aurorae"
$P2K_QDBUS org.kde.KWin /KWin reconfigure 2>/dev/null || true
echo "Removed."
