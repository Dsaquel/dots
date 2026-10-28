import QtQuick
import qs.core
import qs.kit

Item {
    id: h

    required property string output
    property bool interactive: true
    property bool signals: true
    property bool lit: h.interactive && (area.containsMouse || (Test.on && Test.hover === "handle"))
    readonly property var geo: Anchor.of(h.output)
    readonly property real unit: Screens.unitOf(h)
    readonly property var hd: h.geo ? h.geo.layout.handle : null
    readonly property bool main: !!h.geo && h.geo.role === "main"
    readonly property string kind: h.main ? "main" : "side"
    readonly property bool urgent: h.signals && Screens.workspaces(h.output).some(ws => ws !== Hypr.activeWs(h.output) && Hypr.wsUrgent(ws))
    readonly property bool unread: h.signals && h.main && Her.unread > 0
    readonly property bool covered: Hypr.on(h.output).some(w => w.fullscreen)
    readonly property point light: Qt.point(0.5, 0.18)
    property real t: 0
    readonly property real pulse: h.urgent ? 0.5 + 0.5 * Math.sin(h.t * 4.5) : 0
    property real hov: h.lit ? 1 : 0
    Behavior on hov {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    property real glint: 0

    function shine(): void {
        shineAnim.restart();
    }
    SequentialAnimation {
        id: shineAnim
        PauseAnimation { duration: 90 }
        NumberAnimation { target: h; property: "glint"; from: 0; to: 1; duration: 140; easing.type: Easing.OutCubic }
        NumberAnimation { target: h; property: "glint"; to: 0; duration: 520; easing.type: Easing.InOutCubic }
    }

    width: h.hd ? h.hd.w : 0
    height: h.hd ? h.hd.h : 0

    Timer {
        interval: 100
        repeat: true
        running: h.visible && h.urgent && !h.covered && !Gauges.idle
        onTriggered: h.t = Date.now() / 1000
    }

    Item {
        id: art
        readonly property real pad: h.hd ? h.hd.pad : 0
        readonly property string name: "lancet-" + h.kind + "-handle"
        x: -art.pad + (h.interactive ? (h.main ? 4 : -4) * h.hov : 0)
        y: -art.pad
        width: h.width + 2 * art.pad
        height: h.height + 2 * art.pad

        Glow {
            anchors.centerIn: parent
            width: 64
            height: 150
            color: h.urgent ? (Theme.dark ? "#ffc23c" : "#ff9a3a") : (Theme.dark ? Theme.lamp : Theme.sun)
            core: 0.2
            intensity: (Theme.dark ? 0.1 : 0.07) + 0.34 * h.hov + 0.16 * h.pulse + 0.6 * h.glint
        }
        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.smooth: true
            layer.mipmap: true
            layer.textureSize: Qt.size(2 * width * h.unit, 2 * height * h.unit)

            Glass {
                anchors.fill: parent
                src: Theme.a(art.name + "-glow.png")
                additive: 1
                ambient: 0
                radius: 2
                grain: 0
                light: h.light
                power: (Theme.dark ? 0.26 : 0.18) + 0.62 * h.hov + 1.1 * h.glint
            }
            Glass {
                anchors.fill: parent
                src: Theme.a(art.name + ".png")
                light: h.light
                radius: 0.9
                power: (Theme.dark ? 0.56 : 0.45) + 0.55 * h.hov
                ambient: (Theme.dark ? 0.8 : 0.78) + 0.26 * h.hov + 0.3 * h.glint
                grain: 0.1
            }
            Metal {
                anchors.fill: parent
                src: Theme.a(art.name + "-lead.png")
                base: Theme.dark ? "#3a3950" : "#3b3470"
                hi: Theme.dark ? "#d6d3f2" : "#c9c0ff"
                low: Theme.dark ? "#06070e" : "#0c0a24"
                sky: Theme.dark ? "#7d88ba" : "#8f86d8"
                metal: 0.45
                shininess: 12
                depth: 2.4
                lx: 0.2
                ly: -0.4
            }
            Metal {
                anchors.fill: parent
                src: Theme.a(art.name + "-gilt.png")
                base: Theme.dark ? Theme.metalBase : "#c99a4e"
                hi: Theme.dark ? Theme.metalHi : "#fff4cf"
                low: Theme.dark ? Theme.metalLow : "#3b2410"
                sky: Theme.dark ? Theme.metalSky : "#f7dfa4"
                metal: Theme.dark ? 0.7 : 1.0
                shininess: Theme.dark ? 30 : 46
                depth: 4.2
                lx: 0.3
                ly: -0.5
            }
        }
        Glow {
            visible: h.urgent
            readonly property real cy: art.pad + (h.hd ? h.hd.jewel.cy : 0)
            x: art.width / 2 - width / 2
            y: cy - height / 2
            width: 30
            height: 30
            color: Theme.dark ? "#ffc23c" : "#ff9a3a"
            core: 0.22
            intensity: 0.55 + 0.75 * h.pulse
        }
        Item {
            visible: h.main
            readonly property var pe: h.hd && h.hd.pearl ? h.hd.pearl : ({ cy: 0, r: 0 })
            x: art.width / 2 - width / 2
            y: art.pad + pe.cy - height / 2
            width: 2 * pe.r
            height: width
            Glow {
                visible: h.unread
                anchors.centerIn: parent
                width: 34
                height: 34
                color: Theme.lamp
                core: 0.25
                intensity: 0.55
            }
            Pearl {
                anchors.fill: parent
                base: h.unread ? Theme.lamp : (Theme.dark ? "#4b4a68" : "#6d63a8")
                hi: h.unread ? "#fff6e8" : (Theme.dark ? "#b9b6dc" : "#d8d0ff")
                low: Theme.dark ? (h.unread ? "#3a2410" : "#07080f") : (h.unread ? "#4a0a2a" : "#120f33")
                sky: h.unread ? (Theme.dark ? "#ffe2b0" : "#ffb8dc") : (Theme.dark ? "#5d6690" : "#8f86d8")
            }
        }
    }

    MouseArea {
        id: area
        x: (h.width - (h.hd ? h.hd.zone : 0)) / 2
        y: -14
        width: h.hd ? h.hd.zone : 0
        height: h.height + 28
        enabled: h.interactive && !!h.geo && h.geo.folded
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Fold.set(h.kind, false)
    }
}
