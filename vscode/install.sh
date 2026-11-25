#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Installs the Plasma 2000 colour theme into VS Code (and VSCodium, if present).
# Pick it with Ctrl+K Ctrl+T, or set "workbench.colorTheme": "Plasma 2000".
#   ./install.sh                     install the theme only
#   ./install.sh --native-titlebar   also use KDE's (Windows 2000) title bar, with VS
#                                    Code's grey menu bar under it; uninstall.sh puts them back
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
[ "$(id -u)" != 0 ] || { echo "Run this as your user, not with sudo."; exit 1; }
NATIVE=
case "$1" in
    --native-titlebar) NATIVE=1 ;;
    "") ;;
    *) echo "Usage: $0 [--native-titlebar]"; exit 1 ;;
esac
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_DATA_HOME:-$HOME/.local/share}/plasma2000"
TMP=$(mktemp -d)
trap 'rm -f "$TMP/plasma-2000.vsix"; rmdir "$TMP"' EXIT
python3 -I "$HERE/build-vsix.py" "$HERE/plasma-2000" "$TMP/plasma-2000.vsix"
found=
for cli in code codium code-insiders; do
    command -v "$cli" >/dev/null 2>&1 || continue
    "$cli" --install-extension "$TMP/plasma-2000.vsix" --force
    found=1
    if [ -n "$NATIVE" ]; then
        case "$cli" in
            code) dir=Code ;; codium) dir=VSCodium ;; code-insiders) dir="Code - Insiders" ;;
        esac
        python3 -I "$HERE/settings.py" apply "$CONFIG/$dir/User/settings.json" "$STATE/vscode-$cli.json" \
            && echo "$cli: KDE title bar (restart VS Code to see it)."
    fi
done
[ -n "$found" ] || { echo "VS Code not found (no code/codium in PATH); nothing installed."; exit 0; }
echo "Installed. In VS Code: Ctrl+K Ctrl+T -> Plasma 2000."
