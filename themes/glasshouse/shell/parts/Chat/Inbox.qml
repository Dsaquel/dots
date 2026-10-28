pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Singleton {
    id: box

    readonly property int maxBubbles: 3
    readonly property int keepDays: 7
    readonly property int keepEntries: 300
    readonly property int keepTracked: 40

    readonly property alias stack: rows
    property string screen: ""
    property var entries: []
    property var objs: ({})
    property var acts: ({})
    property var refreshers: ({})
    property real seen: 0
    property bool threadOpen: false
    property bool hold: false
    property bool frozen: false
    property var held: []
    property int queued: 0
    property var queuedApps: ({})
    property bool loaded: false
    readonly property real midnight: {
        const d = clock.date;
        return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
    }
    readonly property var today: box.entries.filter(e => e.time >= box.midnight)
    readonly property int unread: box.today.filter(e => e.time > box.seen).length

    signal risen(string key, int urgency)

    function find(key: string): int {
        for (let i = 0; i < rows.count; i++)
            if (rows.get(i).key === key)
                return i;
        return -1;
    }

    function row(r: var): var {
        return {
            key: r.key,
            kind: r.kind || "message",
            app: r.app || "",
            icon: r.icon || "",
            image: r.image || "",
            summary: r.summary || "",
            body: r.body || "",
            urgency: r.urgency === undefined ? 1 : r.urgency,
            actions: JSON.stringify(r.actions || []),
            value: r.value === undefined ? -1 : r.value,
            timeout: r.timeout === undefined ? 6000 : r.timeout,
            sid: r.sid || "",
            state: r.state || "",
            time: r.time || Date.now(),
            born: Date.now(),
            stamp: Date.now(),
            touchedAt: Date.now(),
            leaving: false
        };
    }

    function post(r: var): string {
        r.time = r.time || Date.now();
        if (!r.transient)
            box.remember(r);
        if (r.act)
            box.acts[r.key] = r.act;
        if (box.hold) {
            box.held = box.held.filter(h => h.key !== r.key).concat([r]);
            return "held";
        }
        if (Settings.dnd && r.urgency < 2) {
            box.queued++;
            const q = Object.assign({}, box.queuedApps);
            const name = r.app || "Glasshouse";
            q[name] = (q[name] || 0) + 1;
            box.queuedApps = q;
            return "queued";
        }
        if (box.threadOpen) {
            box.ping(r);
            return "thread";
        }
        const fresh = box.show(r);
        if (fresh)
            box.ping(r);
        return fresh ? "shown" : "updated";
    }

    function ping(r: var): void {
        if (r.urgency === 0 || Settings.dnd)
            return;
        Sfx.play("notify", r.urgency >= 2 ? 1.0 : 0.8);
        if (r.kind === "error")
            Her.react("error", 9000);
        else if (r.kind === "message")
            Her.react("message", 6000);
        else if (r.kind === "info")
            Her.react("greet", 4000);
    }

    function show(r: var): bool {
        const i = box.find(r.key);
        if (i >= 0 && !rows.get(i).leaving) {
            const old = rows.get(i);
            const o = box.row(r);
            o.born = old.born;
            o.stamp = old.summary !== o.summary || o.urgency > old.urgency ? Date.now() : old.stamp;
            rows.set(i, o);
            return false;
        }
        if (i >= 0)
            rows.remove(i);
        rows.append(box.row(r));
        let alive = [];
        for (let j = 0; j < rows.count; j++)
            if (!rows.get(j).leaving)
                alive.push(rows.get(j));
        while (alive.length > box.maxBubbles) {
            const out = alive.find(x => x.urgency < 2 && x.key !== r.key) || alive[0];
            box.retire(out.key);
            alive = alive.filter(x => x.key !== out.key);
        }
        box.risen(r.key, r.urgency);
        return true;
    }

    function retire(key: string): void {
        const i = box.find(key);
        if (i >= 0 && !rows.get(i).leaving)
            rows.setProperty(i, "leaving", true);
    }
    function drop(key: string): void {
        const i = box.find(key);
        if (i >= 0 && rows.get(i).leaving)
            rows.remove(i);
    }

    function invoke(key: string, id: string): string {
        const n = box.objs[key];
        if (n) {
            const a = n.actions.find(x => x.identifier === id);
            if (!a)
                return "no action " + id;
            const keep = n.resident;
            a.invoke();
            if (!keep)
                box.retire(key);
            return "invoked " + id;
        }
        const f = box.acts[key];
        if (f) {
            f(id);
            box.retire(key);
            return "acted " + id;
        }
        return "gone";
    }
    function click(key: string): string {
        const n = box.objs[key];
        if (n && n.actions.some(x => x.identifier === "default"))
            return box.invoke(key, "default");
        if (!n && box.acts[key])
            return box.invoke(key, "default");
        box.dismiss(key);
        return "dismissed";
    }
    function dismiss(key: string): void {
        const n = box.objs[key];
        if (n)
            n.dismiss();
        box.retire(key);
    }
    function expire(key: string): void {
        box.retire(key);
        const live = Object.keys(box.objs);
        if (live.length > box.keepTracked) {
            const oldest = live.sort((x, y) => box.timeOf(x) - box.timeOf(y))[0];
            const n = box.objs[oldest];
            if (n)
                n.expire();
        }
    }
    function timeOf(key: string): real {
        const e = box.entries.find(x => x.key === key);
        return e ? e.time : 0;
    }

    function gone(key: string): void {
        delete box.objs[key];
        delete box.refreshers[key];
        box.retire(key);
        const i = box.entries.findIndex(e => e.key === key);
        if (i >= 0 && box.entries[i].live) {
            const list = box.entries.slice();
            const e = list[i];
            list[i] = Object.assign({}, e, { live: false, image: (e.image || "").startsWith("file://") ? e.image : "" });
            box.entries = list;
        }
    }

    function forget(key: string): void {
        const n = box.objs[key];
        if (n)
            n.dismiss();
        box.retire(key);
        delete box.acts[key];
        box.entries = box.entries.filter(e => e.key !== key);
        box.save();
    }

    function clearAll(): void {
        for (const k of Object.keys(box.objs)) {
            const n = box.objs[k];
            if (n)
                n.dismiss();
        }
        for (let i = 0; i < rows.count; i++)
            box.retire(rows.get(i).key);
        box.entries = [];
        box.acts = {};
        box.queued = 0;
        box.queuedApps = {};
        box.save();
    }

    function markSeen(): void {
        box.seen = Date.now();
        box.save();
    }

    function remember(r: var): void {
        const keep = {
            key: r.key,
            kind: r.kind || "message",
            app: r.app || "",
            appKey: r.appKey || (r.app || "glasshouse").toLowerCase(),
            icon: r.icon || "",
            image: r.image || "",
            summary: r.summary || "",
            body: r.body || "",
            urgency: r.urgency === undefined ? 1 : r.urgency,
            time: r.time,
            sid: r.sid || "",
            state: r.state || "",
            actions: r.actions || [],
            live: !!box.objs[r.key] || !!r.act
        };
        const cut = Date.now() - box.keepDays * 86400000;
        const list = box.entries.filter(e => e.key !== r.key && e.time > cut);
        list.push(keep);
        box.entries = list.slice(-box.keepEntries);
        box.save();
    }

    function save(): void {
        if (box.loaded)
            saver.restart();
    }

    Timer {
        id: saver
        interval: 1200
        onTriggered: file.setText(JSON.stringify({ version: 1, seen: box.seen, entries: box.entries.map(e => Object.assign({}, e, { live: false, image: (e.image || "").startsWith("file://") ? e.image : "" })) }))
    }

    FileView {
        id: file
        path: Settings.dir + "/notifications.json"
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text() || "{}");
                const cut = Date.now() - box.keepDays * 86400000;
                box.entries = (d.entries || []).filter(e => e && e.key && e.time > cut).map(e => Object.assign({}, e, { live: false }));
                box.seen = d.seen || 0;
            } catch (e) {
                box.entries = [];
            }
            box.loaded = true;
        }
        onLoadFailed: box.loaded = true
    }

    Connections {
        target: Settings
        function onDndChanged(): void {
            if (Settings.dnd || box.queued === 0)
                return;
            const apps = Object.keys(box.queuedApps).map(a => box.queuedApps[a] > 1 ? a + " " + box.queuedApps[a] : a);
            const n = box.queued;
            box.queued = 0;
            box.queuedApps = {};
            box.post({
                key: "wake-" + Date.now(),
                kind: "info",
                app: "While you rested",
                appKey: "glasshouse",
                summary: n === 1 ? "One message came" : n + " messages came",
                body: apps.join("  ·  "),
                urgency: 1,
                timeout: 9000,
                transient: true,
                actions: [{ id: "thread", label: "Read them" }],
                act: id => Bus.thread()
            });
        }
    }
    onHoldChanged: {
        if (box.hold)
            return;
        const list = box.held.slice(-box.maxBubbles);
        box.held = [];
        list.forEach((r, i) => {
            if (box.show(r) && i === list.length - 1)
                box.ping(r);
        });
    }

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    ListModel {
        id: rows
    }
}
