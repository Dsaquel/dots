import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core

Scope {
    id: phial

    property string kind: "volume"
    property bool shown: false
    property var screenObj: null
    readonly property real level: phial.kind === "mic" ? Audio.micVolume : Audio.volume
    readonly property bool muted: phial.kind === "mic" ? Audio.micMuted : Audio.muted

    signal poked()

    function where(): var {
        const f = Hypr.focusedMonitor;
        const main = Screens.list.find(s => Screens.role(s.name) === "main") || Screens.list[0] || null;
        return Screens.list.find(s => s.name === f) || main;
    }
    function show(k: string): void {
        if (!phial.shown) {
            const scr = phial.where();
            if (!scr)
                return;
            phial.kind = k;
            phial.screenObj = scr;
            phial.shown = true;
            return;
        }
        phial.kind = k;
        Qt.callLater(phial.poke);
    }
    function poke(): void {
        phial.poked();
    }
    function setLevel(v: real): void {
        phial.kind === "mic" ? Audio.setMic(v) : Audio.setVolume(v);
    }
    function toggleMute(): void {
        phial.kind === "mic" ? Audio.toggleMic() : Audio.toggleMute();
    }

    Connections {
        target: Audio
        function onVolumeTouched(): void {
            phial.show("volume");
        }
        function onMicTouched(): void {
            phial.show("mic");
        }
    }

    LazyLoader {
        active: phial.shown && !!phial.screenObj
        PanelWindow {
            id: win
            readonly property real u: Screens.unit(phial.screenObj.name)
            screen: phial.screenObj
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "glasshouse-phial"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            anchors.bottom: true
            implicitWidth: Math.round(440 * win.u)
            implicitHeight: Math.round(320 * win.u)
            color: "transparent"
            mask: Region {
                item: vial.hit
            }

            Vial {
                id: vial
                anchors.fill: parent
                host: phial
                u: win.u
                onDone: phial.shown = false
            }
        }
    }

    IpcHandler {
        target: "phial"
        function open(kind: string): void {
            phial.show(kind === "mic" ? "mic" : "volume");
        }
        function status(): string {
            return JSON.stringify({ shown: phial.shown, kind: phial.kind, level: phial.level, muted: phial.muted, screen: phial.screenObj ? phial.screenObj.name : "" });
        }
    }

    Component.onCompleted: Audio.phial = true
    Component.onDestruction: Audio.phial = false
}
