// SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
// SPDX-License-Identifier: GPL-3.0-or-later
// Classic push button: raised bevel, dotted focus rectangle, black frame when default.
import QtQuick

FocusScope {
    id: button
    property string text
    property bool isDefault: false
    signal clicked()

    implicitWidth: Math.max(75, label.implicitWidth + 16)
    implicitHeight: 23
    activeFocusOnTab: true

    readonly property bool down: mouse.pressed && mouse.containsMouse || keyDown
    property bool keyDown: false
    readonly property bool framed: isDefault || activeFocus

    Rectangle {
        anchors.fill: parent
        color: "black"
        visible: button.framed
    }

    Bevel {
        anchors.fill: parent
        anchors.margins: button.framed ? 1 : 0
        style: button.down ? "pressed" : "raised"

        // disabled text is "etched": white copy offset under a grey one
        ClassicLabel {
            visible: !button.enabled
            anchors.centerIn: label
            anchors.horizontalCenterOffset: 1
            anchors.verticalCenterOffset: 1
            text: button.text
            color: Classic.highlight
        }
        ClassicLabel {
            id: label
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: button.down ? 1 : 0
            anchors.verticalCenterOffset: button.down ? 1 : 0
            text: button.text
            color: button.enabled ? "black" : Classic.shadow
        }

        // dotted focus rectangle
        Item {
            visible: button.activeFocus
            anchors.fill: parent
            anchors.margins: 2
            Repeater {
                model: Math.max(0, Math.ceil(parent.width / 2))
                delegate: Item {
                    required property int index
                    Rectangle { x: index * 2; y: 0; width: 1; height: 1; color: "black" }
                    Rectangle { x: index * 2; y: parent.parent.height - 1; width: 1; height: 1; color: "black" }
                }
            }
            Repeater {
                model: Math.max(0, Math.ceil(parent.height / 2))
                delegate: Item {
                    required property int index
                    Rectangle { x: 0; y: index * 2; width: 1; height: 1; color: "black" }
                    Rectangle { x: parent.parent.width - 1; y: index * 2; width: 1; height: 1; color: "black" }
                }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.clicked()
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space && !event.isAutoRepeat) {
            keyDown = true;
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            button.clicked();
            event.accepted = true;
        }
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Space && !event.isAutoRepeat && keyDown) {
            keyDown = false;
            button.clicked();
            event.accepted = true;
        }
    }
}
