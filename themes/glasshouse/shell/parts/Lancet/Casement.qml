import QtQuick
import qs.core
import qs.kit

Item {
    id: c

    required property var host
    anchors.fill: parent
    layer.enabled: true
    layer.smooth: true
    layer.mipmap: true
    layer.textureSize: Qt.size(2 * width * c.host.unit, 2 * height * c.host.unit)

    Glass {
        anchors.fill: parent
        src: Theme.a("lancet-" + c.host.kind + ".png")
        light: c.host.light
        radius: 0.62
        power: Theme.dark ? 0.56 : 0.5
        ambient: Theme.dark ? 0.72 : 0.78
        grain: 0.14
    }
    Glow {
        visible: c.host.main
        readonly property var rd: c.host.main ? c.host.lay.roundel : ({ cx: 0, cy: 0 })
        x: rd.cx - width / 2
        y: rd.cy - height / 2 - 6
        width: 150
        height: 170
        color: Theme.dark ? Theme.lamp : Theme.sun
        core: 0.3
        intensity: Settings.dnd ? 0.07 : (c.host.activeKey === "her" ? 0.36 : 0.26)
        Behavior on intensity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    }
    Repeater {
        model: c.host.main ? c.host.shelf : []
        Glow {
            required property var modelData
            required property int index
            readonly property var n: c.host.lay.niches[index]
            readonly property bool dark: (modelData.key === "volume" && Gauges.muted) || (modelData.key === "mic" && Gauges.micMuted)
            x: n.x + n.w / 2 - width / 2
            y: n.y + n.h * 0.6 - height / 2
            width: 116
            height: 116
            color: modelData.key === "cpu" && Gauges.cpu > 0.8 ? "#ff9a5c" : modelData.tint
            core: 0.16
            intensity: (c.host.activeKey === modelData.key ? 0.36 : 0.2) * (dark ? 0.4 : 1)
            Behavior on intensity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }
    }
    Roundel {
        host: c.host
    }
    Metal {
        anchors.fill: parent
        src: Theme.a("lancet-" + c.host.kind + "-lead.png")
        base: Theme.dark ? "#3a3950" : "#3b3470"
        hi: Theme.dark ? "#d6d3f2" : "#c9c0ff"
        low: Theme.dark ? "#06070e" : "#0c0a24"
        sky: Theme.dark ? "#7d88ba" : "#8f86d8"
        metal: 0.45
        shininess: 12
        depth: 2.4
        lx: c.host.light.x - 0.3
        ly: c.host.light.y - 0.25
    }
    Metal {
        anchors.fill: parent
        src: Theme.a("lancet-" + c.host.kind + "-gilt.png")
        base: Theme.dark ? Theme.metalBase : "#c99a4e"
        hi: Theme.dark ? Theme.metalHi : "#fff4cf"
        low: Theme.dark ? Theme.metalLow : "#3b2410"
        sky: Theme.dark ? Theme.metalSky : "#f7dfa4"
        metal: Theme.dark ? 0.7 : 1.0
        shininess: Theme.dark ? 30 : 46
        depth: 4.2
        lx: c.host.light.x - 0.2
        ly: c.host.light.y - 0.3
    }
    Repeater {
        model: !Theme.dark && c.host.lay ? c.host.lay.pearls : []
        Pearl {
            required property var modelData
            width: 8
            height: 8
            x: modelData[0] - 4
            y: modelData[1] - 4
        }
    }
}
