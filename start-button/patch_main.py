#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
"""Turns Kickoff's flat panel button into a Windows 2000 style "Start" button.

Changes the compact (panel) representation in main.qml:
- a raised 3D bevel behind icon + label, sunken while the menu is open
- small (16px) icon, bold label at normal size, no hover glow
Each edit must match exactly once, so a changed upstream file fails loudly.
"""
import sys

path = sys.argv[1]
s = open(path, encoding="utf-8").read()


def replace(old, new):
    global s
    n = s.count(old)
    if n != 1:
        sys.exit(f"patch_main.py: expected 1 match, found {n}:\n{old}")
    s = s.replace(old, new)


# The added code uses these names from upstream main.qml. If one is renamed the
# edits below could still match while the widget fails to load, so check first.
REQUIRED = {
    "id: kickoff": "kickoff (root id)",
    "readonly property bool inPanel": "kickoff.inPanel",
    "readonly property bool vertical": "kickoff.vertical",
    "compactRepresentation: MouseArea {": "compactRoot being a MouseArea (pressed, containsMouse)",
    "id: compactRoot": "compactRoot",
    "id: compactDragArea": "compactDragArea",
    'import "code/tools.js" as Tools': "Tools",
    "import org.kde.kirigami as Kirigami": "Kirigami",
}
missing = [what for text, what in REQUIRED.items() if text not in s]
if missing:
    sys.exit("patch_main.py: upstream main.qml changed, these are gone: " + ", ".join(missing)
             + "\nThe patch needs updating; until then use stock Kickoff (./use.sh --revert).")


# like the task manager, ignore the panel's padding so the button can be as tall as task buttons
replace("    preferredRepresentation: compactRepresentation\n",
        "    preferredRepresentation: compactRepresentation\n"
        "    Plasmoid.constraintHints: Plasmoid.CanFillArea\n")

# fill the panel's height (Kickoff only asks for icon height, so it sat centred and short)
replace("        Layout.minimumHeight: Layout.preferredHeight\n",
        "        Layout.minimumHeight: Layout.preferredHeight\n"
        "        Layout.fillHeight: kickoff.inPanel && !kickoff.vertical\n")

# room for the bevel + padding in the button width
replace("            let impWidth = 0;\n",
        "            let impWidth = startBevel.visible ? 10 : 0; // bevel padding + 2px gap\n")

BEVEL = '''        // Windows 2000 style "Start" button: raised, sunken while the menu is open
        Item {
            id: startBevel
            readonly property bool down: kickoff.expanded || (compactRoot.pressed && compactRoot.containsMouse)
            readonly property color face: Kirigami.Theme.backgroundColor
            readonly property color light: "#ffffff"
            readonly property color shadow: Qt.darker(face, 1.65)
            readonly property color dark: Qt.darker(face, 3.3)
            Kirigami.Theme.colorSet: Kirigami.Theme.Button
            Kirigami.Theme.inherit: false
            visible: kickoff.inPanel && !kickoff.vertical
            anchors.fill: parent
            // same height as the taskbar buttons next to it
            // lines up with the task buttons' bevel (measured: 3 logical px top and bottom)
            anchors.topMargin: 3
            anchors.bottomMargin: 3
            anchors.leftMargin: 2

            Rectangle { anchors.fill: parent; color: startBevel.face }
            // outer edge
            Rectangle { x: 0; y: 0; width: parent.width; height: 1; color: startBevel.down ? startBevel.dark : startBevel.light }
            Rectangle { x: 0; y: 0; width: 1; height: parent.height; color: startBevel.down ? startBevel.dark : startBevel.light }
            Rectangle { x: 0; y: parent.height - 1; width: parent.width; height: 1; color: startBevel.down ? startBevel.light : startBevel.dark }
            Rectangle { x: parent.width - 1; y: 0; width: 1; height: parent.height; color: startBevel.down ? startBevel.light : startBevel.dark }
            // inner edge
            Rectangle { x: 1; y: 1; width: parent.width - 2; height: 1; color: startBevel.down ? startBevel.shadow : startBevel.face }
            Rectangle { x: 1; y: 1; width: 1; height: parent.height - 2; color: startBevel.down ? startBevel.shadow : startBevel.face }
            Rectangle { x: 1; y: parent.height - 2; width: parent.width - 2; height: 1; color: startBevel.down ? startBevel.face : startBevel.shadow }
            Rectangle { x: parent.width - 2; y: 1; width: 1; height: parent.height - 2; color: startBevel.down ? startBevel.face : startBevel.shadow }
        }

'''
replace('''        RowLayout {
            id: iconLabelRow
            anchors.fill: parent
            spacing: 0
''', BEVEL + '''        RowLayout {
            id: iconLabelRow
            anchors.fill: parent
            // inside the bevel; content shifts 1px down-right when pressed
            anchors.leftMargin: startBevel.visible ? (startBevel.down ? 7 : 6) : 0
            anchors.rightMargin: startBevel.visible ? (startBevel.down ? 3 : 4) : 0
            anchors.topMargin: startBevel.visible ? (startBevel.down ? 8 : 7) : 0
            anchors.bottomMargin: startBevel.visible ? (startBevel.down ? 6 : 7) : 0
            spacing: 0
''')

# 16px icon like the original, no hover glow
replace('''                Layout.maximumHeight: Kirigami.Units.iconSizes.huge
                Layout.maximumWidth: Kirigami.Units.iconSizes.huge
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                source: Tools.iconOrDefault(Plasmoid.formFactor, Plasmoid.icon)
                active: compactRoot.containsMouse || compactDragArea.containsDrag''',
        '''                Layout.maximumHeight: startBevel.visible ? Kirigami.Units.iconSizes.small : Kirigami.Units.iconSizes.huge
                Layout.maximumWidth: startBevel.visible ? Kirigami.Units.iconSizes.small : Kirigami.Units.iconSizes.huge
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                source: Tools.iconOrDefault(Plasmoid.formFactor, Plasmoid.icon)
                active: false''')

# bold label at the normal font size instead of filling the panel height
replace('''                fontSizeMode: Text.VerticalFit
                font.pixelSize: compactRoot.tooSmall ? Kirigami.Theme.defaultFont.pixelSize : Kirigami.Units.iconSizes.roundedIconSize(Kirigami.Units.gridUnit * 2)
                minimumPointSize: Kirigami.Theme.smallFont.pointSize
''', '''                font.bold: true
''')

open(path, "w", encoding="utf-8").write(s)
print("patched", path)

# Footer.qml: the Applications/Places tab marker uses the panel style's top-edge
# image, because the Plasma 2000 panel style hides the bottom-edge one (that image
# is also the blue "popup open" strip under panel buttons).
import os
fpath = os.path.join(os.path.dirname(path), "Footer.qml")
s = open(fpath, encoding="utf-8").read()
replace('prefix: tabBar.position === PC3.TabBar.Header ? "north-active-tab" : "south-active-tab"',
        'prefix: "north-active-tab"')
open(fpath, "w", encoding="utf-8").write(s)
print("patched", fpath)
