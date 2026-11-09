# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Sourced after detect.sh: works out the distribution name and logo shown in
# the banners ("Log On to <name>", boot screen). Nothing is shipped: the logo
# comes from the system. Run directly to print the result.
#
# Override any value in ~/.config/plasma2000/branding.conf:
#     name=My Distro
#     version=26.04                 (empty: no version)
#     logo=/path/to/logo.png        (PNG or SVG)
#     wordmark=generic              (boot screen title image, see plymouth/wordmarks/)
# then re-run the installers.

command -v p2k_os_release >/dev/null 2>&1 || . "$(dirname "$0")/detect.sh"

P2K_NAME=$(p2k_os_release NAME)
P2K_WORDMARK=generic
P2K_LOGO=
# release number shown after the name, e.g. 26.04; rolling releases have none
P2K_VERSION=$(p2k_os_release VERSION_ID)
P2K_VERSION_SET=
case "$P2K_OS_ID" in
    arch | endeavouros | cachyos | manjaro | opensuse-tumbleweed | opensuse-slowroll) P2K_VERSION= ;;
esac
case "$P2K_VERSION" in [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]*) P2K_VERSION= ;; esac  # a date
_logo_name=$(p2k_os_release LOGO)

case "$P2K_OS_ID" in
    ubuntu)
        # Ubuntu flavours share Ubuntu's os-release; recognise Kubuntu by its package or logo
        if [ -e /usr/share/pixmaps/kubuntu-logo.png ] \
           || dpkg-query -W -f='${Status}' kubuntu-desktop 2>/dev/null | grep -q "ok installed"; then
            P2K_NAME=Kubuntu; P2K_WORDMARK=kubuntu; _logo_name=kubuntu-logo
        fi ;;
    neon) P2K_NAME="KDE neon"; P2K_WORDMARK=neon ;;
    debian) P2K_NAME=Debian; P2K_WORDMARK=debian ;;
    fedora) P2K_NAME=Fedora; P2K_WORDMARK=fedora ;;
    arch) P2K_NAME="Arch Linux"; P2K_WORDMARK=arch ;;
    opensuse*) P2K_NAME=openSUSE; P2K_WORDMARK=opensuse ;;
esac
[ -n "$P2K_NAME" ] || P2K_NAME="KDE Plasma"

# logo: os-release's LOGO icon name, looked up like an icon theme would
p2k_find_logo() {
    [ -n "$1" ] || return 1
    for f in /usr/share/pixmaps/"$1".png /usr/share/pixmaps/"$1".svg \
             /usr/share/icons/hicolor/512x512/apps/"$1".png /usr/share/icons/hicolor/256x256/apps/"$1".png \
             /usr/share/icons/hicolor/scalable/apps/"$1".svg /usr/share/icons/hicolor/128x128/apps/"$1".png \
             /usr/share/icons/hicolor/96x96/apps/"$1".png /usr/share/icons/hicolor/64x64/apps/"$1".png; do
        if [ -r "$f" ]; then echo "$f"; return 0; fi
    done
    return 1
}
P2K_LOGO=$(p2k_find_logo "$_logo_name" || p2k_find_logo distributor-logo || true)
# fallback: the Plasma logo from the Breeze icons (start-here-kde)
if [ -z "$P2K_LOGO" ]; then
    for f in /usr/share/icons/breeze/places/96/start-here-kde.svg /usr/share/icons/breeze-dark/places/96/start-here-kde.svg; do
        if [ -r "$f" ]; then P2K_LOGO=$f; break; fi
    done
fi
unset _logo_name

# user overrides
P2K_BRANDING_CONF="$P2K_HOME/.config/plasma2000/branding.conf"
if [ -r "$P2K_BRANDING_CONF" ]; then
    _v=$(sed -n 's/^name=//p' "$P2K_BRANDING_CONF" | head -n1); [ -n "$_v" ] && P2K_NAME=$_v
    _v=$(sed -n 's/^logo=//p' "$P2K_BRANDING_CONF" | head -n1); [ -n "$_v" ] && P2K_LOGO=$_v
    _v=$(sed -n 's/^wordmark=//p' "$P2K_BRANDING_CONF" | head -n1); [ -n "$_v" ] && P2K_WORDMARK=$_v
    if grep -q '^version=' "$P2K_BRANDING_CONF"; then
        P2K_VERSION=$(sed -n 's/^version=//p' "$P2K_BRANDING_CONF" | head -n1)
        P2K_VERSION_SET=yes   # chosen by the user: shown even next to the generic title
    fi
    unset _v
