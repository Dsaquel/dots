import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.core

Scope {
    id: sanctum

    LazyLoader {
        active: Rite.shown && !!Rite.screenObj
        PanelWindow {
            id: win
            screen: Rite.screenObj
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "glasshouse-sanctum"
            WlrLayershell.keyboardFocus: !Test.on && Rite.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"

            Altar {
                anchors.fill: parent
            }
        }
    }

    Timer {
        id: warmUp
        property bool ready: false
        interval: 3000
        running: true
        onTriggered: warmUp.ready = true
    }
    Variants {
        model: Screens.list
        Scope {
            id: warmth
            required property ShellScreen modelData
            property bool done: false
            LazyLoader {
                active: warmUp.ready && !warmth.done
                PanelWindow {
                    screen: warmth.modelData
                    WlrLayershell.layer: WlrLayer.Background
                    WlrLayershell.namespace: "glasshouse-warm"
                    exclusionMode: ExclusionMode.Ignore
                    anchors {
                        top: true
                        left: true
                    }
                    implicitWidth: 1
                    implicitHeight: 1
                    color: "transparent"
                    mask: Region {}
                    ScreencopyView {
                        anchors.fill: parent
                        captureSource: warmth.modelData
                        live: false
                        paintCursor: false
                        onHasContentChanged: if (hasContent) settle.start()
                    }
                    Timer {
                        id: settle
                        interval: 400
                        onTriggered: warmth.done = true
                    }
                }
            }
        }
    }

    readonly property string appid: Test.on ? "glasshouse-test" : "glasshouse"
    GlobalShortcut {
        appid: sanctum.appid
        name: "sanctum"
        description: "The Sanctum: the applications"
        onPressed: Rite.toggle("apps")
    }
    GlobalShortcut {
        appid: sanctum.appid
        name: "power"
        description: "The Sanctum: the power roundels"
        onPressed: Rite.open("power")
    }

    Connections {
        target: Bus
        function onSanctum(m: string): void {
            m === "" ? Rite.toggle("apps") : Rite.open(m);
        }
    }

    IpcHandler {
        target: "sanctum"
        function open(): void {
            Rite.open("apps");
        }
        function close(): void {
            Rite.close();
        }
        function toggle(): void {
            Rite.toggle("apps");
        }
        function power(): void {
            Rite.open("power");
        }
        function type(text: string): void {
            if (Test.on)
                Rite.typed(text);
        }
        function key(name: string): string {
            if (!Test.on)
                return "test only";
            const m = name.match(/^(ctrl\+)?(shift\+)?(.+)$/i);
            const k = m[3].length === 1 ? m[3].toUpperCase() : m[3];
            return Rite.key(k, !!m[1], !!m[2]) ? "ok" : "unhandled";
        }
        function screen(name: string): void {
            if (Test.on)
                Rite.testScreen = name;
        }
        function dump(): string {
            return JSON.stringify({
                opened: Rite.opened,
                shown: Rite.shown,
                screen: Rite.screenName,
                query: Rite.query,
                selected: Rite.selected,
                zone: Rite.zone,
                index: Rite.index,
                armed: Rite.armed,
                results: Rite.results.slice(0, 12).map(r => r.title),
                count: Rite.results.length,
                zones: Rite.zones,
                player: Rite.player ? Rite.player.dbusName : null,
                firstFrameMs: Rite.firstFrame,
                acts: Rite.acts
            });
        }
    }

    Component.onCompleted: Rite.ruleOut()
}
