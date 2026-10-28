pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: t

    readonly property bool dark: World.dark
    readonly property string world: World.name

    function a(name: string): url {
        return Qt.resolvedUrl("../assets/" + t.world + "/" + name);
    }
    function of(world: string, name: string): url {
        return Qt.resolvedUrl("../assets/" + world + "/" + name);
    }
    function shared(name: string): url {
        return Qt.resolvedUrl("../assets/shared/" + name);
    }

    readonly property color ground: dark ? "#0f1226" : "#1b1d5e"
    readonly property color field: dark ? "#0f1226" : "#292e9d"
    readonly property color surface: dark ? "#1a2840" : "#292e9d"
    readonly property color raised: dark ? "#243552" : "#343aa8"
    readonly property color ink: dark ? "#f1e8dc" : "#fff8ec"
    readonly property color inkSoft: dark ? "#c9c3d8" : "#efe4ff"
    readonly property color dim: dark ? "#9aa4bd" : "#d9ccf2"
    readonly property color inkOnLight: "#211b33"
    readonly property color ivory: "#f4ecdc"

    readonly property color metalBase: dark ? "#3a3950" : "#caa36a"
    readonly property color metalHi: dark ? "#d6d3f2" : "#fff7e2"
    readonly property color metalLow: dark ? "#06070e" : "#4a2f1c"
    readonly property color metalSky: dark ? "#7d88ba" : "#fbe3b0"
    readonly property color pearl: "#f4efe6"

    readonly property color lamp: dark ? "#f2b35e" : "#e41480"
    readonly property color sun: "#ffd48a"
    readonly property color rare: dark ? "#e2b670" : "#fcf2db"
    readonly property color accent: dark ? "#f2b35e" : "#ffd48a"
    readonly property var jewels: dark ? ["#3558b8", "#6a4fc2", "#cfd8ec", "#87b2aa", "#b8567e"] : ["#e8759a", "#f3c14f", "#5fd3e6", "#8a63da", "#7fb6ff"]

    readonly property color ok: dark ? "#7cc9a0" : "#3a9467"
    readonly property color alert: dark ? "#e0668a" : "#cf3b4a"
    readonly property color info: dark ? "#5fb0e0" : "#1a92c4"
    readonly property color honey: "#fdcf6f"
    readonly property color cream: "#fdf8cd"

    readonly property string jp: dark ? "Kaisei Tokumin" : "Dela Gothic One"
    readonly property string numerals: dark ? "Gilda Display" : "Bodoni Moda"
    readonly property string caps: "Cinzel"
    readonly property string ui: dark ? "Outfit" : "Manrope"
    readonly property string mono: "Monaspace Argon Var"
    readonly property string glyphs: "Symbols Nerd Font Mono"
    readonly property string symbols: "Noto Sans Symbols"
    readonly property real capsTracking: 3

    readonly property int menuOpenMs: 700
    readonly property int menuCloseMs: 450
    readonly property int panMs: 300
}
