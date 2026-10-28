import QtQuick
import Quickshell

Scope {
    LazyLoader {
        active: true
        source: Qt.resolvedUrl("LockPart.qml")
    }
}
