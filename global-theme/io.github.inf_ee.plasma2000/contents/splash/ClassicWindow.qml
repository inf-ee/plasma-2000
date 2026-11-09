// SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
// SPDX-License-Identifier: GPL-3.0-or-later
// Dialog frame with a gradient title bar and an optional (decorative) close button.
import QtQuick

Bevel {
    id: win
    property string title
    property bool active: true
    property bool closable: true
    property int padding: 10
    default property alias body: bodyItem.data

    style: "window"
    implicitWidth: bodyItem.childrenRect.width + 2 * padding + 6
    implicitHeight: bodyItem.childrenRect.height + 2 * padding + titleBar.height + 7

    Rectangle {
        id: titleBar
        // Bevel already insets its children by its 2px border; 1 more px of face colour
        x: 1; y: 1
        width: parent.width - 2
        height: 18
        antialiasing: false
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: win.active ? Classic.titleStart : Classic.inactiveTitleStart }
            GradientStop { position: 1; color: win.active ? Classic.titleEnd : Classic.inactiveTitleEnd }
        }

        ClassicLabel {
            anchors.left: parent.left
            anchors.leftMargin: 3
            anchors.verticalCenter: parent.verticalCenter
            text: win.title
            color: win.active ? "white" : Classic.inactiveTitleText
            font.bold: true
        }

        Bevel {
            visible: win.closable
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            width: 16; height: 14
            PixelArt {
                anchors.centerIn: parent
                pixel: 1
                palette: ({ k: "black" })
                rows: ["kk....kk", ".kk..kk.", "..kkkk..", "...kk...", "..kkkk..", ".kk..kk.", "kk....kk"]
            }
        }
    }

    Item {
        id: bodyItem
        x: 1 + win.padding
        y: titleBar.y + titleBar.height + 1 + win.padding
    }
}
