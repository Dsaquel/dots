import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.core
import qs.parts.World
import qs.parts.Chat

Scope {
    id: part

    LazyLoader {
        active: Slumber.engaged && Slumber.shown && !Slumber.real

        Variants {
            model: Screens.list

            PanelWindow {
                id: pw

                required property ShellScreen modelData

                screen: modelData
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "glasshouse-lock"
                WlrLayershell.keyboardFocus: Test.on ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
                exclusionMode: ExclusionMode.Ignore
                anchors { top: true; bottom: true; left: true; right: true }
                color: Theme.ground
                mask: Test.on ? empty : null

                Region {
                    id: empty
                }

                LockBody {
                    anchors.fill: parent
                    output: pw.modelData.name
                }
                KeyCatch {
                    anchors.fill: parent
                    enabled: !Test.on
                }
            }
        }
    }

    LazyLoader {
        active: !Test.on && Slumber.real && Slumber.engaged

        WlSessionLock {
            id: session
            locked: Slumber.shown

            onLockStateChanged: {
                if (!session.locked && Slumber.real && Slumber.engaged && !Slumber.releasing)
                    Slumber.lost();
            }
            onSecureStateChanged: console.log("lock: the session is", session.secure ? "locked (secure)" : "not secure")

            WlSessionLockSurface {
                id: surface
                color: Theme.ground

                LockBody {
                    anchors.fill: parent
                    output: surface.screen ? surface.screen.name : ""
                }
                KeyCatch {
                    anchors.fill: parent
                    enabled: true
                }
            }
        }
    }

    LazyLoader {
        active: Slumber.releasing && Slumber.shattering

        Variants {
            model: Screens.list

            PanelWindow {
                id: sw

                required property ShellScreen modelData
                readonly property bool main: Screens.role(modelData.name) === "main"
                readonly property var mains: Screens.list.filter(sc => Screens.role(sc.name) === "main")
                readonly property point impact: {
                    const w = sw.modelData.width, h = sw.modelData.height;
                    if (sw.main)
                        return Slumber.fieldAt;
                    const m = sw.mains.length ? sw.mains[0] : null;
                    if (!m)
                        return Qt.point(w / 2, h / 2);
                    const gx = m.x + Slumber.fieldAt.x, gy = m.y + Slumber.fieldAt.y;
                    return Qt.point(Math.max(0, Math.min(w, gx - sw.modelData.x)), Math.max(0, Math.min(h, gy - sw.modelData.y)));
                }

                screen: modelData
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "glasshouse-lock-shatter"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                exclusionMode: ExclusionMode.Ignore
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"
                mask: Region {}

                property bool told: false
                readonly property bool drawn: sw.backingWindowVisible && shards.ready
                onDrawnChanged: if (sw.drawn && !sw.told) {
                    sw.told = true;
                    Slumber.readyOne();
                }

                Shards {
                    id: shards
                    anchors.fill: parent
                    output: sw.modelData.name
                    impact: sw.impact
                }
            }
        }
    }

    LazyLoader {
        active: Slumber.engaged && Slumber.hasMain && (Slumber.awake || Slumber.releasing) && !Slumber.wakeDone

        Variants {
            model: Screens.list.filter(sc => Screens.role(sc.name) === "main")

            PanelWindow {
                id: ww

                required property ShellScreen modelData

                screen: modelData
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "glasshouse-lock-wake"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                exclusionMode: ExclusionMode.Ignore
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"
                mask: Region {}

                property bool told: false
                readonly property bool drawn: ww.backingWindowVisible && wake.ready && Slumber.releasing
                onDrawnChanged: if (ww.drawn && !ww.told) {
                    ww.told = true;
                    Slumber.readyOne();
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.ground
                    opacity: wake.opacity
                }
                Wake {
                    id: wake
                    anchors.fill: parent
                    output: ww.modelData.name
                    onGone: Slumber.wakeGone()
                }
            }
        }
    }

    LazyLoader {
        active: Slumber.dim > 0.002

        Variants {
            model: Screens.list

            PanelWindow {
                id: dw

                required property ShellScreen modelData
                readonly property bool main: Screens.role(modelData.name) === "main"
                readonly property var out: Stage.of(modelData.name)
                readonly property point keep: dw.main && dw.out ? (Theme.dark ? Qt.point(dw.out.farX + 1328 * dw.out.s, dw.out.fy + 466 * dw.out.s) : Qt.point(dw.out.farX + 1180 * dw.out.s, dw.out.fy + 420 * dw.out.s)) : Qt.point(width * 0.5, height * 0.45)

                screen: modelData
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "glasshouse-lock-dim"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                exclusionMode: ExclusionMode.Ignore
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"
                mask: Region {}

                Shape {
                    anchors.fill: parent
                    opacity: Slumber.dim
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeWidth: 0
                        strokeColor: "transparent"
                        fillGradient: RadialGradient {
                            centerX: dw.keep.x
                            centerY: dw.keep.y
                            centerRadius: Math.max(dw.width, dw.height) * 0.95
                            focalX: dw.keep.x
                            focalY: dw.keep.y
                            GradientStop { position: 0.0; color: Qt.rgba(0.04, 0.05, 0.12, Theme.dark ? 0.22 : 0.16) }
                            GradientStop { position: 0.45; color: Qt.rgba(0.04, 0.05, 0.12, Theme.dark ? 0.42 : 0.3) }
                            GradientStop { position: 1.0; color: Qt.rgba(0.03, 0.04, 0.1, Theme.dark ? 0.6 : 0.46) }
                        }
                        PathRectangle {
                            x: 0
                            y: 0
                            width: dw.width
                            height: dw.height
                        }
                    }
                }
            }
        }
    }

    property string bakeDir: ""
    LazyLoader {
        active: Test.on && part.bakeDir !== ""

        Variants {
            model: Screens.list

            PanelWindow {
                id: bw

                required property ShellScreen modelData
                readonly property string role: Screens.role(modelData.name)

                screen: modelData
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "glasshouse-lock-bake"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                exclusionMode: ExclusionMode.Ignore
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"
                mask: Region {}

                LockBody {
                    id: baked
                    anchors.fill: parent
                    output: bw.modelData.name
                    bake: true
                }
                Timer {
                    running: true
                    interval: 2500
                    onTriggered: baked.grabToImage(result => {
                        const file = part.bakeDir + "/lock-hyprlock-" + bw.role + ".png";
                        console.log("lock: baked", file, result.saveToFile(file));
                    })
                }
            }
        }
    }

    property bool warming: false
    Timer {
        running: true
        interval: Math.max(2500, 9000 - (Date.now() - Quickshell.launchTime.getTime()))
        onTriggered: part.warming = Assets.clip("room-" + World.name + "-sleep") !== ""
    }
    LazyLoader {
        active: part.warming
        Warm {
            source: Assets.clip("room-" + World.name + "-sleep")
            onWarmed: part.warming = false
        }
    }
    Item {
        visible: false
        readonly property var mainOut: {
            const m = Screens.list.find(sc => Screens.role(sc.name) === "main");
            return m ? Stage.of(m.name) : null;
        }
        readonly property size frame: mainOut ? Qt.size(mainOut.fw, mainOut.fh) : Qt.size(Math.round(Screens.design.width * Stage.k), Math.round(Math.round(Screens.design.width * Stage.k) * 9 / 16))
        Repeater {
            model: {
                if (!Assets.ready)
                    return [];
                const m = Screens.list.find(sc => Screens.role(sc.name) === "main");
                const sd = Screens.list.find(sc => Screens.role(sc.name) === "side");
                const main = m ? Stage.layers(m.name, World.name) : {};
                const side = sd ? Stage.layers(sd.name, World.name) : {};
                return [main.deep, main.plate, Assets.asleep(World.name), side.plate].filter(u => !!u);
            }
            Image {
                required property string modelData
                source: modelData
                sourceSize: parent.frame
                asynchronous: true
                cache: true
            }
        }
    }

    readonly property string rule: "hl.layer_rule({ name = \"glasshouse-lock\", match = { namespace = \"^glasshouse-lock\" }, no_anim = true })"
    function install(): void {
        Hypr.dispatch("function() " + part.rule + " end");
    }
    Connections {
        target: Hyprland
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "configreloaded")
                part.install();
        }
    }
    Component.onCompleted: part.install()

    Connections {
        target: Bus
        function onLockPreview(): void {
            Slumber.begin(false, "");
        }
    }

    property var typing: []
    Timer {
        id: typist
        interval: 115
        repeat: true
        running: part.typing.length > 0
        onTriggered: {
            const next = part.typing[0];
            part.typing = part.typing.slice(1);
            part.press(next);
        }
    }
    function press(name: string): void {
        const keys = { escape: Qt.Key_Escape, backspace: Qt.Key_Backspace, enter: Qt.Key_Return, space: Qt.Key_Space };
        if (keys[name] !== undefined)
            Slumber.key(keys[name], name === "space" ? " " : "", 0);
        else if (name.length > 0)
            Slumber.key(0, name, 0);
    }

    IpcHandler {
        target: "lock"

        function now(): void {
            Slumber.lockNow();
        }
        function preview(world: string): void {
            if (!Slumber.engaged)
                Slumber.begin(false, world);
        }
        function previewPassword(text: string): void {
            if (Test.on && Slumber.engaged)
                part.typing = part.typing.concat(Array.from(text));
        }
        function previewKey(name: string): void {
            if (Test.on && Slumber.engaged)
                part.typing = part.typing.concat([name]);
        }
        function previewWrong(): void {
            if (!Test.on || !Slumber.engaged)
                return;
            Slumber.fake = false;
            part.typing = part.typing.concat(Slumber.count > 0 || part.typing.length > 0 ? [] : Array.from("glasshouse")).concat(["enter"]);
        }
        function previewUnlock(): void {
            if (!Test.on || !Slumber.engaged)
                return;
            Slumber.fake = true;
            part.typing = part.typing.concat(Slumber.count > 0 || part.typing.length > 0 ? [] : Array.from("moonlight")).concat(["enter"]);
        }
        function previewClose(): void {
            if (Slumber.real)
                return;
            part.typing = [];
            Slumber.abort();
        }
        function probe(): string {
            return Slumber.probe();
        }
        function bake(dir: string): void {
            if (Test.on)
                part.bakeDir = dir;
        }
        function holdShards(seconds: real): void {
            if (Test.on)
                Slumber.holdShards = Math.max(0, seconds);
        }
        function idle(dimSeconds: int, lockSeconds: int): void {
            if (!Test.on)
                return;
            Slumber.dimS = Math.max(1, dimSeconds);
            Slumber.lockS = Math.max(2, lockSeconds);
        }
        function dump(): string {
            const s = Slumber;
            return JSON.stringify({ engaged: s.engaged, real: s.real, shown: s.shown, t: Math.round(s.t * 100) / 100, asleep: s.asleep, deep: s.deep, raised: s.raised, glyphs: s.count, checking: s.checking, tries: s.tries, accepted: s.acceptAt > 0, releasing: s.releasing, shattering: s.shattering, handed: s.handAt > 0, ready: s.ready + "/" + s.needed, handMs: s.handMs, wakeDone: s.wakeDone, fast: s.fast, living: s.living, dim: Math.round(s.dim * 100) / 100, idleShort: s.idleShort, idleLong: s.idleLong, herIdle: Her.idle, inboxHold: Inbox.hold, layout: s.layout, probe: s.probeResult, notice: s.notice, world: World.name });
        }
    }
}
