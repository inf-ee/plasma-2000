// SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
// SPDX-License-Identifier: GPL-3.0-or-later
// Windows 2000 style logon banner. Name and logo come from branding.js,
// written by the installer (see lib/branding.sh).
import QtQuick
import "branding.js" as Branding

Item {
    id: banner
    width: 410
    height: 93

    readonly property string brand: "KDE"
    readonly property string product: Branding.name
    readonly property string version: Branding.version || ""
    // "Plasma" under the name, unless the name already says it
    readonly property string edition: product.indexOf("Plasma") >= 0 ? "" : "Plasma"
    readonly property string tagline: "Built on Linux Technology"
    readonly property string logo: Branding.logo

    Rectangle {
        width: parent.width
        height: 88
        color: "#fcfcfa"

        // soft green/blue glow behind the logo, like the original
        Rectangle {
            x: 30; y: 48
            width: 150; height: 26
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#00c8e6c0" }
                GradientStop { position: 0.25; color: "#c8e6c0" }
                GradientStop { position: 0.6; color: "#c9dff2" }
                GradientStop { position: 1.0; color: "#00fcfcfa" }
            }
        }

        Image {
            id: logoImage
            x: 44; y: 12
            width: 58; height: 58
            visible: banner.logo.length > 0
            source: banner.logo.length === 0 ? "" : banner.logo.startsWith("/") ? "file://" + banner.logo : Qt.resolvedUrl(banner.logo)
            sourceSize: Qt.size(116, 116)
            smooth: true
            mipmap: true
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 8
            y: 7
            text: banner.brand
            font.family: "Liberation Sans"
            font.pixelSize: 12
            font.bold: true
            font.italic: true
            color: "black"
        }

        Item {
            id: wordmark
            x: logoImage.x + logoImage.width + 8
            y: 10
            width: titleRow.width
            height: 76
            // room left of the "KDE" label; long names get a smaller font
            readonly property real room: banner.width - x - 50

            TextMetrics {
                id: titleMetrics
                text: banner.product
                font.family: "Liberation Sans"
                font.pixelSize: 38
                font.bold: true
                font.letterSpacing: -1.5
            }
            TextMetrics {
                id: versionMetrics
                text: banner.version
                font.family: "Liberation Sans"
                font.pixelSize: 26
                font.letterSpacing: -1
            }
            // name + version shrink together when they don't fit
            readonly property real fit: Math.min(1, room / (titleMetrics.width + (banner.version.length > 0 ? 4 + versionMetrics.width : 0)))
            Row {
                id: titleRow
                // a shrunk name sits lower, closer to "Plasma"
                y: (38 - titleText.font.pixelSize) * 0.75
                spacing: 4
                Text {
                    id: titleText
                    text: banner.product
                    font.family: "Liberation Sans"
                    font.pixelSize: Math.max(16, Math.floor(38 * wordmark.fit))
                    font.bold: true
                    font.letterSpacing: -1.5
                    color: "black"
                }
                Text {
                    visible: banner.version.length > 0
                    anchors.baseline: titleText.baseline
                    text: banner.version
                    font.family: "Liberation Sans"
                    font.pixelSize: Math.max(12, Math.floor(26 * wordmark.fit))
                    font.letterSpacing: -1
                    color: "#202020"
                }
            }
            Text {
                id: editionText
                anchors.right: titleRow.right
                y: 36
                text: banner.edition
                font.family: "Liberation Sans"
                font.pixelSize: 25
                font.bold: true
                font.letterSpacing: -1
                color: "black"
            }
            ClassicLabel {
                anchors.right: titleRow.right
                anchors.rightMargin: 16
                y: editionText.y + 27
                text: banner.tagline
                font.pixelSize: 12
            }
        }
    }

    // blue stripe under the banner
    Rectangle {
        y: 88
        width: parent.width
        height: 5
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#013755" }
            GradientStop { position: 0.25; color: "#60a8d9" }
            GradientStop { position: 0.5; color: "#9ec0da" }
            GradientStop { position: 0.75; color: "#60a8d9" }
            GradientStop { position: 1.0; color: "#013755" }
        }
    }
}
