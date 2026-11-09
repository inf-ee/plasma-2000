// SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
// SPDX-License-Identifier: GPL-3.0-or-later
// Draws a small bitmap from rows of characters, one char per pixel.
import QtQuick

Canvas {
    id: art
    property var rows: []
    property var palette: ({})
    property int pixel: 2

    width: (rows.length ? rows[0].length : 0) * pixel
    height: rows.length * pixel
    antialiasing: false
    renderStrategy: Canvas.Immediate

    onRowsChanged: requestPaint()
    onPaletteChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        for (let y = 0; y < rows.length; y++) {
            for (let x = 0; x < rows[y].length; x++) {
                const color = palette[rows[y][x]];
                if (color) {
                    ctx.fillStyle = color;
                    ctx.fillRect(x * pixel, y * pixel, pixel, pixel);
                }
            }
        }
    }
}
