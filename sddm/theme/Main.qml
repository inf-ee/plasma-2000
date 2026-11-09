// SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
// SPDX-License-Identifier: GPL-3.0-or-later
/*
    Windows 2000 style SDDM login theme.
    Uses SDDM's theme API: sddm, userModel, sessionModel, keyboard, config.
*/

import QtQuick
import "branding.js" as Branding

Item {
    id: root
    width: 1600
    height: 900

    property bool showError: false
    property bool showShutdown: false
    property bool showOptions: false
    property bool busy: false
    property string notification: ""

    readonly property string product: config.bannerTitle || Branding.name

    // First user in the list, used when SDDM doesn't remember a last user
    Repeater {
        id: users
        model: userModel
        delegate: Item {
            required property string name
            readonly property string userName: name
        }
    }
    readonly property string defaultUser: userModel.lastUser
        ? userModel.lastUser
        : (users.count > 0 && users.itemAt(0) ? users.itemAt(0).userName : "")

    function submit() {
        if (busy || userField.text.length === 0) {
            return;
        }
        busy = true;
        notification = "";
        sddm.login(userField.text, passwordField.text, sessionCombo.currentIndex);
    }

    function focusFirstEmpty() {
        if (userField.text.length === 0) {
            userField.input.forceActiveFocus();
        } else {
            passwordField.input.forceActiveFocus();
        }
    }

    function closeError() {
        showError = false;
        passwordField.input.forceActiveFocus();
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            passwordField.text = "";
            root.showError = true;
            errorOk.forceActiveFocus();
        }
        function onInformationMessage(message) {
            root.notification = message;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: config.color || Classic.desktop
    }

    // ---------- "Log On to ..." dialog ----------
    ClassicWindow {
        id: dialog
        title: "Log On to " + root.product
        closable: false
        padding: 0
        active: !root.showError && !root.showShutdown
        enabled: active
        visible: !root.showShutdown
        anchors.centerIn: parent

        Column {
            width: 410

            Banner {}

            Column {
                width: parent.width
                topPadding: 13
                spacing: 8

                FieldRow {
                    label: "<u>U</u>ser name:"
                    ClassicTextField {
                        id: userField
                        anchors.fill: parent
                        text: root.defaultUser
                        input.enabled: !root.busy
                        onAccepted: passwordField.input.forceActiveFocus()
                    }
                }

                FieldRow {
                    label: "<u>P</u>assword:"
                    ClassicTextField {
                        id: passwordField
                        anchors.fill: parent
                        input.enabled: !root.busy
                        input.echoMode: TextInput.Password
                        input.passwordCharacter: "*"
                        input.passwordMaskDelay: 0
                        onAccepted: root.submit()
                    }
                }

                FieldRow {
                    z: 1 // keeps the drop-down list above the buttons
                    visible: root.showOptions
                    label: "<u>L</u>og on to:"
                    ClassicComboBox {
                        id: sessionCombo
                        anchors.fill: parent
                        model: sessionModel
                        nameRole: "name"
                        currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
                    }
                }

                ClassicLabel {
                    x: 84
                    width: 242
                    wrapMode: Text.WordWrap
                    visible: text.length > 0
                    text: {
                        const parts = [];
                        if (keyboard.capsLock) parts.push("Caps Lock is on.");
                        if (root.busy) parts.push("Logging on...");
                        if (root.notification) parts.push(root.notification);
                        return parts.join("\n");
                    }
                }

                Item {
                    width: parent.width
                    height: buttons.height + 22
                    Row {
                        id: buttons
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        spacing: 6

                        ClassicButton {
                            text: "OK"
                            isDefault: true
                            enabled: !root.busy
                            onClicked: root.submit()
                        }
                        ClassicButton {
                            text: "Cancel"
                            enabled: !root.busy && passwordField.text.length > 0
                            onClicked: {
                                passwordField.text = "";
                                root.notification = "";
                                root.focusFirstEmpty();
                            }
                        }
                        ClassicButton {
                            text: "Shutdown..."
                            enabled: sddm.canPowerOff || sddm.canReboot || sddm.canSuspend || sddm.canHibernate
                            onClicked: shutdownDialog.openDialog()
                        }
                        ClassicButton {
                            text: root.showOptions ? "Options <<" : "Options >>"
                            onClicked: root.showOptions = !root.showOptions
                        }
                    }
                }
            }
        }
    }

    // label + 242px control, laid out like the Win2000 dialog
    component FieldRow: Item {
        property string label
        default property alias control: holder.data
        width: 410
        height: 20
        ClassicLabel {
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.StyledText
            text: parent.label
        }
        Item {
            id: holder
            x: 84
            width: 242
            height: parent.height
        }
    }

    // blocks clicks to the dialog behind a message box
    MouseArea {
        anchors.fill: parent
        visible: root.showError
    }

    // ---------- "Logon Message" ----------
    ClassicWindow {
        id: errorBox
        title: "Logon Message"
        visible: root.showError
        anchors.horizontalCenter: dialog.horizontalCenter
        y: dialog.y + dialog.height / 2
        padding: 10

        Column {
            spacing: 14
            Row {
                spacing: 16
                leftPadding: 4
                topPadding: 4
                SysIcon { name: "dialog-warning" }
                ClassicLabel {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 380
                    wrapMode: Text.WordWrap
                    text: "The system could not log you on. Make sure your User name is correct, then type your password again. Letters in passwords must be typed using the correct case."
                }
            }
            ClassicButton {
                id: errorOk
                anchors.horizontalCenter: parent.horizontalCenter
                text: "OK"
                isDefault: true
                onClicked: root.closeError()
                Keys.onEscapePressed: root.closeError()
            }
        }
    }

    // ---------- "Shut Down ..." ----------
    ListModel { id: shutdownActions }

    ClassicWindow {
        id: shutdownDialog
        title: "Shut Down " + root.product
        closable: false
        padding: 0
        visible: root.showShutdown
        anchors.centerIn: parent

        function openDialog() {
            shutdownActions.clear();
            if (sddm.canPowerOff) shutdownActions.append({ name: "Shut down", action: "poweroff",
                text: "Ends your session and shuts down the computer so that you can safely turn off power." });
            if (sddm.canReboot) shutdownActions.append({ name: "Restart", action: "reboot",
                text: "Ends your session, shuts down the computer, and starts it again." });
            if (sddm.canSuspend) shutdownActions.append({ name: "Stand by", action: "suspend",
                text: "Keeps the computer running on low power with data still in memory." });
            if (sddm.canHibernate) shutdownActions.append({ name: "Hibernate", action: "hibernate",
                text: "Saves memory to disk and turns off the computer. Everything is restored the next time you start it." });
            actionCombo.currentIndex = 0;
            root.showShutdown = true;
            actionCombo.forceActiveFocus();
        }
        function closeDialog() {
            root.showShutdown = false;
            root.focusFirstEmpty();
        }
        function confirm() {
            if (shutdownActions.count === 0) {
                closeDialog();
                return;
            }
            const action = shutdownActions.get(actionCombo.currentIndex).action;
            root.showShutdown = false;
            // after Stand by / Hibernate the greeter is still there: typing must work on resume
            root.focusFirstEmpty();
            if (action === "poweroff") sddm.powerOff();
            else if (action === "reboot") sddm.reboot();
            else if (action === "suspend") sddm.suspend();
            else if (action === "hibernate") sddm.hibernate();
        }

        Column {
            width: 410

            Banner {}

            Item {
                width: parent.width
                height: 120

                SysIcon {
                    x: 14; y: 16
                    name: "system-shutdown"
                }
                ClassicLabel {
                    x: 60; y: 16
                    text: "What do you want the computer to do?"
                }
                ClassicComboBox {
                    id: actionCombo
                    z: 1
                    x: 60; y: 36
                    width: 240; height: 20
                    model: shutdownActions
                    nameRole: "name"
                    Keys.onReturnPressed: event => { if (!open) shutdownDialog.confirm(); else open = false; }
                    Keys.onEscapePressed: event => { if (!open) shutdownDialog.closeDialog(); else open = false; }
                }
                ClassicLabel {
                    x: 60; y: 66
                    width: 330
                    wrapMode: Text.WordWrap
                    text: shutdownActions.count > actionCombo.currentIndex && actionCombo.currentIndex >= 0
                          ? shutdownActions.get(actionCombo.currentIndex).text : ""
                }
            }

            Item {
                width: parent.width
                height: 23 + 12
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    spacing: 6
                    ClassicButton {
                        text: "OK"
                        isDefault: true
                        onClicked: shutdownDialog.confirm()
                    }
                    ClassicButton {
                        text: "Cancel"
                        onClicked: shutdownDialog.closeDialog()
                        Keys.onEscapePressed: shutdownDialog.closeDialog()
                    }
                }
            }
        }
    }

    // Keyboard layout in the bottom-right corner, only with several layouts (click to switch),
    // so a password that needs another layout can be typed
    Text {
        id: layoutIndicator
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8
        visible: keyboard.layouts.length > 1
        text: (keyboard.layouts[keyboard.currentLayout]?.shortName ?? "").toUpperCase()
        color: "white"
        font.family: Classic.fontFamily
        font.pixelSize: Classic.fontPx
        renderType: Text.QtRendering

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            onClicked: {
                keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length;
                root.focusFirstEmpty();
            }
        }
    }

    Component.onCompleted: focusFirstEmpty()
}
