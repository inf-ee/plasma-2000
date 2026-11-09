#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Restores the previous boot screen and rebuilds the initramfs. Run with sudo.
set -e
[ "$(id -u)" = 0 ] || { echo "Run with sudo: sudo $0"; exit 1; }
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/detect.sh"
PREV=/etc/plymouth/plasma2000-previous
DEST=/usr/share/plymouth/themes/plasma2000
CONF=/etc/plymouth/plymouthd.conf
# written by install.sh: THEME, ALT (Debian/Ubuntu), CONF_THEME, GPU_ADDED
THEME=bgrt; ALT=; GPU_ADDED=
[ -f "$PREV" ] && . "$PREV"
[ -n "$THEME" ] && [ "$THEME" != plasma2000 ] || THEME=bgrt

# plymouthd.conf as it was: its own theme line, or none (unknown for older installs)
restore_conf() {
    [ -f "$CONF" ] || return 0
    if [ "${CONF_THEME-unknown}" = unknown ]; then sed -i "s/^Theme=.*/Theme=$THEME/" "$CONF"
    elif [ -n "$CONF_THEME" ] && [ "$CONF_THEME" != plasma2000 ]; then sed -i "s/^Theme=.*/Theme=$CONF_THEME/" "$CONF"
    else sed -i '/^Theme=/d' "$CONF"; fi
}

# switch first, then delete: the theme files must not vanish while still selected
case "$P2K_INITRAMFS" in
    initramfs-tools)
        [ -n "$ALT" ] && update-alternatives --set default.plymouth "$ALT" || true
        update-alternatives --remove default.plymouth "$DEST/plasma2000.plymouth" || true
        restore_conf
        rm -rf "$DEST"
        case "$GPU_ADDED" in
            xe | i915 | amdgpu | radeon | nouveau) sed -i "/^$GPU_ADDED\$/d" /etc/initramfs-tools/modules ;;
        esac
        update-initramfs -u ;;
    dracut)
        if command -v plymouth-set-default-theme >/dev/null 2>&1; then plymouth-set-default-theme "$THEME"
        else restore_conf; fi
        rm -rf "$DEST"
        dracut -f ;;
    mkinitcpio)
        if command -v plymouth-set-default-theme >/dev/null 2>&1; then plymouth-set-default-theme "$THEME"
        else restore_conf; fi
        rm -rf "$DEST"
        mkinitcpio -P ;;
    *)
        restore_conf
        rm -rf "$DEST"
        echo "Rebuild your initramfs yourself." ;;
esac
rm -f "$PREV"
echo "Restored boot screen: $THEME"
