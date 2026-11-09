# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Sourced by the installers: works out where things are on this distro.
# Sets P2K_* variables only; changes nothing. Run directly to print them.

# value of a key from /etc/os-release (empty if missing)
# (P2K_OS_RELEASE can point to another file, for testing)
p2k_os_release() {
    _f=${P2K_OS_RELEASE:-/etc/os-release}
    [ -r "$_f" ] || return 0
    sed -n "s/^$1=//p" "$_f" | head -n1 | sed 's/^"//; s/"$//'
}

P2K_OS_ID=$(p2k_os_release ID)
P2K_OS_LIKE=$(p2k_os_release ID_LIKE)

# distro family: decides how the boot screen is installed and a few paths
case " $P2K_OS_ID $P2K_OS_LIKE " in
    *" debian "* | *" ubuntu "*) P2K_FAMILY=debian ;;
    *" fedora "* | *" rhel "*) P2K_FAMILY=fedora ;;
    *" arch "*) P2K_FAMILY=arch ;;
    *suse*) P2K_FAMILY=suse ;;
    *) P2K_FAMILY=unknown ;;
esac

# the user the theme is for, also when an installer runs under sudo
P2K_USER=${SUDO_USER:-$(id -un)}
P2K_HOME=$(getent passwd "$P2K_USER" | cut -d: -f6)
[ -n "$P2K_HOME" ] || P2K_HOME=$HOME

# Plasma version, major.minor (e.g. 6.6)
P2K_PLASMA=$(plasmashell --version 2>/dev/null | awk '{print $2}' | cut -d. -f1,2)

# folder with Plasma's helper programs (Debian/Ubuntu: multiarch path; others: /usr/libexec)
P2K_LIBEXEC=
for d in /usr/lib/*/libexec /usr/libexec /usr/lib/libexec; do
    if [ -x "$d/kscreenlocker_greet" ]; then P2K_LIBEXEC=$d; break; fi
done

# qdbus is called qdbus6, qdbus-qt6 (Fedora) or plain qdbus
P2K_QDBUS=
for c in qdbus6 qdbus-qt6 qdbus; do
    if command -v "$c" >/dev/null 2>&1; then P2K_QDBUS=$c; break; fi
done

# how the initramfs (early boot image with the boot screen) is rebuilt
if command -v update-initramfs >/dev/null 2>&1; then P2K_INITRAMFS=initramfs-tools
elif command -v dracut >/dev/null 2>&1; then P2K_INITRAMFS=dracut
elif command -v mkinitcpio >/dev/null 2>&1; then P2K_INITRAMFS=mkinitcpio
else P2K_INITRAMFS=unknown
fi

# window decoration engine: Plasma 6.6+ ships "aurorae.v2" next to the old one
P2K_AURORAE=org.kde.kwin.aurorae
for d in /usr/lib/*/qt6/plugins /usr/lib64/qt6/plugins /usr/lib/qt6/plugins; do
    if ls "$d"/org.kde.kdecoration*/org.kde.kwin.aurorae.v2.so >/dev/null 2>&1; then
        P2K_AURORAE=org.kde.kwin.aurorae.v2; break
    fi
done

if [ "${0##*/}" = detect.sh ]; then
    for v in P2K_OS_ID P2K_OS_LIKE P2K_FAMILY P2K_USER P2K_HOME P2K_PLASMA P2K_LIBEXEC P2K_QDBUS P2K_INITRAMFS P2K_AURORAE; do
        eval "printf '%-14s %s\n' $v \"\$$v\""
    done
fi
