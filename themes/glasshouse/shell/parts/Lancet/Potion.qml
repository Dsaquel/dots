import QtQuick
import qs.core

ShaderEffect {
    id: p

    property string sprite
    readonly property var meta: Anchor.bottle(p.sprite)
    property real level: 0.5
    property real wave: 0
    property real phase: 0
    property real bubbles: 0
    property real time: 0
    property real grey: 0
    property real warm: 0
    property real swirl: 0
    property real cloud: 0
    property real boost: 0
    property real wash: 0
    property color washColor: "white"
    readonly property real vTop: p.meta ? p.meta.itop : 0.3
    readonly property real paintTop: p.meta ? p.meta.top : 0.3
    readonly property real vBottom: p.meta ? p.meta.bottom : 0.95
    readonly property real aspect: p.width / Math.max(1, p.height)
    readonly property real texelV: 1 / Math.max(1, p.height)
    readonly property string base: p.sprite ? Assets.url("potions/lancet/" + p.sprite + "-full.png").replace(/-full\.png$/, "") : ""
    property variant fullTex: Image {
        source: p.base ? p.base + "-full.png" : ""
        smooth: true
        mipmap: true
        visible: false
    }
    property variant emptyTex: Image {
        source: p.base ? p.base + "-empty.png" : ""
        smooth: true
        mipmap: true
        visible: false
    }
    property variant maskTex: Image {
        source: p.base ? p.base + "-liquid.png" : ""
        smooth: true
        mipmap: true
        visible: false
    }

    visible: !!p.meta && p.base !== ""
    fragmentShader: Qt.resolvedUrl("../../shaders/liquid.frag.qsb")
}
