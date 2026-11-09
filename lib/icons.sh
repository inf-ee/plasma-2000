# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Sourced after detect.sh and branding.sh. The login, lock and shut down screens show a few
# classic icons. They are not shipped with Plasma 2000: they are copied from
# the SE98C icon theme installed on this computer (KDE Store 2330873), or from
# Breeze if SE98C is missing.
#
#   p2k_install_icon NAME SIZE DESTFILE   e.g. p2k_install_icon system-shutdown 48 dir/system-shutdown-48.png

p2k_icon_source() { # NAME SIZE -> path of the best match, SE98C first
    for t in "$P2K_HOME/.local/share/icons/SE98C" "$P2K_HOME/.icons/SE98C" /usr/share/icons/SE98C; do
        for c in actions status apps places devices; do
            if [ -r "$t/$c/$2/$1.png" ]; then echo "$t/$c/$2/$1.png"; return 0; fi
        done
    done
    for t in /usr/share/icons/breeze /usr/share/icons/breeze-dark; do
        for c in actions status apps places devices; do
            for d in "$2" 48 32 22; do
                if [ -r "$t/$c/$d/$1.svg" ]; then echo "$t/$c/$d/$1.svg"; return 0; fi
            done
        done
    done
    return 1
}

p2k_install_icon() {
    src=$(p2k_icon_source "$1" "$2") || { echo "  icon $1: not found (SE98C or Breeze), skipped"; return 0; }
    mkdir -p "$(dirname "$3")"
    p2k_copy_image "$src" "$3" "$2" || { echo "  icon $1: could not read $src, skipped"; return 0; }
    chmod a+r "$3"
    case "$src" in */SE98C/*) ;; *) echo "  icon $1: SE98C not installed, using $(basename "$(dirname "$(dirname "$(dirname "$src")")")")" ;; esac
}
