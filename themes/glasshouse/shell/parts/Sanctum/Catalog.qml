import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Scope {
    id: cat

    property var recent: ({})
    property var foreign: ({})
    readonly property var apps: DesktopEntries.applications.values.filter(e => !e.noDisplay && !cat.foreign[e.id])

    function list(v: var): var {
        return String(v || "").split(/[;,]/).map(x => x.trim()).filter(x => x);
    }
    function words(v: var): string {
        return cat.list(v).join(" ");
    }
    readonly property var silent: ["GTK", "Qt", "KDE", "GNOME", "XFCE", "LXQt", "MATE", "Application", "Core"]
    readonly property var broad: ["Utility", "Settings", "System"]
    function sub(e: var): string {
        if (e.genericName)
            return e.genericName;
        const cats = cat.list(e.categories).filter(c => !c.startsWith("X-") && cat.silent.indexOf(c) < 0);
        const specific = cats.filter(c => cat.broad.indexOf(c) < 0);
        if (specific.length)
            return specific[0].replace(/([a-z])([A-Z])/g, "$1 $2");
        if (e.comment && e.comment.length <= 36)
            return e.comment;
        return cats.length ? cats[0] : "";
    }
    function row(e: var): var {
        return { key: e.id, title: e.name, sub: cat.sub(e), icon: e.icon || "", entry: e };
    }
    function score(q: string, e: var): real {
        const name = (e.name || "").toLowerCase();
        if (name === q)
            return 1000;
        if (name.startsWith(q))
            return 900 - name.length;
        const parts = name.split(/[\s\-_.:]+/);
        if (parts.some(w => w.startsWith(q)))
            return 760 - name.length;
        const at = name.indexOf(q);
        if (at >= 0)
            return 600 - at;
        const other = [e.genericName, cat.words(e.keywords), e.id, cat.words(e.categories)].join(" ").toLowerCase();
        if (other.indexOf(q) >= 0)
            return 420 - Math.min(100, other.indexOf(q));
        let pos = 0;
        let last = -1;
        let gaps = 0;
        for (const ch of q) {
            const k = name.indexOf(ch, pos);
            if (k < 0)
                return -1;
            if (last >= 0)
                gaps += k - last - 1;
            last = k;
            pos = k + 1;
        }
        return 300 - gaps * 6 - name.length;
    }
    function lift(e: var): real {
        const t = cat.recent[e.id] || 0;
        if (!t)
            return 0;
        const days = (Date.now() - t) / 86400000;
        return Math.max(0, 80 - days * 2.6);
    }
    function search(query: string): var {
        const q = query.trim().toLowerCase();
        if (!q)
            return cat.apps.slice().sort((a, b) => (cat.recent[b.id] || 0) - (cat.recent[a.id] || 0) || a.name.localeCompare(b.name)).map(cat.row);
        const hits = [];
        for (const e of cat.apps) {
            const s = cat.score(q, e);
            if (s > 0)
                hits.push({ e: e, s: s + cat.lift(e) });
        }
        hits.sort((x, y) => y.s - x.s || x.e.name.localeCompare(y.e.name));
        return hits.map(h => cat.row(h.e));
    }
    function used(id: string): void {
        const next = Object.assign({}, cat.recent);
        next[id] = Date.now();
        cat.recent = next;
        store.setText(JSON.stringify(next));
    }

    Process {
        running: true
        command: ["sh", "-c", 'for d in "${XDG_DATA_HOME:-$HOME/.local/share}" $(printf %s "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" | tr : " "); do find "$d/applications" -maxdepth 1 -name "*.desktop" -print0 2>/dev/null; done | xargs -0 -r awk -F= \'FNR == 1 { id = FILENAME; sub(/.*\\//, "", id); sub(/\\.desktop$/, "", id); skip = (id in seen); seen[id] = 1; grp = "" } /^\\[/ { grp = $0 } !skip && grp == "[Desktop Entry]" && /^(OnlyShowIn|NotShowIn)=/ { print id "|" $1 "|" $2 }\'']
        stdout: StdioCollector {
            onStreamFinished: {
                const here = (Quickshell.env("XDG_CURRENT_DESKTOP") || "Hyprland").split(":");
                const out = {};
                for (const line of text.split("\n")) {
                    const f = line.split("|");
                    if (f.length < 3)
                        continue;
                    const listed = cat.list(f[2]).some(d => here.indexOf(d) >= 0);
                    if ((f[1] === "OnlyShowIn" && !listed) || (f[1] === "NotShowIn" && listed))
                        out[f[0]] = true;
                }
                cat.foreign = out;
            }
        }
    }

    FileView {
        id: store
        path: Settings.dir + "/recent.json"
        printErrors: false
        onLoaded: {
            try {
                cat.recent = JSON.parse(text()) || {};
            } catch (e) {
                cat.recent = {};
            }
        }
    }
}
