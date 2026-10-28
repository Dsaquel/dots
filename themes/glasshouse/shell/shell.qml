import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.core
import qs.parts.World
import qs.parts.Lancet
import qs.parts.Chrome
import qs.parts.Sanctum
import qs.parts.Chat
import qs.parts.Turn
import qs.parts.Lock
import qs.parts.Pointer
import qs.parts.Profile
import qs.parts.Reliquary
import qs.parts.Sill
import qs.parts.Kiln
import qs.parts.Ledger
import qs.parts.Phial
import qs.parts.Cutter

ShellRoot {
    id: root

    settings.watchFiles: Quickshell.env("GLASSHOUSE_WATCH") !== "0"

    readonly property var parts: (Quickshell.env("GLASSHOUSE_PARTS") || "world,lancet,chrome,sanctum,chat,turn,lock,pointer,profile,reliquary,sill,kiln,ledger,phial,cutter").split(",")

    function has(part: string): bool {
        return root.parts.indexOf(part) >= 0;
    }

    Variants {
        model: Screens.list

        Scope {
            id: output

            required property ShellScreen modelData

            LazyLoader {
                active: root.has("world")
                World {
                    screen: output.modelData
                    onDrawn: if (++root.drawn >= Screens.list.length)
                        soon.start()
                }
            }
            LazyLoader {
                active: root.has("lancet") && Screens.role(output.modelData.name) === "main"
                Lancet {
                    screen: output.modelData
                }
            }
            LazyLoader {
                active: root.has("chrome")
                Chrome {
                    screen: output.modelData
                }
            }
            LazyLoader {
                active: Test.keepalive
                PanelWindow {
                    screen: output.modelData
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.namespace: "glasshouse-keepalive"
                    exclusionMode: ExclusionMode.Ignore
                    anchors { bottom: true; right: true }
                    implicitWidth: 1
                    implicitHeight: 1
                    color: "transparent"
                    mask: Region {}
                    Rectangle {
                        anchors.fill: parent
                        NumberAnimation on opacity { from: 0.02; to: 0.04; duration: 1000; loops: Animation.Infinite }
                        color: "black"
                    }
                }
            }
        }
    }

    LazyLoader {
        active: root.has("chat")
        Chat {}
    }
    LazyLoader {
        active: root.has("phial")
        Phial {}
    }
    LazyLoader {
        active: root.has("cutter")
        Cutter {}
    }

    property int drawn: 0
    property bool late: false
    property bool built: false
    function wake(): void {
        root.late = true;
        root.built = true;
        boot.up = true;
    }
    PersistentProperties {
        id: boot
        reloadableId: "glasshouseBoot"
        property bool up: false
        onReloaded: if (boot.up)
            root.wake()
    }
    Timer {
        id: soon
        interval: 150
        onTriggered: root.wake()
    }
    Timer {
        running: !root.late
        interval: root.has("world") ? 6000 : 0
        onTriggered: root.wake()
    }

    LazyLoader {
        active: root.built && root.has("sanctum")
        Sanctum {}
    }
    LazyLoader {
        active: root.built && root.has("reliquary")
        Reliquary {}
    }
    LazyLoader {
        active: root.built && root.has("profile")
        Profile {}
    }
    LazyLoader {
        active: root.built && root.has("lock")
        Lock {}
    }
    LazyLoader {
        active: root.built && root.has("pointer")
        Pointer {}
    }
    LazyLoader {
        active: root.built && root.has("turn")
        Turn {}
    }
    LazyLoader {
        active: root.built && root.has("sill")
        Sill {}
    }
    LazyLoader {
        active: root.built && root.has("kiln")
        Kiln {}
    }
    LazyLoader {
        active: root.built && root.has("ledger")
        Ledger {}
    }

    IpcHandler {
        enabled: !root.late && root.has("sanctum")
        target: "sanctum"
        function open(): void {
            root.wake();
            Rite.open("apps");
        }
        function close(): void {
            root.wake();
            Rite.close();
        }
        function toggle(): void {
            root.wake();
            Rite.toggle("apps");
        }
        function power(): void {
            root.wake();
            Rite.open("power");
        }
    }
    IpcHandler {
        enabled: !root.late && root.has("reliquary")
        target: "clipboard"
        function toggle(): void {
            root.wake();
            Keeper.toggle();
        }
        function open(): void {
            root.wake();
            Keeper.open();
        }
        function close(): void {
            root.wake();
            Keeper.close();
        }
    }
    IpcHandler {
        enabled: !root.late && root.has("profile")
        target: "profile"
        function toggle(): void {
            root.wake();
            Leaf.toggle();
        }
        function open(): void {
            root.wake();
            Leaf.open = true;
        }
        function close(): void {
            root.wake();
            Leaf.close();
        }
    }
    IpcHandler {
        enabled: !root.late && root.has("turn")
        target: "turn"
        function begin(): void {
            root.wake();
            Bus.turn();
        }
    }
    IpcHandler {
        enabled: !root.late && root.has("ledger")
        target: "settings"
        function open(): void {
            root.wake();
            Bus.settings();
        }
        function close(): void {}
        function status(): string {
            return JSON.stringify({ phase: "rest" });
        }
    }
    IpcHandler {
        enabled: !root.late && root.has("lock")
        target: "lock"
        function now(): void {
            root.wake();
            Slumber.lockNow();
        }
    }
    IpcHandler {
        enabled: !root.late && root.has("pointer")
        target: "pointer"
        function toggle(): void {
            Settings.pointerDust = !Settings.pointerDust;
        }
        function on(): void {
            Settings.pointerDust = true;
        }
        function off(): void {
            Settings.pointerDust = false;
        }
    }
    Connections {
        target: Bus
        enabled: !root.late
        function onSanctum(m: string): void {
            root.wake();
            Bus.sanctum(m);
        }
        function onTurn(): void {
            root.wake();
            Bus.turn();
        }
        function onLockPreview(): void {
            root.wake();
            Bus.lockPreview();
        }
    }

    IpcHandler {
        target: "world"
        function pin(world: string): void {
            World.pin = world;
        }
        function name(): string {
            return World.name;
        }
    }

    IpcHandler {
        target: "glasshouse"
        function reload(): void {
            Quickshell.reload(true);
        }
        function mons(): string {
            return JSON.stringify(Hyprland.monitors.values.map(m => [m.id, m.name, m.x, m.y, m.activeWorkspace ? m.activeWorkspace.id : null, m.lastIpcObject ? Object.keys(m.lastIpcObject).length : 0]));
        }
        function hypr(): string {
            return JSON.stringify({ monitors: Hypr.monitors, active: Hypr.active, windows: Hypr.windows.map(w => [w.address, w.cls, w.monitor, w.ws, w.x, w.y, w.w, w.h]) });
        }
        function status(): string {
            return JSON.stringify({ world: World.name, pin: World.pin, screens: Screens.list.map(s => s.name), parts: root.parts, agents: Agents.sessions.length });
        }
    }

    Process {
        id: announce
        command: ["sh", "-c", 'echo "$PPID" > "${XDG_RUNTIME_DIR:-/tmp}/glasshouse.on" && { hyprctl eval "glasshouse_announce()" >/dev/null 2>&1 || hyprctl reload >/dev/null; }']
    }

    Component.onCompleted: {
        if (!Test.on)
            announce.running = true;
        Agents.sessions;
        Settings.muted;
        Hypr.windows;
        Sfx.enabled;
        Assets.ready;
        Test.on;
        Her.mood;
    }
}
