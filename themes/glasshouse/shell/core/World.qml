pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: w

    readonly property string stateFile: Quickshell.env("GLASSHOUSE_STATE") || Quickshell.env("HOME") + "/.cache/theme-switch/current"
    property string mode: "dark"
    property string pin: "auto"
    readonly property string name: pin === "dark" || pin === "light" ? pin : mode
    readonly property bool dark: name === "dark"
    readonly property bool light: name === "light"

    FileView {
        path: w.stateFile
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: w.mode = text().trim() === "light" ? "light" : "dark"
    }
}
