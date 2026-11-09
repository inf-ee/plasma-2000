#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Installs the "Plasma 2000" global theme (splash, Shut Down dialog, theme defaults,
# taskbar layout) and applies its defaults. Install colors/, aurorae/ and plasma-style/
# first, and SE98C icons + ModernXP cursors from the KDE Store.
#   ./install.sh            apply colours, title bars, panel style, icons, cursors, splash
#   ./install.sh --layout   also replace your panels with the Windows 2000 taskbar
#                           (removes your current panels and their widgets)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/detect.sh"; . "$HERE/../lib/branding.sh"; . "$HERE/../lib/icons.sh"; . "$HERE/../lib/settings.sh"
p2k_not_root
ID=io.github.inf_ee.plasma2000
DEST="$HOME/.local/share/plasma/look-and-feel/$ID"

rm -rf "$DEST"; mkdir -p "$(dirname "$DEST")"
cp -r "$HERE/$ID" "$DEST"
# the decoration engine name differs between Plasma versions
sed -i "s/^library=.*/library=$P2K_AURORAE/" "$DEST/contents/defaults"
p2k_write_branding "$DEST/contents/splash"
p2k_write_branding "$DEST/contents/logout"
p2k_install_icon system-shutdown 48 "$DEST/contents/logout/icons/system-shutdown-48.png"
rm -rf "$HOME/.cache/ksmserver-logout-greeter/qmlcache" "$HOME/.cache/ksplashqml/qmlcache"

CUR=$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage)
[ "$CUR" = "$ID" ] || p2k_remember lookandfeel "$CUR"
if [ "$1" = --layout ]; then
    plasma-apply-lookandfeel --apply "$ID" --resetLayout
else
    plasma-apply-lookandfeel --apply "$ID"
fi
# Plasma 6 writes the theme's choices to kdedefaults only; some apps (Double Commander 1.1)
# read the style and icon theme only from kdeglobals itself, so set them there too
p2k_set kdeglobals KDE widgetStyle Windows
ICONS=$(sed -n '/^\[Icons\]/,/^\[/s/^Theme=//p' "${XDG_CONFIG_HOME:-$HOME/.config}/kdedefaults/kdeglobals" 2>/dev/null | head -n1)
[ -n "$ICONS" ] && p2k_set kdeglobals Icons Theme "$ICONS"
echo "Applied Plasma 2000 ($P2K_NAME)."
