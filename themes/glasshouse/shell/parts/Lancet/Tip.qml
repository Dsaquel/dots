import QtQuick
import qs.core
import qs.kit

Item {
    id: t

    property var info: null
    property bool shown: false
    property string edge: "left"
    property real aim: height / 2
    readonly property bool hasIcons: !!t.info && !!t.info.icons && t.info.icons.length > 0
    readonly property color gold: Theme.dark ? Theme.rare : Theme.sun

    width: Math.ceil(Math.max(col.implicitWidth + 30, 96))
    height: Math.ceil(col.implicitHeight + 20)
    property bool born: false
    opacity: t.shown && t.born ? 1 : 0
    visible: opacity > 0.01
    Component.onCompleted: t.born = true
    transform: Translate { x: (1 - t.opacity) * (t.edge === "left" ? -10 : 10) }
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    BorderImage {
        anchors.fill: parent
        anchors.margins: -16
        anchors.topMargin: -12
        anchors.bottomMargin: -22
        source: Theme.shared("lancet-shadow.png")
        border { left: 30; right: 30; top: 30; bottom: 30 }
    }
    Nine {
        anchors.fill: parent
        name: "lancet-tip"
        border: 10
        power: 0.3
        ambient: Theme.dark ? 0.66 : 0.74
        light: Qt.point(t.edge === "left" ? 0.08 : 0.92, 0.2)
    }
    BorderImage {
        id: giltBI
        visible: false
        anchors.fill: parent
        source: Theme.a("lancet-tip-gilt.png")
        border { left: 12; right: 12; top: 12; bottom: 12 }
    }
    ShaderEffectSource {
        id: giltSrc
        sourceItem: giltBI
        hideSource: true
        visible: false
    }
    Gilt {
        visible: !Theme.dark
        anchors.fill: parent
        heightMap: giltSrc
        lx: 0.2
        ly: -0.6
        depth: 3
    }

    Piece {
        name: "lancet-jewel"
        width: 16
        height: 16
        x: t.edge === "left" ? -8 : t.width - 8
        y: Math.round(Math.max(4, Math.min(t.height - 20, t.aim - 8)))
        power: 0.7
        ambient: 0.75
        glow: 0.55
        light: Qt.point(0.4, 0.3)
    }

    Column {
        id: col
        x: 15
        y: 10
        spacing: 4
        Row {
            spacing: 10
            Text {
                id: label
                y: value.visible ? value.baselineOffset - label.baselineOffset : 0
                text: t.info ? t.info.label : ""
                font.family: Theme.caps
                font.pixelSize: 10
                font.letterSpacing: Theme.capsTracking
                font.weight: Font.DemiBold
                color: t.info && t.info.alert ? Theme.alert : t.gold
            }
            Text {
                id: value
                visible: text !== ""
                text: t.info ? t.info.value : ""
                font.family: t.info && t.info.word ? Theme.ui : Theme.numerals
                font.weight: t.info && t.info.word ? Font.DemiBold : Font.Normal
                font.pixelSize: t.info && t.info.word ? 16 : 20
                font.features: { "lnum": 1, "tnum": 1 }
                font.variableAxes: Theme.dark || (t.info && t.info.word) ? ({}) : ({ "wght": 560, "opsz": 20 })
                color: Theme.ink
                renderType: Text.CurveRendering
            }
        }
        Text {
            visible: text !== ""
            width: Math.min(implicitWidth, 250)
            text: t.info && t.info.detail ? t.info.detail : ""
            font.family: Theme.ui
            font.pixelSize: 12
            color: Theme.inkSoft
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
        Row {
            visible: t.hasIcons
            spacing: 6
            topPadding: 2
            Repeater {
                model: t.hasIcons ? t.info.icons : []
                Image {
                    required property string modelData
                    visible: status !== Image.Error
                    width: 22
                    height: 22
                    sourceSize: Qt.size(44, 44)
                    source: modelData
                    smooth: true
                    mipmap: true
                }
            }
        }
    }
}
