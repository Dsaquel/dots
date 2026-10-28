import QtQuick
import qs.core
import qs.kit

Item {
    id: d

    property real open: 1
    property real sweep: -1
    property real glint: -100000
    property bool live: false
    property string side: "left"
    property vector4d rect: Qt.vector4d(0, 0, 0, 0)

    readonly property bool search: d.side === "left"
    readonly property string stone: Assets.url("wings/skin/" + Theme.world + "/" + d.side + "-drop.png")
    readonly property bool skinned: d.stone !== ""
    readonly property real ignite: Math.max(0, Math.min(1, (d.open - 0.42) / 0.37))
    readonly property real on: d.ignite * d.ignite * (3 - 2 * d.ignite)
    readonly property real burst: Math.pow(Math.sin(Math.PI * d.ignite), 2)

    property real found: Rite.results.length > 0 ? 1 : 0
    Behavior on found { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
    property real flare: 0
    property int typedLength: Rite.query.length
    property int lastLength: Rite.query.length
    property real breath: 0

    readonly property real body: d.search ? 1 - 0.34 * (1 - d.found) : 1
    readonly property real glow: d.on * (d.search ? 0.16 + 0.5 * d.found + 1.1 * d.flare : 0.2 + 0.22 * d.breath) + 0.95 * d.burst

    width: 34
    height: 33

    onTypedLengthChanged: {
        if (d.search && d.typedLength > d.lastLength)
            flash.restart();
        d.lastLength = d.typedLength;
    }
    SequentialAnimation {
        id: flash
        NumberAnimation { target: d; property: "flare"; to: 1; duration: 70; easing.type: Easing.OutQuad }
        NumberAnimation { target: d; property: "flare"; to: 0; duration: 520; easing.type: Easing.OutCubic }
    }
    SequentialAnimation on breath {
        running: !d.search && d.live
        loops: Animation.Infinite
        NumberAnimation { to: 1; duration: 3200; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 3200; easing.type: Easing.InOutSine }
    }

    Glass {
        anchors.fill: parent
        opacity: d.on
        src: d.stone || Theme.a("sanctum-wing-" + d.side + "-drop.png")
        light: Qt.point(0.5, 0.5)
        radius: 100
        ambient: d.body * (d.skinned ? 1 : 0.531)
        power: d.skinned ? 0 : 0.489 * d.body
        grain: 0
    }
    Glass {
        visible: d.glow > 0.004
        anchors.fill: parent
        src: d.skinned ? Assets.url("wings/skin/" + Theme.world + "/" + d.side + "-drop-glow.png") : Theme.a("sanctum-wing-" + d.side + "-drop-glow.png")
        additive: 1
        light: Qt.point(0.5, 0.5)
        radius: 100
        ambient: d.glow
        power: 0
        grain: 0
    }
}
