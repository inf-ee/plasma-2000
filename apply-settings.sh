#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Windows-like behaviour that no theme can set: Win+D minimizes all windows, Minimize All
# button instead of Peek at Desktop, task buttons react at once, no launch feedback
# bouncing, no wobbly windows/translucency, clock without date, Win2000 desktop colour,
# and the Plasma 2000 Start button / tray box on your existing panel if they're installed.
# Run inside your Plasma session (not with sudo). Safe to run again.
#   ./apply-settings.sh --revert   put these settings back (Win+D, wallpaper, clock and
#                                  task buttons go back to Plasma's defaults)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/lib/detect.sh"; . "$HERE/lib/settings.sh"
p2k_not_root
pgrep -u "$(id -u)" -x plasmashell >/dev/null || { echo "Plasma isn't running; run this inside your Plasma session."; exit 1; }
[ -n "$P2K_QDBUS" ] || { echo "qdbus not found (package qt6-tools / qdbus-qt6)."; exit 1; }
Q=$P2K_QDBUS
META=268435456; SHIFT=33554432; KEY_D=68
RC="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

# JavaScript for plasmashell: replace widget $1 with $2 in the same place on every panel.
# Prints "ORDER <panel> <order>" lines to be written while plasmashell is stopped
# (it rewrites the widget order when it exits).
swap_widget_js() {
    cat <<JS
    var old = p.widgets("$1");
    if (old.length && !p.widgets("$2").length) {
        p.currentConfigGroup = ["General"];
        var order = p.readConfig("AppletOrder", "").toString().split(";").filter(function (x) { return x != ""; });
        var w = p.addWidget("$2");
        var oldId = String(old[0].id);
        old[0].remove();
        if (order.length) {
            order = order.map(function (x) { return x == oldId ? String(w.id) : x; });
            out.push("ORDER " + p.id + " " + order.join(";"));
        }
        out.push("$1 -> $2");
    }
JS
}
js_str() { printf '%s' "$1" | sed 's/[\\"]/\\&/g'; }  # for a "..." JavaScript string
write_orders() { # OUT from the script above; plasmashell must be stopped
    echo "$1" | while read -r tag cid order; do
        [ "$tag" = ORDER ] || continue
        kwriteconfig6 --file "$RC" --group Containments --group "$cid" --group General --key AppletOrder "$order"
    done
}

