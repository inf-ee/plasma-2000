/*
    SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
    SPDX-License-Identifier: GPL-3.0-or-later

    Windows 2000 style sunken box around the panel widgets to its right
    (system tray + clock). Put it directly left of the system tray.

    It draws only a thin frame outside its own small area; the tray and clock are
    painted on top of it and stay fully clickable, nothing of theirs is modified.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    // use the panel's full height, like task buttons (ignores panel padding)
    Plasmoid.constraintHints: Plasmoid.CanFillArea

    // Win2000 colours: the frame's dark top/left edge and light bottom/right edge
    readonly property color shadow: "#808080"
    readonly property color highlight: "#ffffff"
    // inset from the panel's top/bottom so it lines up with task buttons and Start
    readonly property int vInset: 3
    // gap between the taskbar buttons and the box
    readonly property int gap: 3
    // room between the clock and the box's right edge (drawn into the panel's end margin)
    readonly property int rightPadding: 4

    fullRepresentation: Item {
        id: frameRoot
        readonly property bool horizontal: Plasmoid.formFactor !== PlasmaCore.Types.Vertical
        Layout.minimumWidth: root.gap + 1
        Layout.preferredWidth: root.gap + 1
        Layout.maximumWidth: root.gap + 1
        Layout.fillHeight: true

        // The panel wraps each widget in a container; find ours and its siblings.
        readonly property Item container: {
            let item = frameRoot.parent;
            while (item) {
                if (item.isAppletContainer) {
                    return item;
                }
                item = item.parent;
            }
            return null;
        }
        readonly property Item layout: container ? container.parent : null

        // right edge (in panel layout coordinates) of the last widget after us
        readonly property real spanEnd: {
            if (!layout || !container) {
                return 0;
            }
            let end = container.x + container.width;
            const kids = layout.children;
            for (let i = 0; i < kids.length; ++i) {
                const k = kids[i];
                if (k.visible && k.isAppletContainer && k.x >= container.x) {
                    end = Math.max(end, k.x + k.width);
                }
            }
            return end;
        }
        // offset of this item inside its container (normally 0)
        readonly property point origin: container ? frameRoot.mapToItem(container, 0, 0) : Qt.point(0, 0)

        Item {
            id: box
            visible: frameRoot.horizontal && frameRoot.layout !== null
            x: root.gap - frameRoot.origin.x
            y: root.vInset
            width: frameRoot.container ? frameRoot.spanEnd + root.rightPadding - frameRoot.container.x - root.gap - frameRoot.origin.x : 0
            height: frameRoot.height - 2 * root.vInset

            // top and left: shadow
            Rectangle { x: 0; y: 0; width: parent.width; height: 1; color: root.shadow }
            Rectangle { x: 0; y: 0; width: 1; height: parent.height; color: root.shadow }
            // bottom and right: highlight
            Rectangle { x: 0; y: parent.height - 1; width: parent.width; height: 1; color: root.highlight }
            Rectangle { x: parent.width - 1; y: 0; width: 1; height: parent.height; color: root.highlight }
        }
    }
}
