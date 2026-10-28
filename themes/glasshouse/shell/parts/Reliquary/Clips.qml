import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Scope {
    id: clips

    property var entries: []
    property var thumbs: ({})
    readonly property string db: Test.on ? Settings.dir + "/cliphist-test.db" : ""
    readonly property string thumbDir: Test.on ? Settings.dir + "/clip-thumbs" : (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/glasshouse/clip-thumbs"

    function cliphist(args: var): var {
        return clips.db ? ["cliphist", "-db-path", clips.db].concat(args) : ["cliphist"].concat(args);
    }
    function load(): void {
        lister.running = false;
        lister.running = true;
    }
    function kindOf(text: string): string {
        if (/^#(?:[0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(text))
            return "colour";
        if (/^(?:https?|ftp|file):\/\/\S+$/i.test(text))
            return "link";
        if (/^~?\/\S+$/.test(text))
            return "path";
        return "text";
    }
    function thumbName(e: var): string {
        return e.id + "-" + e.w + "x" + e.h + "-" + e.size.replace(/\W/g, "");
    }
    function parse(text: string): void {
        const list = [];
        for (const line of text.split("\n")) {
            const tab = line.indexOf("\t");
            if (tab <= 0)
                continue;
            const id = line.slice(0, tab);
            const prev = line.slice(tab + 1);
            const m = prev.match(/^\[\[ binary data (.+?) (png|jpeg|jpg|webp|gif|bmp) (\d+)x(\d+) \]\]$/);
            if (m) {
                const ext = m[2] === "jpeg" ? "jpg" : m[2];
                list.push({ id: id, image: true, kind: "image", ext: ext, mime: "image/" + (ext === "jpg" ? "jpeg" : ext), size: m[1], w: Number(m[3]), h: Number(m[4]), text: "" });
            } else {
                const t = prev.replace(/\s+/g, " ").trim();
                list.push({ id: id, image: false, kind: clips.kindOf(t), mime: "text/plain;charset=utf-8", text: t });
            }
            if (list.length >= 200)
                break;
        }
        clips.entries = list;
        const imgs = list.filter(e => e.image).slice(0, 24);
        if (imgs.length) {
            decoder.command = ["sh", "-c", 'umask 077; mkdir -p "$1" && chmod 700 "$1" && cd "$1" && shift && db="$1" && shift && keep=" $* " && for a in "$@"; do key=${a%%:*}; id=${a#*:}; [ -s "$key.img" ] || { if [ -n "$db" ]; then cliphist -db-path "$db" decode "$id"; else cliphist decode "$id"; fi > "$key.img" 2>/dev/null; }; done; for f in *.img; do [ -e "$f" ] || continue; case "$keep" in *" ${f%.img}:"*) ;; *) rm -f "$f" ;; esac; done', "sh", clips.thumbDir, clips.db].concat(imgs.map(e => clips.thumbName(e) + ":" + e.id));
            decoder.running = true;
        }
    }
    function search(query: string): var {
        const q = query.trim().toLowerCase();
        const rows = clips.entries.filter(e => !q || (e.image ? ("image " + e.ext + " " + e.w + "x" + e.h).indexOf(q) >= 0 : e.text.toLowerCase().indexOf(q) >= 0));
        return rows.map(e => ({
                    key: "clip" + e.id,
                    clip: e,
                    thumb: e.image ? (clips.thumbs[e.id] || "") : ""
                }));
    }
    Process {
        id: lister
        command: clips.cliphist(["list"])
        stdout: StdioCollector {
            onStreamFinished: clips.parse(text)
        }
    }
    Process {
        id: decoder
        onExited: {
            const t = {};
            for (const e of clips.entries)
                if (e.image)
                    t[e.id] = "file://" + clips.thumbDir + "/" + clips.thumbName(e) + ".img";
            clips.thumbs = t;
        }
    }
}
