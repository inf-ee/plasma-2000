/*
    Windows 2000 style "Shut Down" dialog for Plasma's logout screen
    (ksmserver-logout-greeter). Same interface as Breeze's Logout.qml:
    context properties sdtype, maysd, canLogout, spdMethods,
    softwareUpdatePending, screenGeometry; signals below.

    SPDX-FileCopyrightText: 2014 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
    SPDX-FileCopyrightText: 2026 Dmitrii Shaburov

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.coreaddons as KCoreAddons
import org.kde.plasma.private.sessions
import "timer.js" as AutoTriggerTimer
import "branding.js" as Branding

Item {
    id: root
    height: screenGeometry.height
    width: screenGeometry.width

    signal logoutRequested()
    signal haltRequested()
    signal haltUpdateRequested()
    signal suspendRequested(int spdMethod)
    signal rebootRequested()
    signal rebootRequested2(int opt)
    signal rebootUpdateRequested()
    signal cancelRequested()
    signal lockScreenRequested()
    signal cancelSoftwareUpdateRequested()

    function sleepRequested() { root.suspendRequested(2); }
    function hibernateRequested() { root.suspendRequested(4); }

    // When a specific action was asked for (e.g. "Restart" in the menu), Plasma
    // expects it to happen by itself after a timeout unless cancelled.
    readonly property bool showAllOptions: sdtype === ShutdownType.ShutdownTypeDefault
    property real timeout: 30
    property real remainingTime: timeout
    // false while Component.onCompleted preselects the action, so that doesn't count as user input
    property bool ready: false
    readonly property string requestedKey: {
        switch (sdtype) {
        case ShutdownType.ShutdownTypeReboot: return softwareUpdatePending ? "reboot-update" : "reboot";
        case ShutdownType.ShutdownTypeHalt: return softwareUpdatePending ? "halt-update" : "halt";
        // anything else (ShutdownTypeNone, ShutdownTypeLogout, future values): the least drastic action
        default: return "logout";
        }
    }

    function run(key) {
        switch (key) {
        case "logout": root.logoutRequested(); break;
        case "halt": root.haltRequested(); break;
        case "halt-update": root.haltUpdateRequested(); break;
        case "reboot": root.rebootRequested(); break;
        case "reboot-update": root.rebootUpdateRequested(); break;
        case "suspend": root.sleepRequested(); break;
        case "hibernate": root.hibernateRequested(); break;
        }
    }

    function confirm() {
        if (actions.count > 0 && actionCombo.currentIndex >= 0) {
            run(actions.get(actionCombo.currentIndex).key);
        }
    }

    function stopCountdown() {
        AutoTriggerTimer.cancelAutoTrigger();
    }

    KCoreAddons.KUser { id: kuser }

    ListModel { id: actions }

    Component.onCompleted: {
        if (canLogout) {
            actions.append({ key: "logout", name: "Log off " + kuser.loginName,
                text: "Ends your session, leaving the computer running on full power." });
        }
        if (maysd) {
            actions.append({ key: "halt", name: "Shut down",
                text: "Ends your session and shuts down the computer so that you can safely turn off power." });
            actions.append({ key: "reboot", name: "Restart",
                text: "Ends your session, shuts down the computer, and starts it again." });
            if (softwareUpdatePending) {
                actions.append({ key: "halt-update", name: "Install updates and shut down",
                    text: "Installs the pending software updates, then shuts down the computer." });
                actions.append({ key: "reboot-update", name: "Install updates and restart",
                    text: "Installs the pending software updates, then restarts the computer." });
            }
        }
        if (spdMethods.SuspendState) {
            actions.append({ key: "suspend", name: "Stand by",
                text: "Maintains your session, keeping the computer running on low power with data still in memory." });
        }
        if (spdMethods.HibernateState) {
            actions.append({ key: "hibernate", name: "Hibernate",
                text: "Saves your session to disk so that you can safely turn off power. Your session is restored the next time you start the computer." });
        }
        for (let i = 0; i < actions.count; i++) {
            if (actions.get(i).key === root.requestedKey) {
                actionCombo.currentIndex = i;
                break;
            }
        }
        actionCombo.forceActiveFocus();
        ready = true;
    }

    onRemainingTimeChanged: {
        if (remainingTime <= 0) {
            run(requestedKey);
        }
    }

    Timer {
        id: countDownTimer
        running: !root.showAllOptions
        repeat: true
        interval: 1000
        onTriggered: root.remainingTime--
        Component.onCompleted: {
            AutoTriggerTimer.addCancelAutoTriggerCallback(function() {
                countDownTimer.running = false;
            });
        }
    }

    // Win2000 didn't dim the screen; just swallow clicks outside the dialog.
    MouseArea {
        anchors.fill: parent
        onPressed: root.stopCountdown()
    }

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            root.stopCountdown();
            if (event.key === Qt.Key_Escape) {
                if (actionCombo.open) {
                    actionCombo.open = false;
                } else {
                    root.cancelRequested();
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (actionCombo.open) {
                    actionCombo.open = false;
                } else {
                    root.confirm();
                }
                event.accepted = true;
            }
        }

        ClassicWindow {
            id: dialog
            title: "Shut Down " + Branding.name
            closable: false
            padding: 0
            anchors.centerIn: parent

            Column {
                width: 410

                Banner {}

                Item {
                    z: 1 // keeps the open drop-down list above the rows below
                    width: parent.width
                    height: description.y + description.height + 16

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
                        width: 260; height: 20
                        model: actions
                        nameRole: "name"
                        // only the user's choice stops the countdown: on several screens the views share
                        // timer.js, and another screen's preselection must not stop this one
                        onCurrentIndexChanged: if (root.ready) root.stopCountdown()
                    }
                    ClassicLabel {
                        id: description
                        x: 60; y: 66
                        width: 330
                        wrapMode: Text.WordWrap
                        text: actions.count > actionCombo.currentIndex && actionCombo.currentIndex >= 0
                              ? actions.get(actionCombo.currentIndex).text : ""
                    }
                }

                ClassicLabel {
                    x: 60
                    width: 330
                    visible: countDownTimer.running
                    wrapMode: Text.WordWrap
                    text: {
                        const s = Math.max(0, Math.ceil(root.remainingTime));
                        switch (root.requestedKey) {
                        case "reboot": case "reboot-update": return "Restarting automatically in " + s + " seconds.";
                        case "halt": case "halt-update": return "Shutting down automatically in " + s + " seconds.";
                        default: return "Logging off automatically in " + s + " seconds.";
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 23 + 24
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        ClassicButton {
                            text: "OK"
                            isDefault: true
                            onClicked: root.confirm()
                        }
                        ClassicButton {
                            text: "Cancel"
                            onClicked: root.cancelRequested()
                        }
                    }
                }
            }
        }
    }
}