fi
# the wordmark names a file in plymouth/wordmarks/, so only plain names are allowed
case "$P2K_WORDMARK" in
    "" | *[!a-z0-9-]*)
        echo "branding.conf: wordmark must be a name from plymouth/wordmarks/; using generic" >&2
        P2K_WORDMARK=generic ;;
esac

# p2k_copy_image SRC DEST [SIZE]: copy a PNG to DEST, or render an SVG at SIZExSIZE.
# Under sudo the source is read with the user's rights: logo= and the SE98C icons
# come from the user's settings and home, and must not expose files only root can read.
# Fails (DEST not written) if SRC can't be read or isn't a PNG or SVG.
p2k_copy_image() {
    _dir=$(mktemp -d) || return 1
    _rc=1; _svg=
    if [ "$(id -u)" = 0 ] && [ "$P2K_USER" != root ]; then
        if runuser -u "$P2K_USER" -- cat -- "$1" > "$_dir/img" 2>/dev/null; then _rc=0; fi
    elif cat -- "$1" > "$_dir/img" 2>/dev/null; then _rc=0
    fi
    if [ "$_rc" = 0 ]; then
        _rc=1
        case "$(head -c 8 "$_dir/img" | od -An -tx1 | tr -d ' \n')" in
            89504e470d0a1a0a) cp "$_dir/img" "$2" && _rc=0 ;;
            1f8b*) mv "$_dir/img" "$_dir/img.svgz" && _svg="$_dir/img.svgz" ;;
            *) grep -aq '<svg' "$_dir/img" && mv "$_dir/img" "$_dir/img.svg" && _svg="$_dir/img.svg" ;;
        esac
        # offscreen: under sudo there is no display, and ksvgtopng aborts without one
        [ -n "$_svg" ] && QT_QPA_PLATFORM=offscreen ksvgtopng "${3:-256}" "${3:-256}" "$_svg" "$2" >/dev/null 2>&1 \
            && [ -s "$2" ] && _rc=0
    fi
    rm -rf "$_dir"
    unset _dir _svg
    return "$_rc"
}

# p2k_logo_png SIZE OUT: the logo as a SIZExSIZE-or-smaller PNG (Plymouth can't read SVG)
p2k_logo_png() {
    [ -n "$P2K_LOGO" ] || return 1
    p2k_copy_image "$P2K_LOGO" "$2" "$1"
}

if [ "${0##*/}" = branding.sh ]; then
    printf '%-14s %s\n' P2K_NAME "$P2K_NAME" P2K_VERSION "$P2K_VERSION" P2K_WORDMARK "$P2K_WORDMARK" P2K_LOGO "$P2K_LOGO" \
        P2K_BRANDING_CONF "$P2K_BRANDING_CONF"
fi

# p2k_write_branding DIR: write DIR/branding.js (name) and DIR/logo.png for an installed screen,
# so the screen needs nothing outside its own folder (SDDM can't read home folders).
p2k_write_branding() {
    _name=$(printf '%s' "$P2K_NAME" | sed 's/\\/\\\\/g; s/"/\\"/g')
    _logo=
    if p2k_logo_png 256 "$1/logo.png"; then chmod a+r "$1/logo.png"; _logo=logo.png; fi
    cat > "$1/branding.js" <<JS
// Written by Plasma 2000's installer (lib/branding.sh); re-run it to update.
.pragma library
var name = "$_name";
var version = "$(printf '%s' "$P2K_VERSION" | sed 's/[^A-Za-z0-9. -]//g')";
var logo = "$_logo";
JS
    chmod a+r "$1/branding.js"
    unset _name _logo
}
