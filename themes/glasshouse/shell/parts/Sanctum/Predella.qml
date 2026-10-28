import QtQuick
import QtQuick.Shapes
import qs.core
import qs.kit

Item {
    id: pd

    property real sweep: -1
    property real glint: -100000
    property real stageX: 0
    readonly property var names: ({ lock: "LOCK", logout: "LOG OUT", suspend: "SUSPEND", reboot: "RESTART", shutdown: "SHUT DOWN" })
    readonly property var glyphs: ({ lock: "\u{f033e}", logout: "\u{f0343}", suspend: "\u{f0904}", reboot: "\u{f0709}", shutdown: "\u{f0425}" })
    readonly property string focusKey: Rite.zone === "power" ? Rite.powers[Rite.index] : ""

    width: 320
    height: 64

    Glass {
        anchors.fill: parent
        src: Theme.a("sanctum-predella.png")
        light: Qt.point(0.5, 0.0)
        power: 0.35
        ambient: 0.62
        radius: 0.8
    }
    Iron {
        anchors.fill: parent
        src: Theme.a("sanctum-predella-lead.png")
        lx: 0.4
        ly: -0.6
        rect: Qt.vector4d(pd.stageX, pd.y, pd.width, pd.height)
        glint: pd.glint
    }
    Row {
        x: 16
        y: 8
        spacing: 12
        Repeater {
            model: Rite.powers
            Item {
                id: pw
                required property string modelData
                required property int index
                readonly property bool armed: Rite.armed === pw.modelData
                readonly property bool sel: pd.focusKey === pw.modelData
                width: 48
                height: 48
                Piece {
                    anchors.centerIn: parent
                    width: pw.armed ? 68 : 48
                    height: width
                    name: pw.armed ? "sanctum-power-armed" : "sanctum-power"
                    power: 0.55
                    ambient: pw.armed ? 1.0 : (pw.sel ? 0.9 : 0.62)
                    glow: pw.armed ? 0.7 : 0
                    hasGlow: pw.armed
                    sweep: pd.sweep
                }
                Rectangle {
                    visible: pw.sel && !pw.armed
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.ivory
                }
                Shape {
                    id: drain
                    visible: pw.armed
                    anchors.fill: parent
                    anchors.margins: -4
                    preferredRendererType: Shape.CurveRenderer
                    property real remain: 1
                    ShapePath {
                        strokeColor: Theme.ivory
                        strokeWidth: 2.2
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: drain.width / 2
                            centerY: drain.height / 2
                            radiusX: drain.width / 2 - 1.2
                            radiusY: drain.height / 2 - 1.2
                            startAngle: -90
                            sweepAngle: 360 * drain.remain
                        }
                    }
                    NumberAnimation on remain {
                        running: pw.armed
                        from: 1
                        to: 0
                        duration: 4000
                        easing.type: Easing.Linear
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: pd.glyphs[pw.modelData]
                    font.family: Theme.glyphs
                    font.pixelSize: 19
                    color: pw.armed ? "#ffe9ee" : (Theme.dark ? Theme.rare : Theme.sun)
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        Rite.zone = "power";
                        Rite.index = pw.index;
                    }
                    onClicked: Rite.power(pw.modelData)
                }
            }
        }
    }

    Item {
        visible: pd.focusKey !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        y: -44
        width: label.implicitWidth + 36
        height: 30
        Nine {
            anchors.fill: parent
            name: "sanctum-plaque"
            border: 12
            power: 0.3
            ambient: 0.7
        }
        Text {
            id: label
            anchors.centerIn: parent
            text: Rite.armed ? "PRESS AGAIN TO " + pd.names[Rite.armed] : pd.names[pd.focusKey] || ""
            font.family: Theme.caps
            font.pixelSize: 11
            font.letterSpacing: Theme.capsTracking
            font.weight: Font.DemiBold
            color: Rite.armed ? (Theme.dark ? "#ff9fb4" : "#ffb3bf") : (Theme.dark ? Theme.rare : Theme.sun)
        }
    }
}
