import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.core
import qs.parts.Lancet

Scope {
    id: part

    readonly property string busAddress: Quickshell.env("DBUS_SESSION_BUS_ADDRESS") || ""
    readonly property bool privateBus: Quickshell.env("GLASSHOUSE_CHAT_BUS") === "private" && part.busAddress !== "" && part.busAddress !== "unix:path=" + Quickshell.env("XDG_RUNTIME_DIR") + "/bus"
    readonly property bool serve: !Test.on || part.privateBus
    property string testScreen: ""
    property var working: ({})
    property string lastAct: ""
    property int serial: 0
    readonly property string mainScreen: {
        const m = Screens.list.find(s => Screens.role(s.name) === "main");
        return m ? m.name : (Screens.list.length ? Screens.list[0].name : "");
    }

    Binding {
        target: Her
        property: "unread"
        value: Inbox.unread
    }

    function target(): string {
        if (Test.on && part.testScreen !== "")
            return part.testScreen;
        const f = Hypr.focusedMonitor;
        return Screens.list.some(s => s.name === f) ? f : part.mainScreen;
    }
    function post(r: var): string {
        Inbox.screen = part.target();
        return Inbox.post(r);
    }

    function themed(name: string): string {
        return name && Quickshell.hasThemeIcon(name) ? Quickshell.iconPath(name) : "";
    }
    function fileUrl(p: string): string {
        return p.startsWith("file://") ? p : (p.startsWith("/") ? "file://" + p : "");
    }
    function iconFile(path: string): bool {
        return /\/icons\/|\.svg$/i.test(path);
    }
    function iconOf(n: var): string {
        const ai = n.appIcon || "";
        let u = ai.startsWith("/") || ai.startsWith("file://") ? part.fileUrl(ai) : part.themed(ai);
        if (u)
            return u;
        const img = n.image || "";
        if (img.startsWith("image://icon//") && part.iconFile(img.slice(13)))
            return "file://" + img.slice(13);
        if (img.startsWith("image://icon/") && !img.startsWith("image://icon//")) {
            u = part.themed(img.slice(13));
            if (u)
                return u;
        }
        const e = n.desktopEntry ? DesktopEntries.byId(n.desktopEntry) : DesktopEntries.heuristicLookup(n.appName || "");
        if (e && e.icon) {
            u = e.icon.startsWith("/") ? part.fileUrl(e.icon) : part.themed(e.icon);
            if (u)
                return u;
        }
        return part.themed((n.appName || "").toLowerCase());
    }
    function imageOf(n: var): string {
        const img = n.image || "";
        if (!img || (img.startsWith("image://icon/") && !img.startsWith("image://icon//")))
            return "";
        if (img.startsWith("image://icon//"))
            return part.iconFile(img.slice(13)) ? "" : "file://" + img.slice(13);
        return img;
    }
    function timeoutOf(n: var): int {
        if (n.urgency === NotificationUrgency.Critical || n.resident || n.expireTimeout === 0)
            return 0;
        if (n.expireTimeout > 0)
            return Math.max(2500, Math.min(30000, n.expireTimeout));
        return n.urgency === NotificationUrgency.Low ? 4500 : 6000;
    }
    function lineOf(n: var, key: string): var {
        const e = n.desktopEntry ? DesktopEntries.byId(n.desktopEntry) : null;
        const v = n.hints ? n.hints.value : undefined;
        return part.house(n, {
            key: key,
            kind: n.urgency === NotificationUrgency.Critical ? "error" : (n.urgency === NotificationUrgency.Low ? "low" : "message"),
            app: n.appName || (e ? e.name : "") || "Notification",
            appKey: (n.desktopEntry || n.appName || "app").toLowerCase(),
            icon: part.iconOf(n),
            image: part.imageOf(n),
            summary: n.summary || "",
            body: n.body || "",
            urgency: n.urgency,
            actions: n.actions.map(a => ({ id: a.identifier, label: a.text })),
            value: typeof v === "number" ? Math.round(v) : -1,
            timeout: part.timeoutOf(n),
            transient: n.transient,
            resident: n.resident
        });
    }

    function house(n: var, r: var): var {
        if (n.appName !== "the house")
            return r;
        Object.assign(r, { app: "Glasshouse", appKey: "glasshouse", icon: "", kind: r.urgency >= 2 ? "error" : "info" });
        if (n.summary === "Claude Code") {
            if (Agents.sessions.length > 0)
                return null;
            const needs = n.urgency === NotificationUrgency.Critical || /permission|waiting/i.test(n.body || "");
            return Object.assign(r, { app: "Claude", appKey: "claude", kind: needs ? "needs" : "done", summary: n.body || (needs ? "Waiting for your answer" : "Turn complete"), body: "", urgency: 1, timeout: needs ? 0 : 6000 });
        }
        const sw = (n.summary || "").match(/^Theme switched: (\w+)/);
        if (sw) {
            const relaunch = ((n.body || "").match(/Relaunch needed: ([^.]+)/) || [])[1] || "";
            return Object.assign(r, { summary: sw[1] === "light" ? "Turned to Rubedo Light" : "Turned to Rubedo Dark", body: relaunch ? "Relaunch " + relaunch + " to follow it" : "", timeout: 5000 });
        }
        if (/^Theme switch FAILED/.test(n.summary || "")) {
            const back = ((n.body || "").match(/Reverted to (\w+)/) || [])[1] || "";
            const log = ((n.body || "").match(/See (\S+?)\.?$/) || [])[1] || "";
            return Object.assign(r, { summary: "The theme switch failed", body: (back ? "Back in " + (back === "light" ? "Rubedo Light" : "Rubedo Dark") + ". " : "") + (log ? "The log: " + log : ""), kind: "error", urgency: 2, timeout: 0 });
        }
        return r;
    }

    function receive(n: var): void {
        const key = "n" + n.id + "-" + Date.now().toString(36);
        const first = part.lineOf(n, key);
        if (!first) {
            n.dismiss();
            return;
        }
        n.tracked = true;
        Inbox.objs[key] = n;
        n.closed.connect(() => Inbox.gone(key));
        const refresh = () => {
            if (!Inbox.objs[key])
                return;
            const r = part.lineOf(n, key);
            if (!r)
                return;
            r.time = Date.now();
            Inbox.remember(r);
            if (Inbox.find(key) >= 0 || !Settings.dnd)
                Inbox.show(r);
        };
        Inbox.refreshers[key] = () => Qt.callLater(refresh);
        for (const sig of [n.summaryChanged, n.bodyChanged, n.appIconChanged, n.imageChanged, n.actionsChanged, n.urgencyChanged, n.hintsChanged])
            sig.connect(Inbox.refreshers[key]);
        part.post(first);
    }

    LazyLoader {
        active: part.serve
        NotificationServer {
            keepOnReload: false
            actionsSupported: true
            bodySupported: true
            bodyMarkupSupported: true
            imageSupported: true
            persistenceSupported: true
            onNotification: n => part.receive(n)
        }
    }

    function vialFocus(s: var): void {
        const t = Gauges.terminalOf(s);
        part.lastAct = JSON.stringify({ sid: s.sid, terminal: t });
        if (t && !Test.on)
            Hypr.focusWindow(t.address);
    }
    function elapsed(ms: real): string {
        const s = Math.round(ms / 1000);
        if (s < 60)
            return s + " s";
        const m = Math.round(s / 60);
        return m < 60 ? m + " min" : Math.floor(m / 60) + " h " + String(m % 60).padStart(2, "0");
    }
    function agentSummary(s: var, state: string): string {
        if (s.detail && state !== "working")
            return s.detail;
        const since = part.working[s.sid];
        switch (state) {
        case "needs":
            return "Waiting for your answer";
        case "done":
            return since && s.updated > since ? "Finished after " + part.elapsed(s.updated - since) : "Finished";
        case "working":
            return "Brewing for " + part.elapsed(Date.now() - (s.since || s.updated));
        default:
            return "Waiting for a prompt";
        }
    }
    function agentLine(s: var, state: string, asked: bool): string {
        const t = Gauges.terminalOf(s);
        if (!asked && t && t.address === Hypr.active && !Test.on)
            return "looking";
        return part.post({
            key: "a:" + s.sid,
            kind: state,
            app: s.label || "claude",
            appKey: "claude:" + (s.label || "claude"),
            summary: part.agentSummary(s, state),
            body: "",
            urgency: 1,
            sid: s.sid,
            state: state,
            timeout: state === "needs" ? 0 : 6000,
            transient: asked,
            actions: t ? [{ id: "open", label: "Open" }] : [],
            act: id => part.vialFocus(s)
        });
    }
    Connections {
        target: Agents
        function onChanged(session: var, previous: string): void {
            if (previous === "needs" && session.state !== "needs")
                Inbox.retire("a:" + session.sid);
            if (session.state === "working") {
                if (previous !== "working" && previous !== "needs") {
                    const w = Object.assign({}, part.working);
                    w[session.sid] = session.updated;
                    part.working = w;
                }
                return;
            }
            if (!previous)
                return;
            if (session.state === "needs" && previous !== "needs")
                part.agentLine(session, "needs", false);
            else if (session.state === "done" && previous === "working")
                part.agentLine(session, "done", false);
        }
        function onSessionsChanged(): void {
            for (let i = 0; i < Inbox.stack.count; i++) {
                const r = Inbox.stack.get(i);
                if (r.sid && !Agents.sessions.some(s => s.sid === r.sid))
                    Inbox.retire(r.key);
            }
        }
    }

    Connections {
        target: Bus
        function onSay(b: var): void {
            part.say(b);
        }
        function onThread(): void {
            part.thread();
        }
    }
    function say(b: var): string {
        const kind = b.kind || "info";
        if (kind === "agent" && b.sid) {
            const s = Agents.sessions.find(x => x.sid === b.sid) || { sid: b.sid, label: b.title, detail: b.body, state: "idle", updated: Date.now() };
            const state = ["needs", "done", "working", "idle"].indexOf(s.state) >= 0 ? s.state : "idle";
            return part.agentLine(Object.assign({}, s, { label: b.title || s.label, detail: b.body || s.detail }), state, true);
        }
        part.serial++;
        return part.post({
            key: b.key || "s" + part.serial + "-" + Date.now().toString(36),
            kind: kind === "error" ? "error" : "info",
            app: b.app || "Glasshouse",
            appKey: "glasshouse",
            icon: b.icon || "",
            summary: b.title || "",
            body: b.body || "",
            urgency: kind === "error" ? 2 : 1,
            timeout: kind === "error" ? 0 : 7000,
            actions: b.actions || [],
            act: b.act
        });
    }

    property bool threadOn: false
    property bool threadShown: false
    property real threadSeen: 0
    signal threadScroll(real dy)
    readonly property var threadScreen: Screens.list.find(s => s.name === part.mainScreen) || null

    property real dismissedAt: 0
    function thread(): void {
        if (!part.threadOn && Date.now() - part.dismissedAt < 400)
            return;
        part.threadOn ? part.closeThread() : part.openThread();
    }
    function openThread(): void {
        if (part.threadOn || !part.threadScreen)
            return;
        part.threadSeen = Inbox.seen;
        part.threadOn = true;
        part.threadShown = true;
        Inbox.threadOpen = true;
        for (let i = 0; i < Inbox.stack.count; i++)
            Inbox.retire(Inbox.stack.get(i).key);
        Inbox.markSeen();
        Sfx.play("menu-open", 0.7);
    }
    function closeThread(): void {
        if (!part.threadOn)
            return;
        part.threadOn = false;
        Inbox.threadOpen = false;
        Inbox.markSeen();
        Sfx.play("menu-close", 0.7);
    }

    LazyLoader {
        active: part.threadShown && !!part.threadScreen
        Thread {
            id: thr
            modelData: part.threadScreen
            open: part.threadOn
            seenAt: part.threadSeen
            onDismiss: {
                part.dismissedAt = Date.now();
                part.closeThread();
            }
            onSunk: part.threadShown = false
            Connections {
                target: part
                function onThreadScroll(dy: real): void {
                    thr.scroll(dy);
                }
            }
        }
    }

    IpcHandler {
        target: "chat"
        function thread(): void {
            part.thread();
        }
        function dnd(): void {
            Settings.dnd = !Settings.dnd;
        }
        function clear(): void {
            Inbox.clearAll();
        }
        function say(title: string, body: string, kind: string): string {
            return part.say({ title: title, body: body, kind: kind || "info" });
        }
        function dump(): string {
            const rows = [];
            for (let i = 0; i < Inbox.stack.count; i++) {
                const r = Inbox.stack.get(i);
                rows.push({ key: r.key, kind: r.kind, app: r.app, summary: r.summary, leaving: r.leaving, timeout: r.timeout, urgency: r.urgency });
            }
            return JSON.stringify({ serve: part.serve, screen: Inbox.screen, stack: rows, today: Inbox.today.length, entries: Inbox.entries.length, unread: Inbox.unread, queued: Inbox.queued, tracked: Object.keys(Inbox.objs).length, dnd: Settings.dnd, thread: part.threadOn, lastAct: part.lastAct });
        }
        function screen(name: string): void {
            if (Test.on)
                part.testScreen = name;
        }
        function click(key: string): string {
            return Test.on ? Inbox.click(part.resolve(key)) : "test only";
        }
        function act(key: string, id: string): string {
            return Test.on ? Inbox.invoke(part.resolve(key), id) : "test only";
        }
        function dismiss(key: string): void {
            if (Test.on)
                Inbox.dismiss(part.resolve(key));
        }
        function scroll(dy: real): void {
            if (Test.on)
                part.threadScroll(dy);
        }
        function hold(on: bool): void {
            if (Test.on)
                Inbox.hold = on;
        }
        function freeze(on: bool): void {
            if (Test.on)
                Inbox.frozen = on;
        }
        function key(which: string): string {
            return part.resolve(which);
        }
    }
    function resolve(which: string): string {
        const n = Inbox.stack.count;
        if (which === "newest")
            return n ? Inbox.stack.get(n - 1).key : "";
        if (which === "oldest")
            return n ? Inbox.stack.get(0).key : "";
        if (/^\d+$/.test(which))
            return Number(which) < n ? Inbox.stack.get(Number(which)).key : "";
        return which;
    }

    Variants {
        model: Screens.list
        Stack {}
    }
}
