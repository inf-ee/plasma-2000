# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Sourced by the user-level installers. Remembers the settings Plasma 2000 changes,
# the first time it changes them, so the uninstallers can put them back.
#
#   p2k_set FILE GROUP KEY VALUE     write it into the user's FILE, noting the value it replaces
#   p2k_restore FILE GROUP KEY       put that value back (or remove the key if it was unset)
#   p2k_remember NAME VALUE          note a value under a name (e.g. the active colour scheme)
#   p2k_recall NAME                  print it; fails if nothing was noted

P2K_STATE="${XDG_DATA_HOME:-$HOME/.local/share}/plasma2000/previous-settings"
P2K_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

# value of KEY in GROUP of the user's own FILE (not system defaults); fails if not set there
p2k_ini_get() {
    [ -r "$P2K_CONFIG_DIR/$1" ] || return 1
    awk -v g="[$2]" -v k="$3" '
        /^\[/ { ing = ($0 == g); next }
        ing && index($0, k "=") == 1 { print substr($0, length(k) + 2); found = 1; exit }
        END { exit !found }' "$P2K_CONFIG_DIR/$1"
}

# write KEY=VALUE into GROUP of the user's FILE directly (adds the group/key if missing)
_p2k_ini_put() {
    _f="$P2K_CONFIG_DIR/$1"
    mkdir -p "$P2K_CONFIG_DIR"; [ -f "$_f" ] || : > "$_f"
    awk -v g="[$2]" -v k="$3" -v v="$4" '
        BEGIN { ing = 0; done = 0 }
        /^\[/ { if (ing && !done) { print k "=" v; done = 1 } ing = ($0 == g) }
        ing && index($0, k "=") == 1 { if (!done) { print k "=" v; done = 1 } next }
        { print }
        END { if (!done) { if (!ing) print "\n" g; print k "=" v } }' "$_f" > "$_f.p2k" && mv "$_f.p2k" "$_f"
    unset _f
}

# the state file has one tab-separated line per setting: ID <tab> set|unset <tab> value
_p2k_noted() { [ -r "$P2K_STATE" ] && grep -qF -- "$1	" "$P2K_STATE"; }
_p2k_note() {
    _p2k_noted "$1" && return 0
    mkdir -p "$(dirname "$P2K_STATE")"
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$P2K_STATE"
}
_p2k_take() { # ID -> prints "set|unset<tab>value" and forgets it
    _p2k_noted "$1" || return 1
    grep -F -- "$1	" "$P2K_STATE" | head -n1 | cut -f2-
    grep -vF -- "$1	" "$P2K_STATE" > "$P2K_STATE.new" || true
    mv "$P2K_STATE.new" "$P2K_STATE"
}

p2k_set() {
    _id="$1/$2/$3"
    # (already our value: set by a run before settings were remembered; nothing to note)
    if _old=$(p2k_ini_get "$1" "$2" "$3"); then [ "$_old" = "$4" ] || _p2k_note "$_id" set "$_old"
    else _p2k_note "$_id" unset ""; fi
    kwriteconfig6 --file "$1" --group "$2" --key "$3" "$4"
    # kwriteconfig6 skips values equal to a global theme's default (~/.config/kdedefaults),
    # but some apps (e.g. Double Commander 1.1) read only the user's file
    [ "$(p2k_ini_get "$1" "$2" "$3")" = "$4" ] || _p2k_ini_put "$1" "$2" "$3" "$4"
    unset _id _old
}

p2k_restore() {
    _was=$(_p2k_take "$1/$2/$3") || return 0
    case "$_was" in
        set*) kwriteconfig6 --file "$1" --group "$2" --key "$3" "${_was#set	}" ;;
        *) kwriteconfig6 --file "$1" --group "$2" --key "$3" --delete ;;
    esac
    unset _was
}

p2k_remember() { [ -n "$2" ] && _p2k_note "@$1" set "$2"; return 0; }
p2k_recall() { _was=$(_p2k_take "@$1") || return 1; printf '%s\n' "${_was#set	}"; unset _was; }

# the user-level parts write to your own settings; under sudo they would make them root's
p2k_not_root() {
    [ "$(id -u)" != 0 ] || { echo "Run this as your user, not with sudo."; exit 1; }
}
