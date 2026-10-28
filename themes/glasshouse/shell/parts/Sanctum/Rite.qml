pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import qs.core
import qs.parts.Lancet

Singleton {
    id: part

    property bool shown: false
    property bool opened: false
    property string query: ""
    property int selected: 0
    property string zone: "list"
    property int index: 0
    property string armed: ""
    property string screenName: ""
    property var screenObj: null
    property string testScreen: ""
    property real askedAt: 0
    property real firstFrame: -1
    property var acts: []
    readonly property string latlon: Quickshell.env("GLASSHOUSE_LATLON") || ""

    readonly property string mainScreen: {
        const m = Screens.list.find(s => Screens.role(s.name) === "main");
        return m ? m.name : (Screens.list.length ? Screens.list[0].name : "");
    }
    function target(): string {
        if (Test.on)
            return part.testScreen || part.mainScreen;
        const f = Hypr.focusedMonitor;
        return Screens.list.some(s => s.name === f) ? f : part.mainScreen;
    }

    readonly property var results: catalog.search(part.query)
    readonly property var player: {
        const ps = Mpris.players.values;
        if (Test.on)
            return ps.find(p => (p.dbusName || "").indexOf("glasshouse_test") >= 0) || null;
        return ps.find(p => p.isPlaying) || ps.find(p => p.canControl) || null;
    }
    readonly property var agentRank: ({ needs: 0, working: 1, idle: 2, done: 3 })
    readonly property var agents: Agents.live.slice().sort((a, b) => (part.agentRank[a.state] ?? 4) - (part.agentRank[b.state] ?? 4) || b.updated - a.updated)
    readonly property var tray: SystemTray.items.values.filter(i => i.status !== Status.Passive)
    readonly property var systems: ["wifi", "bluetooth", "audio", "night", "pointer", "dnd", "sounds"]
    readonly property var powers: ["lock", "logout", "suspend", "reboot", "shutdown"]
    readonly property var zones: [
        { key: "list", n: part.results.length, axis: "v" },
        { key: "system", n: part.systems.length, axis: "h" },
        { key: "volume", n: Gauges.sinkReady ? 1 : 0, axis: "h" },
        { key: "agents", n: Math.min(3, part.agents.length), axis: "v" },
        { key: "player", n: part.player ? 3 : 0, axis: "h" },
        { key: "tray", n: part.tray.length, axis: "h" },
        { key: "power", n: part.powers.length, axis: "h" }
    ].filter(z => z.n > 0 || z.key === "list")
    onZonesChanged: {
        const z = part.zoneOf(part.zone);
        if (!z || z.n === 0) {
            part.zone = "list";
            part.index = 0;
        } else if (part.index >= z.n) {
            part.index = z.n - 1;
        }
    }

    readonly property int herSize: Theme.dark ? 900 : 860
    readonly property int herPx: Math.round(part.herSize * Screens.unit(part.screenName || part.mainScreen))
    Reserve {
        herPx: part.herPx
    }

    readonly property alias catalog: catalogItem
    readonly property alias sky: skyItem
    Catalog {
        id: catalogItem
    }
    Sky {
        id: skyItem
    }

    signal trayMenu(int index)

    function open(m: string): void {
        part.askedAt = Date.now();
        const power = m === "power";
        if (part.opened && !power)
            return;
        part.query = "";
        part.selected = 0;
        part.armed = "";
        part.zone = power ? "power" : "list";
        part.index = 0;
        sky.refresh();
        if (part.shown && !part.opened) {
            part.opened = true;
        } else if (!part.opened) {
            const name = part.target();
            const scr = Screens.list.find(s => s.name === name) || null;
            if (!scr || (Test.on && !/^VSCREEN-[A-I]$/.test(name)))
                return;
            part.screenName = name;
            part.screenObj = scr;
            part.firstFrame = -1;
            part.opened = true;
            part.shown = true;
        }
    }
    function close(): void {
        if (!part.opened)
            return;
        part.opened = false;
        part.armed = "";
    }
    function toggle(m: string): void {
        if (part.opened && m !== "power")
            part.close();
        else
            part.open(m);
    }

    function zoneOf(key: string): var {
        return part.zones.find(z => z.key === key) || null;
    }
    function walk(step: int): void {
        const keys = part.zones.map(z => z.key);
        let i = keys.indexOf(part.zone);
        i = ((i < 0 ? 0 : i) + step + keys.length) % keys.length;
        part.zone = keys[i];
        part.index = 0;
        part.armed = "";
    }
    function moveList(d: int): void {
        const n = part.results.length;
        if (n > 0)
            part.selected = Math.max(0, Math.min(n - 1, part.selected + d));
    }
    function moveIn(d: int): void {
        const z = part.zoneOf(part.zone);
        if (!z || z.n === 0)
            return;
        part.index = (part.index + d + z.n) % z.n;
        part.armed = "";
    }
    function vertical(d: int): void {
        if (part.zone === "list") {
            part.moveList(d);
            return;
        }
        const z = part.zoneOf(part.zone);
        if (z && z.axis === "v" && part.index + d >= 0 && part.index + d < z.n) {
            part.index += d;
            part.armed = "";
            return;
        }
        const keys = part.zones.filter(x => x.key !== "list").map(x => x.key);
        const j = keys.indexOf(part.zone) + d;
        if (j < 0 || j >= keys.length)
            return;
        const next = part.zoneOf(keys[j]);
        part.zone = next.key;
        part.index = d < 0 && next.axis === "v" ? next.n - 1 : 0;
        part.armed = "";
    }
    function horizontal(d: int): bool {
        const z = part.zoneOf(part.zone);
        if (!z || z.axis !== "h")
            return false;
        if (z.key === "volume")
            part.nudgeVolume(d);
        else
            part.moveIn(d);
        return true;
    }
    function typed(text: string): void {
        if (!text)
            return;
        part.zone = "list";
        part.query += text;
        part.selected = 0;
    }
    function erase(all: bool): void {
        part.zone = "list";
        part.query = all ? "" : part.query.slice(0, -1);
        part.selected = 0;
    }
    function key(name: string, ctrl: bool, shift: bool): bool {
        const list = part.zone === "list";
        switch (name) {
        case "Escape":
            if (part.armed)
                part.armed = "";
            else
                part.close();
            return true;
        case "Return":
        case "Enter":
            if (shift && part.zone === "tray")
                part.trayMenu(part.index);
            else
                part.activate();
            return true;
        case "Tab":
            part.walk(shift ? -1 : 1);
            return true;
        case "Backtab":
            part.walk(-1);
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
            part.vertical(1);
            return true;
        case "K":
        case "P":
            if (!ctrl)
                return false;
            part.vertical(-1);
            return true;
        case "Down":
            part.vertical(1);
            return true;
        case "Up":
            part.vertical(-1);
            return true;
        case "Right":
            return part.horizontal(1);
        case "Left":
            return part.horizontal(-1);
        case "PageDown":
            part.moveList(8);
            return true;
        case "PageUp":
            part.moveList(-8);
            return true;
        case "Home":
            part.selected = 0;
            return true;
        case "End":
            part.selected = Math.max(0, part.results.length - 1);
            return true;
        case "Space":
            if (list)
                return false;
            part.activate();
            return true;
        }
        return false;
    }
    function keyEvent(e: var): bool {
        const names = {};
        names[Qt.Key_Escape] = "Escape";
        names[Qt.Key_Return] = "Return";
        names[Qt.Key_Enter] = "Enter";
        names[Qt.Key_Tab] = "Tab";
        names[Qt.Key_Backtab] = "Backtab";
        names[Qt.Key_Backspace] = "BackSpace";
        names[Qt.Key_Down] = "Down";
        names[Qt.Key_Up] = "Up";
        names[Qt.Key_Left] = "Left";
        names[Qt.Key_Right] = "Right";
        names[Qt.Key_PageDown] = "PageDown";
        names[Qt.Key_PageUp] = "PageUp";
        names[Qt.Key_Home] = "Home";
        names[Qt.Key_End] = "End";
        names[Qt.Key_Space] = "Space";
        names[Qt.Key_J] = "J";
        names[Qt.Key_K] = "K";
        names[Qt.Key_N] = "N";
        names[Qt.Key_P] = "P";
        names[Qt.Key_U] = "U";
        const ctrl = (e.modifiers & Qt.ControlModifier) !== 0;
        const shift = (e.modifiers & Qt.ShiftModifier) !== 0;
        const name = names[e.key];
        if (name && part.key(name, ctrl, shift))
            return true;
        if (!ctrl && e.text && e.text.length > 0 && e.text.charCodeAt(0) >= 32 && e.text !== "\u007f") {
            part.typed(e.text);
            return true;
        }
        return false;
    }

    function activate(): void {
        switch (part.zone) {
        case "list":
            {
                const r = part.results[part.selected];
                if (r)
                    part.launch(r);
                return;
            }
        case "system":
            part.system(part.systems[part.index]);
            return;
        case "volume":
            part.muteToggle();
            return;
        case "player":
            part.music(["previous", "toggle", "next"][part.index]);
            return;
        case "agents":
            part.agent(part.agents[part.index]);
            return;
        case "tray":
            part.trayItem(part.tray[part.index], "activate", null, 0, 0);
            return;
        case "power":
            part.power(part.powers[part.index]);
            return;
        }
    }
    function act(what: string, done: bool): void {
        const line = (done ? "did " : "would ") + what;
        part.acts = part.acts.concat([Qt.formatTime(new Date(), "HH:mm:ss") + "  " + line]).slice(-40);
        console.log("sanctum: " + line);
    }
    function launch(r: var): void {
        const e = r.entry;
        catalog.used(e.id);
        if (Test.on) {
            const isKitty = e.id === "kitty" || (e.command && e.command[0] === "kitty");
            if (isKitty) {
                const id = "ghdemo-sanctum-" + Math.floor(Math.random() * 1e5);
                const palettes = Quickshell.env("GLASSHOUSE_TEST_KITTY");
                const palette = palettes ? ' --config ' + palettes + '/palette-' + World.name + '.conf' : '';
                const ws = Hypr.activeWs(part.screenName);
                Hypr.dispatch('hl.dsp.exec_cmd("kitty --class ' + id + ' --config ' + Quickshell.env("HOME") + '/.config/kitty/kitty.conf' + palette + ' -o cursor_trail=0 -o confirm_os_window_close=0", { workspace = "' + ws + ' silent", no_initial_focus = true })');
                part.act("launch kitty -> " + id + " on workspace " + ws + ", silent", true);
            } else {
                part.act("launch " + e.id + ": " + (e.execString || (e.command || []).join(" ")));
            }
        } else if (e.runInTerminal) {
            Quickshell.execDetached(["kitty", "-e"].concat(e.command));
        } else {
            e.execute();
        }
        part.close();
    }
    function system(k: string): void {
        switch (k) {
        case "dnd":
            Settings.dnd = !Settings.dnd;
            if (Test.on)
                part.act("turn do not disturb " + (Settings.dnd ? "on" : "off") + " (the test instance's settings)", true);
            return;
        case "sounds":
            Settings.muted = !Settings.muted;
            if (Test.on)
                part.act((Settings.muted ? "mute" : "unmute") + " the glass sounds (the test instance's settings)", true);
            return;
        case "wifi":
            if (Test.on)
                part.act("turn Wi-Fi " + (Networking.wifiEnabled ? "off" : "on"));
            else
                Networking.wifiEnabled = !Networking.wifiEnabled;
            return;
        case "bluetooth":
            {
                const a = Bluetooth.defaultAdapter;
                if (!a)
                    return;
                if (Test.on)
                    part.act("turn Bluetooth " + (a.enabled ? "off" : "on"));
                else
                    a.enabled = !a.enabled;
                return;
            }
        case "audio":
            {
                const sinks = Pipewire.nodes.values.filter(n => n.isSink && n.audio && !n.isStream);
                const cur = Pipewire.defaultAudioSink;
                if (sinks.length < 2)
                    return;
                const next = sinks[(sinks.indexOf(cur) + 1) % sinks.length];
                if (Test.on)
                    part.act("switch the output to " + part.label(next));
                else
                    Pipewire.preferredDefaultAudioSink = next;
                return;
            }
        case "night":
            if (Test.on)
                part.act("turn the night light " + (Settings.nightLight ? "off" : "on") + " (gammastep 4300 K)");
            else
                Settings.nightLight = !Settings.nightLight;
            return;
        case "pointer":
            Settings.pointerDust = !Settings.pointerDust;
            if (Test.on)
                part.act("turn the pointer dust " + (Settings.pointerDust ? "on" : "off") + " (the test instance's settings)", true);
            return;
        }
    }
    function pickVolume(): void {
        part.zone = "volume";
        part.index = 0;
    }
    function setVolume(v: real): void {
        part.pickVolume();
        Gauges.setVolume(v);
        if (Test.on)
            part.act("set the volume of the test sink " + Gauges.sinkLabel + " to " + Math.round(v * 100) + " %", true);
    }
    function nudgeVolume(d: int): void {
        part.setVolume(Math.round((Gauges.volume + 0.05 * d) * 20) / 20);
    }
    function muteToggle(): void {
        const was = Gauges.muted;
        part.pickVolume();
        Gauges.toggleMute();
        if (Test.on)
            part.act((was ? "unmute the test sink " : "mute the test sink ") + Gauges.sinkLabel, true);
    }
    function label(n: var): string {
        if (!n)
            return "";
        const d = (n.description || "").split(",").filter(p => p.indexOf("=") < 0).join(",").trim();
        return d || n.nickname || n.name;
    }
    function music(cmd: string): void {
        const p = part.player;
        if (!p)
            return;
        if (cmd === "previous" && p.canGoPrevious)
            p.previous();
        else if (cmd === "next" && p.canGoNext)
            p.next();
        else if (cmd === "toggle" && p.canTogglePlaying)
            p.togglePlaying();
    }
    function agent(s: var): void {
        if (!s)
            return;
        const t = Gauges.terminalOf(s);
        if (Test.on) {
            part.act("focus " + (t ? t.cls + " " + t.address + " (" + t.how + ")" : "no terminal") + " for " + s.label);
            return;
        }
        if (t)
            Hypr.focusWindow(t.address);
        part.close();
    }
    function trayItem(item: var, how: string, win: var, x: int, y: int): void {
        if (!item)
            return;
        const name = item.tooltipTitle || item.title || item.id;
        if (Test.on) {
            part.act((how === "menu" ? "open the menu of " : how === "secondary" ? "secondary-activate " : "activate ") + name);
            return;
        }
        if (how === "menu" && item.hasMenu && win) {
            item.display(win, x, y);
            return;
        }
        if (how !== "activate") {
            item.secondaryActivate();
            return;
        }
        item.activate();
        part.close();
    }
    readonly property var powerCmd: ({
            lock: ["glasshouse-lock", "now"],
            logout: ["hyprctl", "dispatch", "hl.dsp.exit()"],
            suspend: ["systemctl", "suspend"],
            reboot: ["systemctl", "reboot"],
            shutdown: ["systemctl", "poweroff"]
        })
    function power(k: string): void {
        part.zone = "power";
        part.index = part.powers.indexOf(k);
        if (k !== "lock" && part.armed !== k) {
            part.armed = k;
            disarm.restart();
            return;
        }
        part.armed = "";
        if (Test.on) {
            part.act(part.powerCmd[k].join(" "));
            return;
        }
        part.close();
        Quickshell.execDetached(part.powerCmd[k]);
    }
    Timer {
        id: disarm
        interval: 4000
        onTriggered: part.armed = ""
    }

    Process {
        running: !Test.on && Settings.nightLight
        command: ["setpriv", "--pdeathsig", "TERM", "--", "gammastep", "-m", "wayland"].concat(part.latlon ? ["-l", part.latlon.replace(",", ":")] : []).concat(["-t", "4300:4300"])
    }

    function ruleOut(): void {
        Quickshell.execDetached(["hyprctl", "eval", 'hl.layer_rule({ name = "glasshouse-sanctum", match = { namespace = "^(glasshouse-sanctum)$" }, no_anim = true })']);
    }
    Connections {
        target: Hyprland
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "configreloaded")
                part.ruleOut();
        }
    }
}
