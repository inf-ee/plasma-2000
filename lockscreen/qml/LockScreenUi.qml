/*
    Windows 2000 style lock screen.
    Authentication logic follows Plasma's stock LockScreenUi.qml / MainBlock.qml.

    SPDX-FileCopyrightText: 2014 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
    SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2026 Dmitrii Shaburov

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQml
import QtQuick

import org.kde.plasma.private.keyboardindicator as KeyboardIndicator
import org.kde.plasma.workspace.keyboardlayout as Keyboards
import org.kde.plasma.workspace.components as PW
import org.kde.kscreenlocker as ScreenLocker
import org.kde.plasma.private.sessions

Item {
    id: lockScreenUi

    property bool noPasswordMode: false
    property bool showError: false
    property bool showOptions: false
    // KWin's on-screen keyboard (Wayland only), for touch screens without a keyboard
    readonly property bool canShowKeyboard: Qt.platform.pluginName.includes("wayland")
                                            && Keyboards.KWinVirtualKeyboard.available

    function showKeyboard() {
        // focus first, or the on-screen keyboard's keystrokes go nowhere
        passwordField.input.forceActiveFocus();
        Keyboards.KWinVirtualKeyboard.enabled = true;
        Qt.inputMethod.show();
    }

    function handleMessage(msg) {
        if (!msg) {
            return;
        }
        if (!root.notification) {
            root.notification = msg;
        } else if (!root.notification.includes(msg)) {
            root.notification += "\n" + msg;
        }
        notificationRemoveTimer.restart();
    }

    function submit() {
        if (noPasswordMode) {
            Qt.quit();
            return;
        }
        if (!passwordField.input.enabled) {
            return;
        }
        authenticator.respond(passwordField.text);
    }

    function clearPassword() {
        passwordField.text = "";
        passwordField.text = Qt.binding(() => PasswordSync.password);
    }

    function closeError() {
        showError = false;
        passwordField.input.forceActiveFocus();
    }

    Connections {
        target: authenticator
        function onFailed(kind) {
            if (kind != 0) { // noninteractive authenticators (fingerprint, smartcard)
                return;
            }
            lockScreenUi.showError = true;
            errorOk.forceActiveFocus();
            graceLockTimer.restart();
        }
        function onSucceeded() {
            if (authenticator.hadPrompt) {
                Qt.quit();
            } else {
                lockScreenUi.noPasswordMode = true;
                okButton.forceActiveFocus();
            }
        }
        function onInfoMessageChanged() { lockScreenUi.handleMessage(authenticator.infoMessage); }
        function onErrorMessageChanged() { lockScreenUi.handleMessage(authenticator.errorMessage); }
        function onPromptChanged(msg) { lockScreenUi.handleMessage(authenticator.prompt); }
        function onPromptForSecretChanged(msg) {
            if (!lockScreenUi.showError) {
                passwordField.input.forceActiveFocus();
            }
        }
        function onNoninteractiveError(kind, auth) { lockScreenUi.handleMessage(auth.errorMessage); }
    }

    SessionManagement { id: sessionManagement }

    Connections {
        target: sessionManagement
        function onAboutToSuspend() { root.clearPassword(); }
    }

    Connections {
        target: root
        function onClearPassword() {
            lockScreenUi.clearPassword();
            if (!lockScreenUi.showError) {
                passwordField.input.forceActiveFocus();
            }
        }
    }

    KeyboardIndicator.KeyState {
        id: capsLockState
        key: Qt.Key_CapsLock
    }

    Timer {
        id: notificationRemoveTimer
        interval: 5000
        onTriggered: root.notification = ""
    }
    Timer {
        id: graceLockTimer
        interval: 3000
        onTriggered: {
            root.clearPassword();
            authenticator.startAuthenticating();
        }
    }

    MouseArea {
        id: lockScreenRoot
        anchors.fill: parent

        property bool uiVisible: false
        property bool seenPositionChange: false

        hoverEnabled: true
        cursorShape: uiVisible ? Qt.ArrowCursor : Qt.BlankCursor
        onPressed: uiVisible = true
        onPositionChanged: {
            uiVisible = seenPositionChange;
            seenPositionChange = true;
        }
        onUiVisibleChanged: {
            if (uiVisible) {
                Window.window.requestActivate();
                idleTimer.restart();
            }
            authenticator.startAuthenticating();
        }
        Keys.onEscapePressed: {
            // kscreenlocker turns the screen off on Escape
            if (uiVisible) {
                uiVisible = false;
                if (Keyboards.KWinVirtualKeyboard.visible) {
                    Qt.inputMethod.hide();
                }
                root.clearPassword();
            }
        }
        Keys.onPressed: event => {
            uiVisible = true;
            idleTimer.restart();
            event.accepted = false;
        }

        // Hide the mouse cursor again after a while without input
        Timer {
            id: idleTimer
            interval: 10000
            onTriggered: {
                if (passwordField.text.length === 0 && !lockScreenUi.showError) {
                    lockScreenRoot.uiVisible = false;
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Classic.desktop
        }

        // ---------- "Unlock Computer" dialog ----------
        ClassicWindow {
            id: dialog
            title: "Unlock Computer"
            closable: false
            padding: 0
            active: !lockScreenUi.showError
            enabled: active
            anchors.centerIn: parent
            // move up out of the way of the on-screen keyboard, but stay on screen
            anchors.verticalCenterOffset: Keyboards.KWinVirtualKeyboard.visible
                ? -Math.min(Qt.inputMethod.keyboardRectangle.height / 2, Math.max(0, (parent.height - height) / 2 - 8))
                : 0

            Column {
                width: 410

                Banner {}

                Column {
                    width: parent.width
                    topPadding: 12
                    spacing: 8

                    Item {
                        width: parent.width
                        height: Math.max(32, lockText.implicitHeight)
                        SysIcon {
                            x: 14
                            name: "system-lock-screen"
                        }
                        ClassicLabel {
                            id: lockText
                            x: 60
                            width: parent.width - x - 14
                            wrapMode: Text.WordWrap
                            text: lockScreenUi.noPasswordMode
                                  ? "This computer is in use and has been locked.\n\nClick OK to unlock this computer."
                                  : "This computer is in use and has been locked.\n\nOnly " + kscreenlocker_userName + " can unlock this computer."
                        }
                    }

                    Item { width: 1; height: 4 }

                    FieldRow {
                        visible: !lockScreenUi.noPasswordMode
                        label: "<u>U</u>ser name:"
                        ClassicTextField {
                            anchors.fill: parent
                            text: kscreenlocker_userName
                            input.enabled: false
                        }
                    }

                    FieldRow {
                        visible: !lockScreenUi.noPasswordMode
                        label: "<u>P</u>assword:"
                        ClassicTextField {
                            id: passwordField
                            anchors.fill: parent
                            text: PasswordSync.password
                            input.focus: true
                            input.echoMode: TextInput.Password
                            input.passwordCharacter: "*"
                            input.passwordMaskDelay: 0
                            input.enabled: !authenticator.graceLocked && !graceLockTimer.running
                            // Only draw the cursor while the dialog is in use (avoids constant repaints)
                            input.cursorVisible: input.activeFocus && (lockScreenRoot.uiVisible || text.length > 0)
                            onAccepted: {
                                // Typed characters don't reach lockScreenRoot's key handler, so a
                                // password typed without touching the mouse leaves uiVisible false.
                                // Enter on an empty field only wakes the dialog, as in stock Plasma.
                                const wasVisible = lockScreenRoot.uiVisible;
                                lockScreenRoot.uiVisible = true;
                                idleTimer.restart();
                                if (wasVisible || text.length > 0) {
                                    lockScreenUi.submit();
                                }
                            }
                        }
                        Binding {
                            target: PasswordSync
                            property: "password"
                            value: passwordField.text
                        }
                    }

                    ClassicLabel {
                        x: 84
                        width: 310
                        wrapMode: Text.WordWrap
                        visible: text.length > 0
                        text: {
                            const parts = [];
                            if (capsLockState.locked) parts.push("Caps Lock is on.");
                            if (root.notification) parts.push(root.notification);
                            if (authenticator.authenticatorTypes & ScreenLocker.Authenticator.Fingerprint) {
                                parts.push("You can also scan your fingerprint.");
                            }
                            return parts.join("\n");
                        }
                    }

                    // extra actions, revealed by "Options >>"
                    Row {
                        x: 84
                        spacing: 6
                        visible: lockScreenUi.showOptions
                        ClassicButton {
                            text: "Sleep"
                            visible: root.suspendToRamSupported
                            onClicked: root.suspendToRam()
                        }
                        ClassicButton {
                            text: "Hibernate"
                            visible: root.suspendToDiskSupported
                            onClicked: root.suspendToDisk()
                        }
                        ClassicButton {
                            text: "Switch User..."
                            visible: sessionManagement.canSwitchUser
                            onClicked: sessionManagement.switchUser()
                        }
                        ClassicButton {
                            text: "Keyboard"
                            visible: lockScreenUi.canShowKeyboard
                            onClicked: lockScreenUi.showKeyboard()
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
                                id: okButton
                                text: "OK"
                                isDefault: true
                                onClicked: lockScreenUi.submit()
                            }
                            ClassicButton {
                                text: "Cancel"
                                visible: !lockScreenUi.noPasswordMode
                                enabled: passwordField.text.length > 0
                                onClicked: {
                                    root.clearPassword();
                                    passwordField.input.forceActiveFocus();
                                }
                            }
                            ClassicButton {
                                text: lockScreenUi.showOptions ? "Options <<" : "Options >>"
                                visible: root.suspendToRamSupported || root.suspendToDiskSupported || sessionManagement.canSwitchUser
                                         || lockScreenUi.canShowKeyboard
                                onClicked: lockScreenUi.showOptions = !lockScreenUi.showOptions
                            }
                        }
                    }
                }
            }
        }

        // blocks clicks to the dialog behind the message box
        MouseArea {
            anchors.fill: parent
            visible: lockScreenUi.showError
        }

        // ---------- Wrong password ----------
        ClassicWindow {
            id: errorBox
            title: "Unlock Computer"
            visible: lockScreenUi.showError
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
                        text: "The system could not unlock the computer. Make sure your password is correct, then type it again. Letters in passwords must be typed using the correct case."
                    }
                }
                ClassicButton {
                    id: errorOk
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "OK"
                    isDefault: true
                    onClicked: lockScreenUi.closeError()
                    Keys.onEscapePressed: lockScreenUi.closeError()
                }
            }
        }

        // Keyboard layout, barely visible in the bottom-right corner (click to switch)
        Text {
            id: layoutIndicator
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8
            visible: layoutSwitcher.hasMultipleKeyboardLayouts
            text: (layoutSwitcher.layoutNames.shortName || "").toUpperCase()
            color: "white"
            opacity: 1
            font.family: Classic.fontFamily
            font.pixelSize: Classic.fontPx
            renderType: Text.QtRendering

            PW.KeyboardLayoutSwitcher {
                id: layoutSwitcher
                anchors.fill: parent
                anchors.margins: -6
                acceptedButtons: Qt.LeftButton
                hoverEnabled: true
            }
        }

        // Volume/brightness OSD while locked (stock Plasma component)
        Loader {
            z: 2
            active: root.viewVisible
            source: "LockOsd.qml"
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 40
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

    Component.onCompleted: {
        passwordField.input.forceActiveFocus();
        authenticator.startAuthenticating();
    }
}
