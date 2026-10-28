pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: l

    property bool open: false
    property real closedAt: 0

    function toggle(): void {
        if (l.open)
            l.close();
        else if (Date.now() - l.closedAt > 400)
            l.open = true;
    }
    function close(): void {
        if (!l.open)
            return;
        l.open = false;
        l.closedAt = Date.now();
    }
}