if [ "$1" = --revert ]; then
    echo "== Restoring the settings this script changed"
    p2k_restore kdeglobals KDE widgetStyle
    for k in startupfeedbackEnabled wobblywindowsEnabled translucencyEnabled minimizeallEnabled; do
        p2k_restore kwinrc Plugins "$k"
    done
    p2k_restore klaunchrc FeedbackStyle BusyCursor
    p2k_restore klaunchrc FeedbackStyle TaskbarButton
    p2k_restore klaunchrc BusyCursorSettings Bouncing
    $Q org.kde.KWin /KWin reconfigure
    echo "== Win+D: Peek at Desktop (Plasma's default)"
    dbus-send --session --print-reply=literal --dest=org.kde.kglobalaccel /kglobalaccel \
        org.kde.KGlobalAccel.setForeignShortcut \
        array:string:"kwin","MinimizeAll","KWin","Minimize all windows" array:int32: >/dev/null
    dbus-send --session --print-reply=literal --dest=org.kde.kglobalaccel /kglobalaccel \
        org.kde.KGlobalAccel.setForeignShortcut \
        array:string:"kwin","Show Desktop","KWin","Peek at Desktop" array:int32:$((META + KEY_D)) >/dev/null
    echo "== Panel and desktop: your wallpaper, Plasma's default clock and task buttons"
    WP=$(p2k_recall wallpaper) || WP="org.kde.image "
    WP_PLUGIN=$(js_str "${WP%% *}"); WP_IMAGE=$(js_str "${WP#* }")
    OUT=$($Q org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(
        cat <<JS
var out = [];
desktops().forEach(function (d) {
    d.wallpaperPlugin = "$WP_PLUGIN";
    if ("$WP_IMAGE" != "") {
        d.currentConfigGroup = ["Wallpaper", "$WP_PLUGIN", "General"];
        d.writeConfig("Image", "$WP_IMAGE");
    }
});
out.push("wallpaper: $WP_PLUGIN $WP_IMAGE");
panels().forEach(function (p) {
    p.widgets().forEach(function (w) {
        if (w.type == "org.kde.plasma.taskmanager" || w.type == "org.kde.plasma.icontasks") {
            w.currentConfigGroup = ["General"];
            w.writeConfig("taskHoverEffect", true);
        }
        if (w.type == "org.kde.plasma.digitalclock") {
            w.currentConfigGroup = ["Appearance"];
            w.writeConfig("showDate", true);
        }
    });
JS
        swap_widget_js org.kde.plasma.minimizeall org.kde.plasma.showdesktop
        printf '%s\n' '}); print(out.join("\n"));'
    )")
    echo "$OUT" | grep -v '^ORDER ' || true
    if echo "$OUT" | grep -q '^ORDER '; then
        systemctl --user stop plasma-plasmashell.service
        write_orders "$OUT"
        systemctl --user start plasma-plasmashell.service
    fi
    echo "Done. Log out and back in once so every app picks up the old style."
    exit 0
fi

echo "== Application style: Windows"
# plasma-apply-lookandfeel only writes kdedefaults; the main file wins
p2k_set kdeglobals KDE widgetStyle Windows

echo "== KWin: no launch feedback, wobbly windows or translucency; MinimizeAll script on"
p2k_set kwinrc Plugins startupfeedbackEnabled false
p2k_set kwinrc Plugins wobblywindowsEnabled false
p2k_set kwinrc Plugins translucencyEnabled false
p2k_set kwinrc Plugins minimizeallEnabled true
p2k_set klaunchrc FeedbackStyle BusyCursor false
p2k_set klaunchrc FeedbackStyle TaskbarButton false
p2k_set klaunchrc BusyCursorSettings Bouncing false
$Q org.kde.KWin /KWin reconfigure
$Q org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect startupfeedback >/dev/null 2>&1 || true

echo "== Win+D: minimize all windows (instead of Peek at Desktop)"
# Set through kglobalaccel (it runs inside KWin on Wayland; editing the file needs a relogin).
dbus-send --session --print-reply=literal --dest=org.kde.kglobalaccel /kglobalaccel \
    org.kde.KGlobalAccel.setForeignShortcut \
    array:string:"kwin","Show Desktop","KWin","Peek at Desktop" array:int32: >/dev/null
dbus-send --session --print-reply=literal --dest=org.kde.kglobalaccel /kglobalaccel \
    org.kde.KGlobalAccel.setForeignShortcut \
    array:string:"kwin","MinimizeAll","KWin","Minimize all windows" \
    array:int32:$((META + KEY_D)),$((META + SHIFT + KEY_D)) >/dev/null

echo "== Panel and desktop"
OUT=$($Q org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(
    cat <<'JS'
var out = [];
var d0 = desktops()[0];
if (d0) {  // remembered for --revert
    d0.currentConfigGroup = ["Wallpaper", d0.wallpaperPlugin, "General"];
    out.push("WALLPAPER " + d0.wallpaperPlugin + " " + d0.readConfig("Image", ""));
}
desktops().forEach(function (d) {
    d.wallpaperPlugin = "org.kde.color";
    d.currentConfigGroup = ["Wallpaper", "org.kde.color", "General"];
    d.writeConfig("Color", "#3a6ea5");
});
out.push("wallpaper #3a6ea5");
panels().forEach(function (p) {
    p.widgets().forEach(function (w) {
        if (w.type == "org.kde.plasma.taskmanager" || w.type == "org.kde.plasma.icontasks") {
            w.currentConfigGroup = ["General"];
            w.writeConfig("taskHoverEffect", false);
            out.push("task manager: hover highlight off");
        }
        if (w.type == "org.kde.plasma.digitalclock") {
            w.currentConfigGroup = ["Appearance"];
            w.writeConfig("showDate", false);
            out.push("clock: no date");
        }
    });
    // Show Desktop (peek) -> Minimize All Windows, same position
JS
    swap_widget_js org.kde.plasma.showdesktop org.kde.plasma.minimizeall
    printf '%s\n' '}); print(out.join("\n"));'
)")
WP=$(echo "$OUT" | sed -n 's/^WALLPAPER //p')
case "$WP" in org.kde.color*) ;; *) p2k_remember wallpaper "$WP" ;; esac
OUT=$(echo "$OUT" | grep -v '^WALLPAPER ' || true)
echo "$OUT" | grep -v '^ORDER ' || true

START=io.github.inf_ee.plasma2000.start
STARTBTN=no
if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx "$START" \
   && grep -Eq '^plugin=org.kde.plasma.kickoff$' "$RC"; then
    STARTBTN=yes
fi

echo "== Restarting the panel to apply widget changes"
systemctl --user stop plasma-plasmashell.service
write_orders "$OUT"
if [ "$STARTBTN" = yes ]; then
    # swap Kickoff for the Plasma 2000 Start button (same as start-button/use.sh)
    sed -i -E "s/^plugin=org.kde.plasma.kickoff$/plugin=$START/" "$RC"
    echo "Start menu: Plasma 2000 Start button"
fi
systemctl --user start plasma-plasmashell.service
kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx "$START" \
    || echo "Note: Start button not built yet; run start-button/build.sh, then this script again"
kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx io.github.inf_ee.plasma2000.trayframe \
    || echo "Note: sunken tray box not installed; run tray-frame/install.sh"

echo "Done. Log out and back in once so every app picks up the new style."
