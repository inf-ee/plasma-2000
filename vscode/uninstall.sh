#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Removes the Plasma 2000 colour theme from VS Code (and VSCodium) and puts back the
# title bar settings --native-titlebar changed. VS Code falls back to its default
# theme if Plasma 2000 was selected.
HERE=$(cd "$(dirname "$0")" && pwd)
[ "$(id -u)" != 0 ] || { echo "Run this as your user, not with sudo."; exit 1; }
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_DATA_HOME:-$HOME/.local/share}/plasma2000"
for cli in code codium code-insiders; do
    case "$cli" in
        code) dir=Code ;; codium) dir=VSCodium ;; code-insiders) dir="Code - Insiders" ;;
    esac
    [ -f "$STATE/vscode-$cli.json" ] && \
        python3 -I "$HERE/settings.py" revert "$CONFIG/$dir/User/settings.json" "$STATE/vscode-$cli.json"
    command -v "$cli" >/dev/null 2>&1 || continue
    "$cli" --uninstall-extension inf-ee.plasma-2000 || true
done
