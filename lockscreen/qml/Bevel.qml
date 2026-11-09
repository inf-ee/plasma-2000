// SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
// SPDX-License-Identifier: GPL-3.0-or-later
// Two-pixel Classic 3D border. Put content inside; it's inset by 2px.
import QtQuick

Item {
    id: bevel
    // "raised" (buttons), "window" (dialog frames), "sunken" (text fields), "status" (thin 1px sunken)
    property string style: "raised"
    property color fill: Classic.face
    default property alias content: inner.data

    readonly property var colors: ({
        raised: [Classic.highlight, Classic.darkShadow, Classic.light, Classic.shadow],
        pressed: [Classic.darkShadow, Classic.highlight, Classic.shadow, Classic.light],
        window: [Classic.light, Classic.darkShadow, Classic.highlight, Classic.shadow],
        sunken: [Classic.shadow, Classic.highlight, Classic.darkShadow, Classic.light],
        status: [Classic.shadow, Classic.highlight, "transparent", "transparent"]
    })
    readonly property var c: colors[style]

    Rectangle { anchors.fill: parent; color: bevel.fill; antialiasing: false }

    // outer: top-left, bottom-right
    Rectangle { x: 0; y: 0; width: parent.width; height: 1; color: bevel.c[0] }
    Rectangle { x: 0; y: 0; width: 1; height: parent.height; color: bevel.c[0] }
    Rectangle { x: 0; y: parent.height - 1; width: parent.width; height: 1; color: bevel.c[1] }
    Rectangle { x: parent.width - 1; y: 0; width: 1; height: parent.height; color: bevel.c[1] }
    // inner
    Rectangle { x: 1; y: 1; width: parent.width - 2; height: 1; color: bevel.c[2] }
    Rectangle { x: 1; y: 1; width: 1; height: parent.height - 2; color: bevel.c[2] }
    Rectangle { x: 1; y: parent.height - 2; width: parent.width - 2; height: 1; color: bevel.c[3] }
    Rectangle { x: parent.width - 2; y: 1; width: 1; height: parent.height - 2; color: bevel.c[3] }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: 2
    }
}
