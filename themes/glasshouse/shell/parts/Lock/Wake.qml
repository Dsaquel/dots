import QtQuick
import qs.core
import qs.parts.World

Item {
    id: wake

    required property string output
    readonly property var out: Stage.of(output)
    readonly property real fx: out ? out.farX : 0
    readonly property real fy: out ? out.fy : 0
    readonly property real fw: out ? out.fw : width
    readonly property real fh: out ? out.fh : height
    readonly property string clipUrl: Assets.clip("room-" + World.name + "-wake")
    readonly property bool ready: still.status === Image.Ready || still.source == ""
    property double endAt: -1
    readonly property real into: endAt < 0 ? 0 : Slumber.inOut3(Slumber.span(endAt, 0, 0.6))
    readonly property real settle: endAt < 0 ? 0 : Slumber.inOut3(Slumber.span(endAt, 0.45, 0.7))
    readonly property real fade: endAt < 0 ? 0 : Slumber.inOut3(Slumber.span(endAt, 1.2, 0.4))
    property bool over: false

    signal gone()

    opacity: 1 - fade
    onFadeChanged: if (fade >= 1 && !over) {
        over = true;
        wake.gone();
    }

    function end(): void {
        if (wake.endAt > 0)
            return;
        wake.endAt = Date.now();
        Slumber.busy(1700);
    }

    Item {
        x: wake.fx
        y: wake.fy
        width: wake.fw
        height: wake.fh

        Image {
            id: still
            anchors.fill: parent
            source: Assets.asleep(World.name)
            sourceSize: Qt.size(wake.fw, wake.fh)
            asynchronous: false
            cache: true
            smooth: true
        }
        Loader {
            anchors.fill: parent
            active: wake.clipUrl !== ""
            sourceComponent: Clip {
                source: wake.clipUrl
                from: 0.8
                until: 5.72
                go: Slumber.handAt > 0
                onFinished: wake.end()
            }
        }
    }

    Pose {
        anchors.fill: parent
        output: wake.output
        settle: wake.settle
        opacity: wake.into
        visible: opacity > 0
    }

    Timer {
        running: wake.clipUrl === "" && Slumber.handAt > 0
        interval: 900
        onTriggered: wake.end()
    }
}
