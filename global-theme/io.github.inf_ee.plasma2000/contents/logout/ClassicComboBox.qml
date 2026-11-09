// SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
// SPDX-License-Identifier: GPL-3.0-or-later
// Drop-down list: sunken box with an arrow button and a popup list.
// model roles: uses `nameRole` (default "name").
import QtQuick

FocusScope {
    id: combo
    property var model
    property string nameRole: "name"
    property int currentIndex: 0
    readonly property string currentText: repeater.count > currentIndex && currentIndex >= 0 && repeater.itemAt(currentIndex)
                                          ? repeater.itemAt(currentIndex).text : ""
    property bool open: false
    property int hoveredIndex: -1
    onOpenChanged: hoveredIndex = -1

    implicitHeight: 22
    implicitWidth: 200
    activeFocusOnTab: true
    z: open ? 100 : 0

    Bevel {
        anchors.fill: parent
        style: "sunken"
        fill: "white"

        Rectangle {
            // selected text looks highlighted while focused
            x: 1; y: 1
            width: parent.width - arrow.width - 3
            height: parent.height - 2
            color: combo.activeFocus && !combo.open ? Classic.selection : "transparent"
            ClassicLabel {
                anchors.fill: parent
                anchors.leftMargin: 2
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                text: combo.currentText
                color: combo.activeFocus && !combo.open ? "white" : "black"
            }
        }

        Bevel {
            id: arrow
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 16
            style: mouse.pressed ? "pressed" : "raised"
            PixelArt {
                anchors.centerIn: parent
                pixel: 1
                palette: ({ k: "black" })
                rows: ["kkkkkkk", ".kkkkk.", "..kkk..", "...k..."]
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        onClicked: {
            combo.forceActiveFocus();
            combo.open = !combo.open;
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Down) {
            if (event.modifiers & Qt.AltModifier) combo.open = !combo.open;
            else combo.currentIndex = Math.min(repeater.count - 1, combo.currentIndex + 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            combo.currentIndex = Math.max(0, combo.currentIndex - 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_F4) {
            combo.open = !combo.open;
            event.accepted = true;
        } else if (combo.open && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Escape)) {
            combo.open = false;
            event.accepted = true;
        }
    }
    onActiveFocusChanged: if (!activeFocus) open = false

    // popup list (always built so currentText works while closed)
    Rectangle {
        y: combo.height
        width: combo.width
        height: list.height + 2
        visible: combo.open
        color: "black"
        Column {
            id: list
            x: 1; y: 1
            width: parent.width - 2
            Repeater {
                id: repeater
                model: combo.model
                delegate: Rectangle {
                    id: row
                    required property int index
                    required property var model
                    readonly property string text: model[combo.nameRole] ?? ""
                    width: list.width
                    height: 18
                    color: index === (combo.hoveredIndex >= 0 ? combo.hoveredIndex : combo.currentIndex) ? Classic.selection : "white"
                    ClassicLabel {
                        anchors.fill: parent
                        anchors.leftMargin: 3
                        verticalAlignment: Text.AlignVCenter
                        text: row.text
                        color: parent.color === Classic.selection ? "white" : "black"
                    }
                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onContainsMouseChanged: if (containsMouse) combo.hoveredIndex = row.index
                        onClicked: {
                            combo.currentIndex = row.index;
                            combo.open = false;
                        }
                    }
                }
            }
        }
    }
}
