// SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
// SPDX-License-Identifier: GPL-3.0-or-later
// Sunken white text box.
import QtQuick

Bevel {
    id: field
    property alias input: textInput
    property alias text: textInput.text
    signal accepted()

    style: "sunken"
    fill: textInput.enabled ? "white" : Classic.face
    implicitHeight: 22

    TextInput {
        id: textInput
        anchors.fill: parent
        anchors.leftMargin: 3
        anchors.rightMargin: 3
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        activeFocusOnTab: true
        font.family: Classic.fontFamily
        font.pixelSize: Classic.fontPx
        renderType: Text.QtRendering
        color: "black"
        selectionColor: Classic.selection
        selectedTextColor: "white"
        selectByMouse: true
        onAccepted: field.accepted()
        // select everything when tabbing in, like Windows does
        onActiveFocusChanged: if (activeFocus && echoMode === TextInput.Normal) selectAll()
    }
}
