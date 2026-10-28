import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: a

    property string cls
    property int pid
    property string comm: ""

    readonly property var glyphs: ({ "kitty": "", "org.wezfurlong.wezterm": "", "foot": "", "Alacritty": "" })
    readonly property var entry: {
        DesktopEntries.applications.values;
        return DesktopEntries.heuristicLookup(a.cls) || (a.comm ? DesktopEntries.heuristicLookup(a.comm) : null);
    }
    readonly property string id: a.entry ? a.entry.id : (a.comm || a.cls)
    readonly property string name: a.entry ? a.entry.name : (a.comm || a.cls)
    readonly property string glyph: a.glyphs[a.id] || ""
    readonly property string icon: a.glyph === "" && a.entry && a.entry.icon ? Quickshell.iconPath(a.entry.icon, true) : ""
    readonly property string monogram: (a.name || "?").charAt(0).toUpperCase()

    FileView {
        path: a.pid > 0 && !DesktopEntries.heuristicLookup(a.cls) ? "/proc/" + a.pid + "/comm" : ""
        printErrors: false
        onLoaded: a.comm = text().trim()
    }
}
