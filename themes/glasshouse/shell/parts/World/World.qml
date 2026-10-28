import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

Scope {
    id: part

    required property ShellScreen screen
    readonly property string name: screen.name
    readonly property var out: Stage.of(name)

    signal drawn()
    property bool seen: false
    Connections {
        target: body.Window.window
        enabled: body.ready && !part.seen
        function onFrameSwapped(): void {
            part.seen = true;
            part.drawn();
        }
    }

    function advance(): void {
        const cur = body.world === "light" ? lightLife : darkLife;
        if (body.world !== World.name && cur.level <= 0)
            body.world = World.name;
    }

    Connections {
        target: World
        function onNameChanged(): void {
            part.advance();
        }
    }

    PanelWindow {
        id: base

        screen: part.screen
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "glasshouse-world"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: Theme.ground
        mask: Region {}

        WorldBody {
            id: body
            anchors.fill: parent
            output: part.name
            Component.onCompleted: world = World.name
        }
    }

    component Life: Scope {
        id: w

        required property string world
        readonly property bool on: body.world === w.world && World.name === w.world && body.ready && !body.plain && !Stage.bare
        readonly property var list: part.out ? Stage.fx(part.out.role, w.world) : []
        property real level: 0

        onOnChanged: {
            ramp.stop();
            ramp.to = w.on ? 1 : 0;
            ramp.duration = (w.on ? 900 : 450) * Math.abs(ramp.to - w.level);
            ramp.start();
        }
        onLevelChanged: if (w.level <= 0)
            part.advance()

        readonly property NumberAnimation ramp: NumberAnimation {
            target: w
            property: "level"
            easing.type: Easing.InOutCubic
        }

        LazyLoader {
            active: w.level > 0 && w.list.length > 0 && base.backingWindowVisible

            PanelWindow {
                id: lw

                readonly property rect r: Stage.holdAll(part.name, w.world)

                screen: part.screen
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "glasshouse-life"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                exclusionMode: ExclusionMode.Ignore
                anchors { top: true; left: true }
                margins { top: lw.r.y; left: lw.r.x }
                implicitWidth: lw.r.width
                implicitHeight: lw.r.height
                color: "transparent"
                mask: Region {}

                Item {
                    anchors.fill: parent
                    opacity: w.level

                    Repeater {
                        model: w.list

                        Loader {
                            id: fx

                            required property var modelData

                            Component.onCompleted: setSource(Qt.resolvedUrl(modelData.kind + ".qml"), Stage.props(modelData, part.name, w.world, Qt.point(lw.r.x, lw.r.y)))
                            onLoaded: item.t = part.out ? part.out.t : 0

                            Connections {
                                target: part.out
                                function onTChanged(): void {
                                    if (fx.item)
                                        fx.item.t = part.out.t;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    LazyLoader {
        active: Test.on && Stage.hosted

        PanelWindow {
            screen: part.screen
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "glasshouse-world-host"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            color: Theme.ground
            mask: Region {}

            WorldBody {
                anchors.fill: parent
                output: part.name
                life: true
                fadeMs: 0
            }
        }
    }

    Life {
        id: darkLife
        world: "dark"
    }
    Life {
        id: lightLife
        world: "light"
    }
}
