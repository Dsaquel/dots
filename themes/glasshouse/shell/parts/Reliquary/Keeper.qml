pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.core

Singleton {
    id: part

    property bool shown: false
    property bool opened: false
    property string query: ""
    property int selected: 0
    property string screenName: ""
    property var screenObj: null
    property string testScreen: ""
    property var target: null
    property string pasting: ""
    property real askedAt: 0
    property real firstFrame: -1
    property var acts: []

    readonly property alias clips: clipsItem
    readonly property var results: clipsItem.search(part.query)
    Clips {
        id: clipsItem
    }
    Instantiator {
        model: Object.values(clipsItem.thumbs)
        delegate: Image {
            required property string modelData
            source: modelData
            sourceSize: Qt.size(224, 68)
            asynchronous: true
            visible: false
        }
    }

    readonly property string mainScreen: {
        const m = Screens.list.find(s => Screens.role(s.name) === "main");
        return m ? m.name : (Screens.list.length ? Screens.list[0].name : "");
    }
    function where(): string {
        if (Test.on)
            return part.testScreen || part.mainScreen;
        const f = Hypr.focusedMonitor;
        return Screens.list.some(s => s.name === f) ? f : part.mainScreen;
    }
    function isTerminal(comm: string, cls: string): bool {
        return /kitty|foot|alacritty|wezterm|ghostty|konsole|terminal|xterm|ptyxis|kgx|tilix/i.test(comm + " " + cls);
    }

    function open(): void {
        part.askedAt = Date.now();
        if (part.opened)
            return;
        const w = Hypr.find(Hypr.active);
        const shown = !!w && Hypr.on(w.monitor).some(o => o.address === w.address);
        part.target = shown && (!Test.on || w.cls.startsWith("ghdemo-")) ? { address: w.address, cls: w.cls, pid: w.pid } : null;
        part.query = "";
        part.selected = 0;
        part.pasting = "";
        clips.load();
        if (part.shown) {
            part.opened = true;
            Sfx.play("focus", 0.7);
            return;
        }
        const name = part.where();
        const scr = Screens.list.find(s => s.name === name) || null;
        if (!scr || (Test.on && !/^VSCREEN-[A-I]$/.test(name)))
            return;
        part.screenName = name;
        part.screenObj = scr;
        part.firstFrame = -1;
        part.opened = true;
        part.shown = true;
        Sfx.play("focus", 0.7);
    }
    function close(): void {
        if (!part.opened)
            return;
        part.opened = false;
        if (!part.pasting)
            Sfx.play("menu-close", 0.5);
    }
    function toggle(): void {
        if (part.opened)
            part.close();
        else
            part.open();
    }

    function move(d: int): void {
        const n = part.results.length;
        if (n > 0)
            part.selected = Math.max(0, Math.min(n - 1, part.selected + d));
    }
    function typed(text: string): void {
        if (!text)
            return;
        part.query += text;
        part.selected = 0;
    }
    function erase(all: bool): void {
        part.query = all ? "" : part.query.slice(0, -1);
        part.selected = 0;
    }
    function key(name: string, ctrl: bool): bool {
        switch (name) {
        case "Escape":
            part.close();
            return true;
        case "Return":
        case "Enter":
            part.paste(part.results[part.selected]);
            return true;
        case "BackSpace":
            part.erase(ctrl);
            return true;
        case "U":
            if (!ctrl)
                return false;
            part.erase(true);
            return true;
        case "J":
        case "N":
            if (!ctrl)
                return false;
            part.move(1);
            return true;
        case "K":
        case "P":
            if (!ctrl)
                return false;
            part.move(-1);
            return true;
        case "Down":
            part.move(1);
            return true;
        case "Up":
            part.move(-1);
            return true;
        case "PageDown":
            part.move(8);
            return true;
        case "PageUp":
            part.move(-8);
            return true;
        case "Home":
            part.selected = 0;
            return true;
        case "End":
            part.selected = Math.max(0, part.results.length - 1);
            return true;
        }
        return false;
    }
    function keyEvent(e: var): bool {
        const names = {};
        names[Qt.Key_Escape] = "Escape";
        names[Qt.Key_Return] = "Return";
        names[Qt.Key_Enter] = "Enter";
        names[Qt.Key_Backspace] = "BackSpace";
        names[Qt.Key_Down] = "Down";
        names[Qt.Key_Up] = "Up";
        names[Qt.Key_PageDown] = "PageDown";
        names[Qt.Key_PageUp] = "PageUp";
        names[Qt.Key_Home] = "Home";
        names[Qt.Key_End] = "End";
        names[Qt.Key_J] = "J";
        names[Qt.Key_K] = "K";
        names[Qt.Key_N] = "N";
        names[Qt.Key_P] = "P";
        names[Qt.Key_U] = "U";
        const ctrl = (e.modifiers & Qt.ControlModifier) !== 0;
        const name = names[e.key];
        if (name && part.key(name, ctrl))
            return true;
        if (!ctrl && e.text && e.text.length > 0 && e.text.charCodeAt(0) >= 32 && e.text !== "\u007f") {
            part.typed(e.text);
            return true;
        }
        return false;
    }

    function act(what: string): void {
        const line = "would " + what;
        part.acts = part.acts.concat([Qt.formatTime(new Date(), "HH:mm:ss") + "  " + line]).slice(-40);
        console.log("reliquary: " + line);
    }
    function paste(r: var): void {
        if (!r || copier.running)
            return;
        const e = r.clip;
        copier.entry = e;
        copier.win = part.target;
        copier.command = ["sh", "-c", part.copyScript, "sh", e.id, e.mime, String(part.target ? part.target.pid : 0), clips.db, Test.on ? "dry" : ""];
        copier.running = true;
        part.pasting = r.key;
        Sfx.play("volume", 0.9);
        part.close();
    }
    readonly property string copyScript: 't=$(mktemp -p "${XDG_RUNTIME_DIR:-/tmp}" glasshouse-clip.XXXXXX) || exit 0; if [ -n "$4" ]; then cliphist -db-path "$4" decode "$1"; else cliphist decode "$1"; fi > "$t" 2>/dev/null; if [ -s "$t" ] && { [ "$5" = dry ] || wl-copy -t "$2" < "$t" 2>/dev/null; }; then printf "ok %s %s" "$(wc -c < "$t")" "$(cat "/proc/$3/comm" 2>/dev/null)"; fi; rm -f "$t"'
    Process {
        id: copier
        property var entry: null
        property var win: null
        stdout: StdioCollector {
            onStreamFinished: part.landed(copier.entry, copier.win, text)
        }
    }
    function told(e: var, bytes: string): string {
        return "#" + e.id + " (" + (e.image ? "an image " + e.w + "x" + e.h + " " + e.ext : bytes + " bytes: \"" + e.text.slice(0, 48) + "\"") + ")";
    }
    function landed(e: var, w: var, out: string): void {
        const m = out.match(/^ok (\d+) ?(.*)$/);
        if (!m) {
            console.log("reliquary: the entry could not be copied");
            return;
        }
        if (!w) {
            if (Test.on)
                part.act("copy " + part.told(e, m[1]) + " to the clipboard; no window had the focus: no paste");
            return;
        }
        const mods = part.isTerminal(m[2], w.cls) ? "CTRL SHIFT" : "CTRL";
        if (Test.on) {
            part.act("copy " + part.told(e, m[1]) + " to the clipboard, then send " + mods.toLowerCase().replace(" ", "+") + "+v to 0x" + w.address + " (" + w.cls + ", " + (m[2] || "?") + ")");
            return;
        }
        Hypr.dispatch("function() local W = \"address:0x" + w.address + "\" if hl.get_window(W) then hl.dispatch(hl.dsp.focus({ window = W })) hl.dispatch(hl.dsp.send_shortcut({ mods = \"" + mods + "\", key = \"v\", window = W })) end end");
    }

    function ruleOut(): void {
        Quickshell.execDetached(["hyprctl", "eval", 'hl.layer_rule({ name = "glasshouse-reliquary", match = { namespace = "^(glasshouse-reliquary)$" }, no_anim = true })']);
    }
    Connections {
        target: Hyprland
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "configreloaded")
                part.ruleOut();
        }
    }
}
