pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: s

    readonly property string dir: Quickshell.env("GLASSHOUSE_CACHE") || Quickshell.env("HOME") + "/.cache/glasshouse"
    property alias muted: store.muted
    property alias soundLevel: store.soundLevel
    property alias dnd: store.dnd
    property alias nightLight: store.nightLight
    property alias pointerDust: store.pointerDust
    property alias foldMain: store.foldMain
    property alias foldSide: store.foldSide

    FileView {
        id: file
        path: s.dir + "/settings.json"
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }
        JsonAdapter {
            id: store
            property bool muted: false
            property real soundLevel: 0.55
            property bool dnd: false
            property bool nightLight: false
            property bool pointerDust: true
            property bool foldMain: true
            property bool foldSide: true
        }
    }

    Process {
        running: true
        command: ["mkdir", "-p", s.dir]
    }
}
