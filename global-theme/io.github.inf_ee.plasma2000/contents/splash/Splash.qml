// SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
// SPDX-License-Identifier: GPL-3.0-or-later
// Windows 2000 style "Loading your personal settings..." splash for Plasma.
import QtQuick
import "branding.js" as Branding

Rectangle {
    id: root
    color: Classic.desktop

    // set by ksplash: 1 (started) .. 6 (desktop ready)
    property int stage

    ClassicWindow {
        id: dialog
        anchors.centerIn: parent
        title: Branding.name
        closable: false
        padding: 0

        Column {
            width: 410

            Banner {}

            Item {
                width: parent.width
                height: 64
                ClassicLabel {
                    anchors.centerIn: parent
                    text: root.stage >= 4 ? "Applying your personal settings..." : "Loading your personal settings..."
                }
            }
        }
    }
}
