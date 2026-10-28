import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.kit

Item {
    id: win

    property real t: 0
    property bool ready: false
    readonly property bool settled: win.ready && Rite.opened && win.t >= 1
    function ph(a: real, b: real): real {
        return Math.max(0, Math.min(1, (win.t - a) / (b - a)));
    }
    function out3(x: real): real {
        return 1 - Math.pow(1 - x, 3);
    }
    function io3(x: real): real {
        return x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2;
    }
    readonly property bool sweeping: Rite.opened && win.t > 0.36 && win.t < 1
    readonly property real sweep: win.sweeping ? -0.35 + 1.95 * win.io3(win.ph(0.36, 1)) : -1
    readonly property real glint: win.sweeping ? -260 + 2950 * win.io3(win.ph(0.36, 1)) : -100000

    NumberAnimation {
        id: opening
        target: win
        property: "t"
        to: 1
        duration: Theme.menuOpenMs * (1 - win.t)
        easing.type: Easing.Linear
    }
    NumberAnimation {
        id: closing
        target: win
        property: "t"
        to: 0
        duration: Theme.menuCloseMs * win.t
        easing.type: Easing.Linear
        onFinished: Rite.shown = false
    }
    property real madeAt: Date.now()
    property real readyAt: 0
    function begin(): void {
        if (win.ready)
            return;
        win.readyAt = Date.now();
        win.ready = true;
        Sfx.play("sanctum-open");
        opening.start();
    }
    Timer {
        id: late
        interval: 120
        running: true
        onTriggered: win.begin()
    }
    Connections {
        target: Rite
        function onOpenedChanged(): void {
            if (Rite.opened) {
                closing.stop();
                if (win.ready) {
                    Sfx.play("sanctum-open");
                    opening.start();
                }
            } else {
                opening.stop();
                Sfx.play("sanctum-close");
                closing.start();
            }
        }
    }

    Connections {
        target: win.Window.window
        enabled: win.ready && Rite.firstFrame < 0
        function onFrameSwapped(): void {
            Rite.firstFrame = Date.now() - Rite.askedAt;
            if (Test.on)
                console.log("sanctum: first frame " + Date.now() + " (" + Rite.firstFrame + " ms after the ask; window made +" + (win.madeAt - Rite.askedAt) + ", frozen frame +" + (win.readyAt - Rite.askedAt) + ")");
        }
    }

    Backdrop {
        id: backdrop
        anchors.fill: parent
        screen: Rite.screenObj
        shown: win.out3(win.ph(0, 0.5))
        onReadyChanged: if (ready)
            win.begin()
    }

    Item {
        id: stage
        width: Screens.design.width
        height: Screens.design.height
        anchors.centerIn: parent
        scale: Screens.fit(win.width, win.height)
        visible: win.ready

        MouseArea {
            anchors.fill: parent
            enabled: Rite.opened
            onClicked: Rite.close()
        }

        Centre {
            x: 580
            y: 0
            rise: win.out3(win.ph(0, 0.78))
            herRise: win.out3(win.ph(0.08, 0.92))
            bloom: win.ph(0.22, 0.62) * (1 + 0.45 * (1 - win.out3(win.ph(0.62, 1))))
            sweep: win.sweep
            glint: win.glint
            turning: win.settled
        }
        Edge {
            wing: left
        }
        Edge {
            wing: right
        }
        Wing {
            id: left
            side: "left"
            motto: Theme.dark ? "" : "SOLVE"
            open: win.io3(win.ph(0.04, 0.82))
            t: win.t
            sweep: win.sweep
            glint: win.glint
            cached: win.settled
            live: win.settled
            glyph: "\u{f003b}"
            rose: Theme.dark ? drop : flower
            Apps {}
        }
        Wing {
            id: right
            side: "right"
            motto: Theme.dark ? "" : "COAGULA"
            open: win.io3(win.ph(0.04, 0.82))
            t: win.t
            sweep: win.sweep
            glint: win.glint
            cached: win.settled
            live: win.settled
            glyph: "\u{f0ae2}"
            rose: Theme.dark ? drop : flower
            Today {}
        }
        Component {
            id: flower
            Rose {}
        }
        Component {
            id: drop
            Drop {}
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (Rite.opened && Rite.keyEvent(event))
                event.accepted = true;
        }
    }
}
