#!/bin/sh
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
# Builds "Start Menu (Plasma 2000)": a copy of Plasma's Kickoff for the installed
# Plasma version, with a Win2000-style raised Start button, and installs it.
# Re-run after Plasma upgrades.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ID=io.github.inf_ee.plasma2000.start
REPO=https://github.com/inf-ee/plasma-2000
die() { echo "build.sh: $*" >&2; exit 1; }
for c in curl python3 plasmashell kpackagetool6; do
    command -v "$c" >/dev/null 2>&1 || die "$c not found; install it and run again."
done

# Kickoff's source for exactly this Plasma release (tag v6.6.6), or else the
# newest of its branch (Plasma/6.6), e.g. for a beta that has no tag yet
FULL=$(plasmashell --version 2>/dev/null | awk '{print $2}')
VER=$(echo "$FULL" | cut -d. -f1,2)
[ -n "$VER" ] || die "could not read the Plasma version from 'plasmashell --version'."
API="https://invent.kde.org/api/v4/projects/plasma%2Fplasma-desktop/repository/tree?path=applets/kickoff&recursive=true&per_page=100"
REF=
for r in "v$FULL" "Plasma/$VER"; do
    if TREE=$(curl -sf "$API&ref=$r") && [ -n "$TREE" ]; then REF=$r; break; fi
done
[ -n "$REF" ] || die "could not download Kickoff for Plasma $FULL from invent.kde.org (tried tag v$FULL and branch Plasma/$VER).
Check the network connection. A development build of Plasma may have no matching source."
FILES=$(printf '%s' "$TREE" | python3 -I -c "
import json, sys
try:
    tree = json.load(sys.stdin)
    print('\n'.join(x['path'].split('applets/kickoff/')[1] for x in tree if x['type'] == 'blob'))
except Exception as e:
    sys.exit(f'unexpected file list from invent.kde.org: {e}')
") || die "could not read Kickoff's file list."
[ -n "$FILES" ] || die "Kickoff's file list for $REF is empty."
BASE="https://invent.kde.org/plasma/plasma-desktop/-/raw/$REF/applets/kickoff"
OUT="$HERE/build/$ID"
echo "Building from Kickoff $REF"

rm -rf "$HERE/build"
mkdir -p "$OUT/contents/ui/code" "$OUT/contents/config"
for f in $FILES; do
    case "$f" in
        *.qml|code/*.js) dest="$OUT/contents/ui/$f" ;;
        main.xml|config.qml) dest="$OUT/contents/config/$f" ;;
        metadata.json) dest="$HERE/build/upstream-metadata.json" ;;
        *) continue ;;
    esac
    mkdir -p "$(dirname "$dest")"
    curl -sfL -o "$dest" "$BASE/$f" || die "download failed: $BASE/$f"
done
[ -f "$HERE/build/upstream-metadata.json" ] && [ -f "$OUT/contents/ui/main.qml" ] \
    || die "Kickoff's main.qml or metadata.json is missing in $REF."
mv "$OUT/contents/ui/config.qml" "$OUT/contents/config/config.qml" 2>/dev/null || true

# Installed as a package, the QML files need a qmldir to declare the singletons
# (upstream does this in CMake). A qmldir must list every type in the folder.
(
    cd "$OUT/contents/ui"
    echo "module $ID"
    for q in *.qml; do
        t=${q%.qml}
        [ "$t" = main ] && continue
        if grep -q '^pragma Singleton' "$q"; then echo "singleton $t 1.0 $q"; else echo "$t 1.0 $q"; fi
    done
) > "$OUT/contents/ui/qmldir"

python3 -I - "$HERE/build/upstream-metadata.json" "$OUT/metadata.json" "$ID" "$REPO" <<'PY'
import json, sys
src, dst, pid, repo = sys.argv[1:]
d = json.load(open(src))
k = {key: v for key, v in d["KPlugin"].items() if "[" not in key}
# keep Kickoff's authors (without the translated names); bugs in this copy go to Plasma 2000
authors = [{key: v for key, v in a.items() if "[" not in key} for a in k.get("Authors", [])]
k.update({"Id": pid, "Name": "Start Menu (Plasma 2000)",
          "Description": "Kickoff with a Windows 2000 style raised Start button",
          "Authors": authors + [{"Name": "Plasma 2000 (Start button)", "Website": repo}],
          "Website": repo, "BugReportUrl": repo + "/issues"})
d["KPlugin"] = k
d["KPackageStructure"] = "Plasma/Applet"
json.dump(d, open(dst, "w"), indent=4)
PY

python3 -I "$HERE/patch_main.py" "$OUT/contents/ui/main.qml"

if kpackagetool6 -t Plasma/Applet -l | grep -qx "$ID"; then
    kpackagetool6 -t Plasma/Applet -u "$OUT"
else
    kpackagetool6 -t Plasma/Applet -i "$OUT"
fi
rm -rf "$HOME/.cache/plasmashell/qmlcache"
echo "Installed $ID. Use ./use.sh to put it in place of Kickoff on the panel."
