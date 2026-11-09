#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Installs the Windows 2000 style boot screen (Plymouth) and rebuilds the initramfs.
# Run with sudo. Works with initramfs-tools (Debian, Ubuntu, KDE neon), dracut
# (Fedora, openSUSE) and mkinitcpio (Arch).
set -e
[ "$(id -u)" = 0 ] || { echo "Run with sudo: sudo $0"; exit 1; }
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../lib/detect.sh"; . "$HERE/../lib/branding.sh"; . "$HERE/../lib/icons.sh"
THEME=plasma2000
DEST=/usr/share/plymouth/themes/$THEME
CONF=/etc/plymouth/plymouthd.conf
PREV=/etc/plymouth/plasma2000-previous

current_theme() {
    if command -v plymouth-set-default-theme >/dev/null 2>&1; then plymouth-set-default-theme
    else sed -n 's/^Theme=//p' "$CONF" 2>/dev/null; fi
}

# remember what was active, once
if [ ! -f "$PREV" ]; then
    {
        echo "THEME=$(current_theme)"
        # whether plymouthd.conf named a theme itself (uninstall puts back exactly that)
        if grep -q '^Theme=' "$CONF" 2>/dev/null; then
            echo "CONF_THEME=$(sed -n 's/^Theme=//p' "$CONF" | head -n1)"
        else
            echo "CONF_THEME="
        fi
        [ "$P2K_INITRAMFS" = initramfs-tools ] && \
            echo "ALT=$(update-alternatives --query default.plymouth 2>/dev/null | sed -n 's/^Value: //p')"
    } > "$PREV"
fi

# theme files + this computer's name, logo and password icon
rm -rf "$DEST"; mkdir -p "$DEST"
cp "$HERE/$THEME.plymouth" "$HERE/$THEME.script" "$HERE"/*.png "$DEST/"
rm -f "$DEST"/preview*.png
[ -r "$HERE/wordmarks/$P2K_WORDMARK.png" ] || P2K_WORDMARK=generic
# The generic title reads "KDE Plasma": a distribution's release number next to it
# would look like a Plasma version, so only show one the user chose.
[ "$P2K_WORDMARK" = generic ] && [ "$P2K_VERSION_SET" != yes ] && P2K_VERSION=
cp "$HERE/wordmarks/$P2K_WORDMARK.png" "$DEST/wordmark.png"
cp "$HERE/footers/$P2K_WORDMARK.png" "$DEST/footer.png"
# release number: glyph images + their names and positions written into the script
for g in "$HERE"/glyphs/*.png; do cp "$g" "$DEST/glyph-$(basename "$g")"; done
# version_x, version_y, name_end: read as numbers, never run
wm_value() { sed -n "s/^$1=\([0-9][0-9.]*\)\$/\1/p" "$HERE/wordmarks/$P2K_WORDMARK.txt" | head -n1; }
version_x=$(wm_value version_x); version_y=$(wm_value version_y); name_end=$(wm_value name_end)
[ -n "$version_x" ] && [ -n "$version_y" ] && [ -n "$name_end" ] \
    || { echo "wordmarks/$P2K_WORDMARK.txt: missing version_x, version_y or name_end"; exit 1; }
V=$(printf '%s' "$P2K_VERSION" | tr -cd '0-9.')
LINES=""; N=0
while [ -n "$V" ]; do
    c=${V%"${V#?}"}; V=${V#?}
    [ "$c" = . ] && c=dot
    LINES="${LINES}global.version_glyph[$N] = \"$c\";\\n"; N=$((N + 1))
done
sed -i -e "s/^global.version_n = 0;/global.version_n = $N;/" \
       -e "s/^global.version_x = 0;/global.version_x = $version_x;/" \
       -e "s/^global.version_y = 0;/global.version_y = $version_y;/" \
       -e "s/^global.name_end = 0;/global.name_end = $name_end;/" \
       -e "s|^// @P2K_VERSION_GLYPHS@|$LINES|" "$DEST/$THEME.script"
p2k_logo_png 256 "$DEST/logo.png" || echo "  no logo found; the centre tile stays empty"
if src=$(p2k_icon_source dialog-password 32); then
    ok=no
    case "$src" in
        *.svg) p2k_copy_image "$src" "$DEST/icon-password.png" 128 && ok=yes ;;
        *) p2k_copy_image "$src" "$DEST/icon-password-32.png" \
               && python3 -I "$HERE/../lib/pngscale.py" "$DEST/icon-password-32.png" "$DEST/icon-password.png" 4 \
               && ok=yes
           rm -f "$DEST/icon-password-32.png" ;;
    esac
    [ "$ok" = yes ] || echo "  could not make the password icon from $src; the dialog shows none"
fi
chmod -R a+rX "$DEST"

set_conf_theme() {
    mkdir -p /etc/plymouth
    if grep -q '^Theme=' "$CONF" 2>/dev/null; then sed -i "s/^Theme=.*/Theme=$1/" "$CONF"
    else printf '[Daemon]\nTheme=%s\n' "$1" >> "$CONF"; fi
}

echo "Rebuilding the initramfs ($P2K_INITRAMFS), takes a minute..."
case "$P2K_INITRAMFS" in
    initramfs-tools)
        # Debian/Ubuntu: the default.plymouth alternative decides what goes into the initramfs
        update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth "$DEST/$THEME.plymouth" 100
        update-alternatives --set default.plymouth "$DEST/$THEME.plymouth"
        set_conf_theme "$THEME"
        # With disk encryption Plymouth won't draw on the basic boot framebuffer, so the
        # real graphics driver must be in the initramfs or the password prompt stays black.
        GPU=$(for d in /sys/class/drm/card*/device/driver; do basename "$(readlink -f "$d")"; done 2>/dev/null \
              | grep -m1 -E '^(xe|i915|amdgpu|radeon)$' || true)
        # (not nouveau: loaded from the initramfs it would get in the way of NVIDIA's driver)
        if [ -n "$GPU" ] && ! grep -qx "$GPU" /etc/initramfs-tools/modules; then
            echo "$GPU" >> /etc/initramfs-tools/modules
            echo "GPU_ADDED=$GPU" >> "$PREV"   # removed again by uninstall.sh
            echo "Added graphics driver '$GPU' to /etc/initramfs-tools/modules (needed to show the boot screen before the disk is unlocked)."
        fi
        update-initramfs -u ;;
    dracut)
        if command -v plymouth-set-default-theme >/dev/null 2>&1; then plymouth-set-default-theme -R "$THEME"
        else set_conf_theme "$THEME"; dracut -f; fi ;;
    mkinitcpio)
        if command -v plymouth-set-default-theme >/dev/null 2>&1; then plymouth-set-default-theme "$THEME"
        else set_conf_theme "$THEME"; fi
        grep -Eq '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf 2>/dev/null \
            || echo "Note: add 'plymouth' to HOOKS in /etc/mkinitcpio.conf (and 'splash' to the kernel command line), see the Arch wiki."
        mkinitcpio -P ;;
    *)
        set_conf_theme "$THEME"
        echo "Unknown initramfs tool: rebuild your initramfs yourself so the new boot screen is used." ;;
esac
echo "Done ($P2K_NAME${P2K_VERSION:+ $P2K_VERSION}). Reboot to see it."
