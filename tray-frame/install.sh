#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Installs the Windows 2000 style sunken box around the system tray and clock,
# and puts it on the panel directly left of the system tray.
# (Plasma rewrites the widget order when it exits, so the order is written
# while plasmashell is stopped.)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/detect.sh"; . "$HERE/../lib/settings.sh"
p2k_not_root
ID=io.github.inf_ee.plasma2000.trayframe
RC="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx "$ID"; then
    kpackagetool6 -t Plasma/Applet -u "$HERE/package" >/dev/null
else
    kpackagetool6 -t Plasma/Applet -i "$HERE/package" >/dev/null
fi
# add it to every panel with a system tray (if missing) and work out the new order
OUT=$($P2K_QDBUS org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
panels().forEach(function (p) {
    var tray = p.widgets("org.kde.plasma.systemtray");
    if (!tray.length) return;
    p.currentConfigGroup = ["General"];
    var order = p.readConfig("AppletOrder", "").toString().split(";").filter(function (x) { return x != ""; });
    var have = p.widgets("'"$ID"'");
    var w = have.length ? have[0] : p.addWidget("'"$ID"'");
    order = order.filter(function (x) { return x != String(w.id); });
    var i = order.indexOf(String(tray[0].id));
    if (i < 0) return;
    order.splice(i, 0, String(w.id));
    print("ORDER " + p.id + " " + order.join(";") + "\n");
});')
systemctl --user stop plasma-plasmashell.service
echo "$OUT" | while read -r tag cid order; do
    [ "$tag" = ORDER ] || continue
    kwriteconfig6 --file "$RC" --group Containments --group "$cid" --group General --key AppletOrder "$order"
done
rm -rf "$HOME/.cache/plasmashell/qmlcache"
systemctl --user start plasma-plasmashell.service
echo "Installed. The sunken box is left of the system tray."
