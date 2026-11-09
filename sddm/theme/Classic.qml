// SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
// SPDX-License-Identifier: GPL-3.0-or-later
// Windows 2000 palette and fonts.
pragma Singleton

import QtQuick

QtObject {
    readonly property color desktop: "#3a6ea5"
    readonly property color face: "#d4d0c8"
    readonly property color light: "#d4d0c8"
    readonly property color highlight: "#ffffff"
    readonly property color shadow: "#808080"
    readonly property color darkShadow: "#404040"
    readonly property color titleStart: "#0a246a"
    readonly property color titleEnd: "#a6caf0"
    readonly property color inactiveTitleStart: "#808080"
    readonly property color inactiveTitleEnd: "#c0c0c0"
    readonly property color inactiveTitleText: "#d4d0c8"
    readonly property color selection: "#0a246a"

    // Wine's Tahoma clone (LGPL, see COPYING.LIB-tahoma), bundled next to this file.
    property FontLoader regular: FontLoader { source: Qt.resolvedUrl("tahoma.ttf") }
    property FontLoader bold: FontLoader { source: Qt.resolvedUrl("tahomabd.ttf") }
    readonly property string fontFamily: regular.status === FontLoader.Ready ? regular.name : "Liberation Sans"
    readonly property int fontPx: 11

}
