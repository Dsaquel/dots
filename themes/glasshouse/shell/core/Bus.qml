pragma Singleton

import QtQuick
import Quickshell

Singleton {
    signal sanctum(string mode)
    signal thread()
    signal say(var bubble)
    signal turn()
    signal lockPreview()
    signal settings()
}
