import QtQuick
import qs.core
import qs.kit

Item {
    id: c

    property AppInfo app
    property point light: Qt.point(0.3, -2)
    property real glow: 0.5
    readonly property real s: 52

    width: c.s
    height: c.s

    Glass {
        anchors.fill: parent
        src: Theme.a("chrome-crest-glow.png")
        additive: 1
        ambient: 0
        power: c.glow * 0.55
        radius: 3
        light: Qt.point(0.42, 0.38)
        grain: 0
    }
    Glass {
        anchors.fill: parent
        src: Theme.a("chrome-crest.png")
        light: Qt.point(0.4, 0.34)
        power: 0.2 + 0.3 * c.glow
        ambient: 0.52
        radius: 1.2
    }
    Lead {
        anchors.fill: parent
        src: Theme.a("chrome-crest-lead.png")
        lx: c.light.x
        ly: c.light.y
        lightZ: 1.4
    }
    Loader {
        anchors.fill: parent
        sourceComponent: Theme.dark ? silver : gilt
        Component {
            id: gilt
            Gilt {
                src: Theme.a("chrome-crest-gilt.png")
                lx: c.light.x
                ly: c.light.y
                depth: 3
            }
        }
        Component {
            id: silver
            Metal {
                src: Theme.a("chrome-crest-gilt.png")
                base: "#9aa3c8"
                hi: "#f2f0ff"
                low: "#141626"
                sky: "#c9d1ee"
                metal: 0.8
                shininess: 40
                depth: 3
                lx: c.light.x
                ly: c.light.y
            }
        }
    }

    Item {
        id: mark
        width: 44
        height: 44
        Image {
            anchors.fill: parent
            anchors.margins: 2
            visible: c.app && c.app.icon !== ""
            source: c.app ? c.app.icon : ""
            sourceSize: Qt.size(48, 48)
            smooth: true
            mipmap: true
            asynchronous: true
        }
        Text {
            anchors.centerIn: parent
            visible: c.app && c.app.icon === ""
            text: c.app ? (c.app.glyph !== "" ? c.app.glyph : c.app.monogram) : ""
            font.family: c.app && c.app.glyph !== "" ? Theme.glyphs : Theme.caps
            font.pixelSize: c.app && c.app.glyph !== "" ? 30 : 30
            font.weight: Font.Bold
            color: "white"
            renderType: Text.CurveRendering
        }
    }
    ShaderEffectSource {
        id: markSrc
        sourceItem: mark
        hideSource: true
        smooth: true
        mipmap: true
        visible: false
    }
    ShaderEffect {
        anchors.centerIn: parent
        width: 22
        height: 22
        property variant src: markSrc
        property vector2d texel: Qt.vector2d(1 / 44, 1 / 44)
        property color base: Theme.dark ? "#c7cbe6" : "#e9c47e"
        property color hi: Theme.dark ? "#ffffff" : "#fff6dc"
        property color low: Theme.dark ? "#3a3f66" : "#6a4320"
        property point light: Qt.point(0.25, 0.1)
        property real depth: 3.2
        property real detail: 0.35
        fragmentShader: Qt.resolvedUrl("../../shaders/emblem.frag.qsb")
    }
}
