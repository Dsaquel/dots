import QtQuick
import qs.core
import qs.parts.Chat

Item {
    id: s

    property var r: null
    property bool sel: false
    readonly property var e: s.r ? s.r.clip : null
    readonly property string kind: s.e ? s.e.kind : ""
    readonly property color gold: Theme.dark ? Theme.rare : Theme.sun
    readonly property color lead: Theme.dark ? "#0b0c1a" : "#caa36a"
    readonly property color jewel: s.e ? Theme.jewels[Number(s.e.id) % 5] : "transparent"

    function tone(t: string): color {
        return t.length === 9 ? "#" + t.slice(7, 9) + t.slice(1, 7) : t;
    }

    Rectangle {
        visible: s.kind === "text"
        x: 22 - width / 2
        y: s.height / 2 - height / 2
        width: 9
        height: 9
        rotation: 45
        antialiasing: true
        border.width: 1.2
        border.color: s.lead
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.lighter(s.jewel, 1.35)
            }
            GradientStop {
                position: 1
                color: s.jewel
            }
        }
    }
    Rectangle {
        visible: s.kind === "colour"
        x: 22 - width / 2
        y: s.height / 2 - height / 2
        width: 15
        height: 15
        radius: 7.5
        antialiasing: true
        color: s.kind === "colour" ? s.tone(s.e.text) : "transparent"
        border.width: 1.5
        border.color: s.lead
    }
    Text {
        visible: s.kind === "link" || s.kind === "path" || s.kind === "image"
        x: 22 - width / 2
        anchors.verticalCenter: parent.verticalCenter
        text: ({ link: "\u{f0339}", path: "\u{f0256}", image: "\u{f0976}" })[s.kind] || ""
        font.family: Theme.glyphs
        font.pixelSize: 16
        color: s.sel ? "#7d5fae" : s.gold
    }

    Text {
        visible: !!s.e && !s.e.image
        x: 44
        width: s.width - 44 - (s.sel ? 42 : 16)
        anchors.verticalCenter: parent.verticalCenter
        text: s.e && !s.e.image ? s.e.text : ""
        elide: Text.ElideRight
        maximumLineCount: 1
        font.family: Theme.mono
        font.pixelSize: 14
        font.features: { "liga": 0, "clig": 0, "calt": 0, "dlig": 0 }
        color: s.sel ? Theme.inkOnLight : Theme.ink
        renderType: Text.NativeRendering
    }
    Loader {
        id: strip
        active: !!s.e && s.e.image
        x: 44
        width: 112
        height: 34
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: Item {
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1.5
                radius: 3
                color: Theme.dark ? "#0b0e22" : "#14165a"
            }
            Image {
                anchors.fill: parent
                anchors.margins: 2
                source: s.r && s.r.thumb ? s.r.thumb : ""
                sourceSize: Qt.size(224, 68)
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
            }
            Pane {
                x: -4
                y: -3
                width: 120
                height: 44
                pane: Qt.vector4d(4, 3, 112, 34)
                radius: 4
                rim: 2.2
                hollow: 1
                shadow: 0.4
                lightPos: Qt.vector2d(0, 0)
                lightRadius: 80
            }
        }
    }
    Text {
        visible: !!s.e && s.e.image
        x: strip.x + strip.width + 14
        anchors.verticalCenter: parent.verticalCenter
        text: s.e && s.e.image ? s.e.w + " × " + s.e.h + "  ·  " + s.e.ext.toUpperCase() + "  ·  " + s.e.size : ""
        font.family: Theme.ui
        font.pixelSize: 13
        font.features: { "lnum": 1, "tnum": 1 }
        color: s.sel ? "#4a3f63" : Theme.inkSoft
        renderType: Text.NativeRendering
    }

    Text {
        visible: s.sel
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: "\u{f0311}"
        font.family: Theme.glyphs
        font.pixelSize: 17
        color: "#7d5fae"
    }
}
