import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.core

Scope {
    id: cutter

    property string phase: ""
    property string stamp: ""
    property string keyScreen: ""
    property string screenName: ""
    property var rect: null
    property var hover: null
    property var frames: ({})
    property real frost: 0
    property real cut: 0
    property real melt: 0
    property real gild: 0
    property real taken: 0
    property bool canRead: false
    property string toastTitle: ""
    property string toastText: ""
    property string swatch: ""
    property real recordAt: 0
    property string recordFile: ""
    property bool filming: false
    property var after: null
    readonly property string dir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/glasshouse-cutter" + (Test.on ? "-test" : "")
    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string shots: Quickshell.env("HYPRSHOT_DIR") || (Quickshell.env("XDG_PICTURES_DIR") || cutter.home + "/Pictures") + "/Screenshots"
    readonly property string films: (Quickshell.env("XDG_VIDEOS_DIR") || cutter.home + "/Videos") + "/Screencasts"
    readonly property var tools: [
        { key: "copy", label: "COPY", hint: "ENTER", glyph: "\u{f018f}", dark: "#3558b8", light: "#5fb2ff" },
        { key: "save", label: "SAVE", hint: "CTRL S", glyph: "\u{f0193}", dark: "#2e8a6a", light: "#4fd6a0" },
        { key: "annotate", label: "ANNOTATE", hint: "", glyph: "\u{f03eb}", dark: "#6a4fc2", light: "#a77ef0" },
        { key: "read", label: "READ TEXT", hint: "", glyph: "\u{f0284}", dark: "#b8862a", light: "#f3c14f" },
        { key: "pick", label: "COLOUR", hint: "", glyph: "\u{f020a}", dark: "#cfd8ec", light: "#fdf8cd" },
        { key: "record", label: "RECORD", hint: "", glyph: "\u{f044a}", dark: "#b8233c", light: "#e8457a" }
    ].filter(t => t.key !== "read" || cutter.canRead)

    function screenOf(name: string): var {
        return Screens.list.find(s => s.name === name) || null;
    }
    function scaleOf(name: string): real {
        const s = cutter.screenOf(name);
        return s && s.devicePixelRatio > 0 ? s.devicePixelRatio : 1;
    }
    function geom(name: string, r: var): string {
        const k = cutter.scaleOf(name);
        return Math.max(1, Math.round(r.w * k)) + "x" + Math.max(1, Math.round(r.h * k)) + "+" + Math.round(r.x * k) + "+" + Math.round(r.y * k);
    }
    function frame(name: string): string {
        return cutter.frames[name] || "";
    }
    function stampName(): string {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd-HHmmss") + "_cutter";
    }
    function tilde(path: string): string {
        return cutter.home && path.startsWith(cutter.home) ? "~" + path.slice(cutter.home.length) : path;
    }

    function toggle(): void {
        if (cutter.phase === "")
            cutter.open();
        else if (cutter.phase === "record")
            cutter.stopRecord();
        else
            cutter.cancel();
    }
    function open(): void {
        if (cutter.phase !== "")
            return;
        const f = Hypr.focusedMonitor;
        cutter.keyScreen = Screens.list.some(s => s.name === f) ? f : (Screens.list.length ? Screens.list[0].name : "");
        cutter.stamp = String(Date.now());
        cutter.frames = {};
        cutter.rect = null;
        cutter.hover = null;
        cutter.screenName = cutter.keyScreen;
        cutter.frost = 0;
        cutter.cut = 0;
        cutter.melt = 0;
        cutter.gild = 0;
        cutter.taken = 0;
        cutter.toastTitle = "";
        cutter.toastText = "";
        cutter.swatch = "";
        cutter.filming = false;
        cutter.after = null;
        ending.stop();
        cutter.phase = "wait";
        freeze.command = ["sh", "-c", 'd=$1; s=$2; shift 2; umask 077; mkdir -p "$d" && chmod 700 "$d" && rm -f "$d"/*.ppm "$d"/cut.png || exit 1; p=""; for o; do grim -t ppm -o "$o" "$d/$o-$s.ppm" & p="$p $!"; done; for j in $p; do wait "$j" || exit 1; done', "sh", cutter.dir, cutter.stamp].concat(Screens.list.map(s => s.name));
        freeze.running = true;
    }
    function frozen(): void {
        const out = {};
        for (const s of Screens.list)
            out[s.name] = cutter.dir + "/" + s.name + "-" + cutter.stamp + ".ppm";
        cutter.frames = out;
        if (cutter.phase === "wait")
            cutter.phase = "freeze";
        Sfx.play("cutter-freeze", 0.9);
        frosting.restart();
    }
    function cancel(): void {
        if (cutter.phase === "" || cutter.phase === "thaw")
            return;
        if (cutter.phase === "pick") {
            cutter.phase = "cut";
            return;
        }
        if (cutter.phase === "record") {
            cutter.stopRecord();
            return;
        }
        cutter.after = null;
        ending.stop();
        Sfx.play("cutter-thaw", 0.9);
        cutter.finish(520);
    }
    function finish(ms: int): void {
        if (cutter.phase === "" || cutter.phase === "thaw")
            return;
        cutter.phase = "thaw";
        frosting.stop();
        thawing.duration = ms;
        thawing.restart();
    }
    function begin(name: string): void {
        cutter.screenName = name;
        cutter.cut = 0;
        cutter.gild = 0;
        cutter.phase = "drag";
    }
    function snap(name: string, r: var): void {
        const s = cutter.screenOf(name);
        if (!s)
            return;
        const x = Math.max(0, Math.min(s.width - 1, r.x));
        const y = Math.max(0, Math.min(s.height - 1, r.y));
        cutter.screenName = name;
        cutter.rect = { x: x, y: y, w: Math.max(1, Math.min(s.width - x, r.w - (x - r.x))), h: Math.max(1, Math.min(s.height - y, r.h - (y - r.y))) };
        cutter.hover = null;
        cutter.phase = "cut";
        Sfx.play("cutter-snap", 1);
        snapping.restart();
    }
    function whole(name: string): void {
        const s = cutter.screenOf(name);
        if (s)
            cutter.snap(name, { x: 0, y: 0, w: s.width, h: s.height });
    }
    function run(cmd: var, then: var): void {
        cutter.after = then;
        job.command = cmd;
        job.running = true;
    }
    function toast(title: string, text: string, ms: int): void {
        cutter.toastTitle = title;
        cutter.toastText = text;
        ending.interval = ms;
        ending.restart();
    }

    function key(k: int, ctrl: bool): bool {
        if (k === Qt.Key_Escape) {
            cutter.cancel();
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            if (cutter.phase === "freeze")
                cutter.whole(cutter.keyScreen);
            cutter.act("copy");
        } else if (k === Qt.Key_S && ctrl) {
            if (cutter.phase === "freeze")
                cutter.whole(cutter.keyScreen);
            cutter.act("save");
        } else {
            return false;
        }
        return true;
    }
    function act(key: string): void {
        if (cutter.phase !== "cut" || !cutter.rect || job.running || !cutter.frame(cutter.screenName))
            return;
        const src = cutter.frame(cutter.screenName);
        const g = cutter.geom(cutter.screenName, cutter.rect);
        const i = cutter.tools.findIndex(t => t.key === key);
        switch (key) {
        case "copy":
            Sfx.play("cutter-copy", 0.9);
            cutter.phase = "fly";
            cutter.taken = 1;
            cutter.run(["sh", "-c", 'magick "$1" -crop "$2" +repage png:- | wl-copy --type image/png', "sh", src, g], null);
            break;
        case "save": {
            const out = cutter.shots + "/" + cutter.stampName() + ".png";
            Sfx.play("cutter-save", 0.9);
            cutter.phase = "busy";
            gilding.restart();
            cutter.run(["sh", "-c", 'mkdir -p "$(dirname "$3")" && magick "$1" -crop "$2" +repage "$3"', "sh", src, g, out], ok => cutter.toast(ok ? "SAVED" : "NOT SAVED", cutter.tilde(out), 1100));
            break;
        }
        case "annotate": {
            const out = cutter.dir + "/cut.png";
            Sfx.play("cutter-annotate", 0.9);
            cutter.phase = "busy";
            cutter.run(["magick", src, "-crop", g, "+repage", out], ok => {
                cutter.finish(260);
                if (ok)
                    Quickshell.execDetached(["satty", "--filename", out, "--early-exit", "--initial-tool", "arrow", "--copy-command", "wl-copy"]);
            });
            break;
        }
        case "read":
            Sfx.play("cutter-ocr", 0.9);
            cutter.phase = "busy";
            gilding.restart();
            cutter.run(["sh", "-c", 'magick "$1" -crop "$2" +repage -colorspace Gray -resize 200% png:- | tesseract - - -l eng 2>/dev/null', "sh", src, g], (ok, text) => {
                const t = (text || "").replace(/\f/g, "").trim();
                if (t)
                    Quickshell.execDetached(["wl-copy", "--", t]);
                cutter.toast(t ? "TEXT COPIED" : "NO TEXT FOUND", t.split("\n").filter(l => l.trim()).slice(0, 3).join("  ·  ").slice(0, 140), t ? 1600 : 1100);
            });
            break;
        case "pick":
            Sfx.play("cutter-jewel-" + (i + 1), 0.8);
            cutter.phase = "pick";
            break;
        case "record":
            cutter.startRecord();
            break;
        }
    }
    function pickAt(name: string, x: real, y: real): void {
        if (cutter.phase !== "pick" || job.running)
            return;
        const k = cutter.scaleOf(name);
        cutter.screenName = name;
        cutter.phase = "busy";
        Sfx.play("cutter-pick", 0.9);
        cutter.run(["sh", "-c", 'magick "$1" -crop "1x1+$2+$3" +repage -depth 8 txt:- | grep -o "#[0-9A-Fa-f]\\{6\\}" | head -n 1', "sh", cutter.frame(name), String(Math.round(x * k)), String(Math.round(y * k))], (ok, text) => {
            const hex = (text || "").trim().toLowerCase();
            if (hex)
                Quickshell.execDetached(["wl-copy", "--", hex]);
            cutter.swatch = hex;
            cutter.toast(hex ? "COLOUR COPIED" : "NO COLOUR", hex, 1100);
        });
    }
    function startRecord(): void {
        const m = Hypr.monitors[cutter.screenName];
        if (!m || !cutter.rect)
            return;
        const r = cutter.rect;
        cutter.recordFile = cutter.films + "/" + cutter.stampName() + ".mp4";
        rec.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && exec wf-recorder -y -g "$1" -f "$2"', "sh", Math.round(m.x + r.x) + "," + Math.round(m.y + r.y) + " " + 2 * Math.round(r.w / 2) + "x" + 2 * Math.round(r.h / 2), cutter.recordFile];
        cutter.recordAt = Date.now();
        cutter.filming = true;
        cutter.phase = "record";
        Sfx.play("cutter-record", 0.9);
        rec.running = true;
    }
    function stopRecord(): void {
        if (cutter.phase !== "record")
            return;
        cutter.phase = "busy";
        if (rec.running)
            rec.signal(2);
        else
            cutter.recorded(1);
    }
    function recorded(code: int): void {
        Sfx.play("cutter-stop", 0.9);
        cutter.toast(code === 0 ? "RECORDED" : "RECORDING FAILED", cutter.tilde(cutter.recordFile), 1300);
    }

    NumberAnimation {
        id: frosting
        target: cutter
        property: "frost"
        from: 0
        to: 1
        duration: 420
        easing.type: Easing.OutCubic
    }
    NumberAnimation {
        id: snapping
        target: cutter
        property: "cut"
        from: 0
        to: 1
        duration: 260
        easing.type: Easing.OutCubic
    }
    NumberAnimation {
        id: gilding
        target: cutter
        property: "gild"
        from: 0
        to: 1
        duration: 320
        easing.type: Easing.OutQuad
    }
    NumberAnimation {
        id: thawing
        target: cutter
        property: "melt"
        from: 0
        to: 1
        easing.type: Easing.InQuad
        onFinished: {
            cutter.phase = "";
            cutter.frames = {};
        }
    }
    Timer {
        id: ending
        onTriggered: cutter.finish(380)
    }

    Process {
        id: freeze
        onExited: code => {
            if (cutter.phase === "" || cutter.phase === "thaw")
                return;
            if (code === 0)
                cutter.frozen();
            else
                cutter.phase = "";
        }
    }
    Process {
        id: job
        stdout: StdioCollector {
            id: jobOut
        }
        onExited: code => {
            const then = cutter.after;
            cutter.after = null;
            if (then)
                then(code === 0, jobOut.text);
        }
    }
    Process {
        id: rec
        onExited: code => {
            if (cutter.phase === "busy" || cutter.phase === "record")
                cutter.recorded(code === 0 || code === 130 ? 0 : code);
        }
    }
    Process {
        running: true
        command: ["sh", "-c", "command -v tesseract >/dev/null && tesseract --list-langs 2>/dev/null | grep -qx eng"]
        onExited: code => cutter.canRead = code === 0
    }

    Variants {
        model: cutter.phase !== "" ? Screens.list : []
        PanelWindow {
            id: win
            required property ShellScreen modelData
            readonly property bool keyed: win.modelData.name === cutter.keyScreen && !cutter.filming && cutter.phase !== "thaw" && !(Test.on && /^VSCREEN/.test(win.modelData.name))
            screen: win.modelData
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "glasshouse-cutter"
            WlrLayershell.keyboardFocus: win.keyed ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            mask: Region {
                item: cutter.filming ? (cutter.phase === "record" ? sheet.ruby : null) : cutter.phase === "thaw" ? null : sheet
            }

            Sheet {
                id: sheet
                anchors.fill: parent
                host: cutter
                name: win.modelData.name
                u: Screens.unit(win.modelData.name)
                focus: win.keyed
            }
        }
    }

    GlobalShortcut {
        appid: Test.on ? "glasshouse-test" : "glasshouse"
        name: "cutter"
        description: "The Cutter: the screen freezes under glass, cut a pane"
        onPressed: cutter.toggle()
    }

    IpcHandler {
        target: "cutter"
        function toggle(): void {
            cutter.toggle();
        }
        function open(): void {
            cutter.open();
        }
        function close(): void {
            cutter.cancel();
        }
        function key(name: string): string {
            if (!Test.on)
                return "test only";
            const m = name.match(/^(ctrl\+)?(.+)$/i);
            if (!m)
                return "unhandled";
            const k = { escape: Qt.Key_Escape, return: Qt.Key_Return, s: Qt.Key_S }[m[2].toLowerCase()];
            return k !== undefined && cutter.key(k, !!m[1]) ? "ok" : "unhandled";
        }
        function status(): string {
            return JSON.stringify({ phase: cutter.phase, screen: cutter.screenName, rect: cutter.rect, hover: cutter.hover, tools: cutter.tools.map(t => t.key), frames: cutter.frames });
        }
    }
}
