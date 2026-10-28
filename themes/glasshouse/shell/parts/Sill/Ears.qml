import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.core

Scope {
    id: ears

    required property var her

    Connections {
        target: Hypr
        function onWindowsChanged(): void {
            Qt.callLater(ears.her.think);
        }
        function onMonitorsChanged(): void {
            Qt.callLater(ears.her.think);
        }
        function onActiveChanged(): void {
            Qt.callLater(ears.her.think);
        }
        function onOpened(win: var): void {
            const b = {};
            const now = Date.now();
            for (const a in ears.her.born)
                if (now - ears.her.born[a] < 5000)
                    b[a] = ears.her.born[a];
            b[win.address] = now;
            ears.her.born = b;
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "configreloaded")
                ears.her.ruleOut();
            else if (event.name === "vitrail" && event.data.indexOf("glaze,") === 0)
                ears.her.heard(event.data);
        }
    }
}
