// SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
// SPDX-License-Identifier: GPL-3.0-or-later
// Icon copied from the SE98 icon theme (icons/<name>-<px>.png, see icons/SOURCE.txt),
// drawn at `size` logical px. 48px art is used for 32px icons so it is sharp at 1.5x.
import QtQuick

Image {
    property string name
    property int size: 32
    width: size
    height: size
    source: Qt.resolvedUrl("icons/" + name + "-48.png") // 48px art, drawn at 32 logical px (sharp at 1.5x)
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
}
