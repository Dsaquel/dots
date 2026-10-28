import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.core
import qs.parts.Lancet

Scope {
    id: part

    property bool shown: false
    readonly property var screenObj: Screens.list.find(s => Screens.role(s.name) === "main") || null

    Connections {
        target: Leaf
        function onOpenChanged(): void {
            if (Leaf.open)
                part.shown = true;
            Sfx.play(Leaf.open ? "menu-open" : "menu-close", 0.7);
        }
    }

    LazyLoader {
        active: part.shown && !!part.screenObj
        Page {
            modelData: part.screenObj
            open: Leaf.open
            onDismiss: Leaf.close()
            onFolded: part.shown = false
        }
    }

    GlobalShortcut {
        appid: Test.on ? "glasshouse-test" : "glasshouse"
        name: "profile"
        description: "Her page"
        onPressed: Leaf.toggle()
    }

    IpcHandler {
        target: "profile"
        function toggle(): void {
            Leaf.toggle();
        }
        function open(): void {
            Leaf.open = true;
        }
        function close(): void {
            Leaf.close();
        }
        function status(): string {
            return JSON.stringify({ open: Leaf.open, shown: part.shown, screen: part.screenObj ? part.screenObj.name : null });
        }
    }
}
