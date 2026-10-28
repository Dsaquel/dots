import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.core

Scope {
    id: part

    property bool on: true
    property var arts: ({})
    readonly property var meta: part.arts[World.name] || null
    readonly property string atlasUrl: part.meta ? "file://" + Assets.root + "/sill/" + part.meta.world + ".png" : ""
    property int size: 0
    readonly property real scaleBy: part.meta && part.size > 0 ? part.size / (part.meta.seat[1] - part.meta.top) : 1
    readonly property real reach: part.meta ? (part.meta.seat[1] - part.meta.top) * part.scaleBy : 0
    readonly property real legs: part.meta ? (part.meta.bottom - part.meta.seat[1]) * part.scaleBy : 0
    readonly property real footL: part.meta ? (part.meta.seat[0] - part.meta.foot[0]) * part.scaleBy : 0
    readonly property real footR: part.meta ? (part.meta.foot[1] - part.meta.seat[0]) * part.scaleBy : 0
    readonly property real spanL: part.meta ? part.meta.seat[0] * part.scaleBy : 0
    readonly property real spanR: part.meta ? (part.meta.w - part.meta.seat[0]) * part.scaleBy : 0
    readonly property color light: Theme.dark ? "#a9bcff" : "#ffc366"
    readonly property bool playing: Mpris.players.values.some(p => p.isPlaying && (!Test.on || (p.dbusName || "").indexOf("glasshouse_test") >= 0))
    readonly property int frames: part.meta ? part.meta.count : 1
    readonly property bool video: !!part.meta && !!part.meta.video
    readonly property string videoUrl: part.video ? "file://" + Assets.root + "/sill/" + part.meta.video : ""
    property var reels: ({})
    property bool warm: true
    property int cold: 0
    property string reelTo: "perch"
    readonly property var reelTarget: {
        const m = part.reelTo === "flight" ? survey.monAt(part.ax + part.slideX, part.ay + part.slideY - part.lift) : null;
        const name = m ? m.name : (part.perchBox ? part.perchBox.screen : "");
        const own = Object.keys(part.reels).filter(k => k.indexOf(part.reelTo + ":") === 0);
        return part.reels[part.reelTo + ":" + name] || (own.length > 0 ? part.reels[own[0]] : null);
    }

    property string mode: "away"
    property var rec: null
    property real seatX: 0
    property real seatY: 0
    property real ax: 0
    property real ay: 0
    property real lift: 0
    property real tilt: 0
    property real slideX: 0
    property real slideY: 0
    property real alpha: 1
    property real revealUp: 1
    property real revealDown: 1
    property real heat: 0
    property real glow: 0
    property real shadow: 1
    property bool flip: false
    property int frame: 0
    property var occ: []
    property var ground: null
    property bool perchOn: false
    property var perchBox: null
    property bool flightOn: false
    property bool perchHide: false
    property real grabDX: 0
    property real dragTravel: -1
    property real dragLastX: 0
    property double grabAt: 0
    property var flightScreens: []
    property var handoverThen: null
    property int waited: 0
    readonly property int pool: 40
    property var motes: []
    property int moteHead: 0
    property double motesUntil: 0
    property double now: 0
    property var tracks: []
    property double trackAt: 0
    property var trackThen: null
    property bool springing: false
    property var target: null
    property double targetAt: 0
    property double springAt: 0
    property real vx: 0
    property real vy: 0
    property real hopP: 0
    property var hopFrom: null
    property var hopTo: null
    property real hopH: 0
    property bool looping: false
    property int loopsLeft: 0
    property bool again: false
    property var lastMons: ({})
    property var events: ({})
    property var glazes: ({})
    property var landing: null
    property var born: ({})
    property var testScratch: ({})
    property var testHidden: ({})
    readonly property bool ticking: part.tracks.length > 0 || part.springing || part.now < part.motesUntil
    readonly property int step: {
        const m = part.rec ? Hypr.monitors[part.rec.monitor] : null;
        const r = m ? m.rate : 60;
        return Math.max(1, Math.floor(1000 / r * Math.max(1, Math.floor(r / 60))));
    }

    Anim {
        id: anim
    }

    Survey {
        id: survey
        her: part
        memory: spots
        specialIn: anim.specialIn
    }

    function heard(data: string): void {
        const f = data.split(",");
        const cues = f.slice(2).map(c => c.split("@"));
        const slam = cues.find(c => c[0] === "glaze-slam" || c[0] === "slam");
        const stone = cues.find(c => /^glaze-\d/.test(c[0]) || c[0].indexOf("stone") >= 0);
        const r = part.rec && part.rec.special && part.rec.wsName === f[1] ? part.rec : null;
        const was = r ? survey.glazeOf(r) : null;
        const g = Object.assign({}, part.glazes);
        g[f[1]] = { at: Date.now(), slam: slam ? Number(slam[1]) : -1, from: stone ? Number(stone[1]) : 0 };
        part.glazes = g;
        if (!r)
            return;
        const e = survey.fresh(r.monitor);
        if (slam && (part.mode === "wait" || (part.mode === "arrive" && part.landing)))
            part.arrive(r, survey.how(r));
        else if (part.mode === "leave" && !was && e && e.kind === "special-out")
            part.leave(survey.why(r, null), null);
    }

    function think(): void {
        if (!part.meta)
            return;
        const now = Date.now();
        const mons = {};
        for (const n in Hypr.monitors)
            mons[n] = { ws: Hypr.monitors[n].ws, special: Hypr.monitors[n].special };
        for (const n in mons) {
            const p = part.lastMons[n];
            if (!p)
                continue;
            if (p.ws !== mons[n].ws)
                part.events[n] = { kind: "ws", dir: mons[n].ws >= p.ws ? 1 : -1, at: now };
            else if (p.special !== mons[n].special)
                part.events[n] = { kind: mons[n].special !== "" ? "special-in" : "special-out", at: now };
        }
        part.lastMons = mons;
        const all = survey.shownAll();
        const next = survey.choose(all);
        if (part.mode === "arrive" && part.rec && (!next || next.address !== part.rec.address) && !all.some(w => w.address === part.rec.address)) {
            part.again = false;
            part.leave(survey.why(part.rec, null), null);
            return;
        }
        if (part.mode === "leave" || part.mode === "arrive" || part.mode === "drag") {
            part.again = true;
            return;
        }
        if (part.mode === "wait") {
            if (!next || next.address !== part.rec.address) {
                part.away();
                Qt.callLater(part.think);
            } else {
                part.rec = next;
            }
            return;
        }
        const cur = part.rec;
        const here = cur ? all.find(w => w.address === cur.address) || null : null;
        if (!next) {
            if (cur)
                part.leave(survey.why(cur, here), null);
            return;
        }
        if (!cur || part.mode === "away") {
            part.arrive(next, survey.how(next));
            return;
        }
        if (next.address !== cur.address) {
            const w = survey.why(cur, here);
            const e = survey.fresh(next.monitor);
            if (here || part.mode === "hop" || part.mode === "float" || w.kind === "closed" || (w.kind === "ws" && e && e.kind === "ws"))
                part.hop(next);
            else
                part.leave(w, () => part.think());
            return;
        }
        part.rec = next;
        if (part.mode === "seated" || part.mode === "float") {
            const s = next.seat;
            if (Math.abs(s.x - part.seatX) > 1.5 || Math.abs(s.y - part.seatY) > 1.5)
                part.float(s);
            else if (part.mode === "seated")
                part.track(next);
        } else if (part.mode === "hop" && (Math.abs(next.seat.x - part.hopTo.x) > 1.5 || Math.abs(next.seat.y - part.hopTo.y) > 1.5)) {
            part.hopTo = { x: next.seat.x, y: next.seat.y };
            part.seatX = next.seat.x;
            part.seatY = next.seat.y;
        }
    }

    function same(a: var, b: var): bool {
        return JSON.stringify(a) === JSON.stringify(b);
    }
    function track(w: var): void {
        if (!w) {
            if (part.ground !== null)
                part.ground = null;
            if (part.occ.length > 0)
                part.occ = [];
            return;
        }
        const c = survey.cameOf(w);
        const g = { x: w.x - c, y: w.y - c, w: w.w + 2 * c, h: w.h + 2 * c };
        const b = survey.boxAt(part.seatX, part.seatY, part.flip);
        const o = (w.shown || []).filter(x => x.address !== w.address && survey.isAbove(x, w) && x.x < b.x + b.w + 8 && x.x + x.w > b.x - 8 && x.y < b.y + b.h + 8 && x.y + x.h > b.y - 8).slice(0, 4).map(x => ({ x: x.x, y: x.y, w: x.w, h: x.h }));
        if (!part.same(g, part.ground))
            part.ground = g;
        if (!part.same(o, part.occ))
            part.occ = o;
    }

    function toPerch(box: var): void {
        part.perchBox = box;
        part.perchOn = true;
        if (!part.perchHide)
            part.reelTo = "perch";
        if (part.flightOn) {
            part.handoverThen = () => {
                if (!part.perchHide) {
                    part.flightOn = false;
                    return;
                }
                part.perchHide = false;
                part.reelTo = "perch";
                part.handoverThen = () => {
                    part.flightOn = false;
                };
                handover.restart();
            };
            handover.restart();
        }
    }
    function toFlight(screens: var, then: var, keep: bool): void {
        part.flightScreens = screens;
        part.flightOn = true;
        part.reelTo = "flight";
        if (part.perchOn) {
            part.handoverThen = () => {
                if (!keep)
                    part.perchOn = false;
                if (then)
                    then();
            };
            handover.restart();
        } else if (then) {
            then();
        }
    }

    function ease(t: var, k: real): real {
        if (t.c)
            return anim.ease(t.c, k);
        switch (t.e) {
        case "lin":
            return k;
        case "in":
            return k * k * k;
        case "io":
            return k < 0.5 ? 4 * k * k * k : 1 - Math.pow(-2 * k + 2, 3) / 2;
        }
        return 1 - Math.pow(1 - k, 3);
    }
    function apply(ms: real): bool {
        let done = true;
        for (const t of part.tracks) {
            const k = Math.max(0, Math.min(1, (ms - t.at) / Math.max(1, t.ms)));
            if (k < 1)
                done = false;
            if (t.hold && ms < t.at)
                continue;
            part[t.p] = t.a + (t.b - t.a) * part.ease(t, k);
        }
        return done;
    }
    function run(tracks: var, then: var, ahead: real): void {
        part.now = Date.now();
        part.trackAt = part.now - (ahead || 0);
        part.trackThen = then || null;
        part.tracks = tracks;
        part.apply(part.now - part.trackAt);
    }
    function tick(): void {
        const t = Date.now();
        part.now = t;
        if (part.tracks.length > 0 && part.apply(t - part.trackAt)) {
            const then = part.trackThen;
            part.tracks = [];
            part.trackThen = null;
            if (then)
                then();
        }
        if (part.springing)
            part.spring(t);
    }

    function burst(x: real, y: real, n: int, spread: real): void {
        const arr = part.motes.slice();
        while (arr.length < part.pool)
            arr.push(null);
        const t = Date.now();
        for (let i = 0; i < n; i++) {
            arr[part.moteHead] = {
                x: x + (Math.random() - 0.5) * spread,
                y: y + (Math.random() - 0.5) * 12,
                t: t + Math.random() * 140,
                life: 650 + Math.random() * 750,
                vx: (Math.random() - 0.5) * 34,
                vy: -26 - Math.random() * 64,
                g: 18,
                size: 0.55 + Math.random() * 0.6,
                k: 0.55 + 0.45 * Math.random(),
                b: Math.random() < 0.22
            };
            part.moteHead = (part.moteHead + 1) % part.pool;
        }
        part.motes = arr;
        part.now = t;
        part.motesUntil = Math.max(part.motesUntil, t + 1650);
    }

    function clear(): void {
        part.slideX = 0;
        part.slideY = 0;
        part.alpha = 1;
        part.revealUp = 1;
        part.revealDown = 1;
        part.heat = 0;
        part.glow = 0;
        part.lift = 0;
        part.tilt = 0;
    }
    function away(): void {
        part.tracks = [];
        part.trackThen = null;
        part.springing = false;
        part.looping = false;
        entry.stop();
        part.mode = "away";
        part.rec = null;
        part.perchOn = false;
        part.flightOn = false;
        part.perchHide = false;
        part.reelTo = "perch";
        part.track(null);
        part.clear();
    }

    function arrive(next: var, how: var): void {
        const s = next.seat;
        part.warm = true;
        part.cold = 0;
        part.rec = next;
        part.landing = how.kind === "glaze" ? how : null;
        part.seatX = s.x;
        part.seatY = s.y;
        part.ax = s.x;
        part.ay = s.y;
        part.flip = s.flip;
        part.frame = 0;
        if (reelLoader.item)
            reelLoader.item.rewind();
        part.clear();
        part.track(next);
        if (how.kind === "ws" && (!part.video || !!reelLoader.item)) {
            const spec = anim.wsIn;
            const m = next.mon;
            part.mode = "arrive";
            part.slideX = spec.vertical ? 0 : how.dir * spec.slide * m.w;
            part.slideY = spec.vertical ? spec.slide * m.h : 0;
            part.alpha = 0;
            part.shadow = 1;
            part.toPerch(survey.perchFor(next, s.x, s.y));
            part.run([
                { p: "slideX", a: part.slideX, b: 0, at: 0, ms: spec.ms, c: spec.curve },
                { p: "slideY", a: part.slideY, b: 0, at: 0, ms: spec.ms, c: spec.curve },
                { p: "alpha", a: 0, b: 1, at: 0, ms: spec.ms, c: spec.curve }
            ], () => part.seated(), Math.min(120, Date.now() - how.at));
            return;
        }
        if (how.wait > 0) {
            part.mode = "wait";
            entry.interval = how.wait;
            entry.restart();
            return;
        }
        part.entrance();
    }
    function entrance(): void {
        part.mode = "arrive";
        part.clear();
        part.revealUp = 0;
        part.revealDown = 0;
        part.heat = 1;
        part.shadow = 0;
        part.toPerch(survey.perchFor(part.rec, part.seatX, part.seatY));
        if (part.video && !(part.reelTarget && part.reelTarget.ready) && ++part.cold < 40) {
            part.mode = "wait";
            entry.interval = 40;
            entry.restart();
            return;
        }
        part.cold = 0;
        if (part.landing && Date.now() < part.landing.slam) {
            part.alight(part.landing);
            return;
        }
        part.burst(part.seatX, part.seatY - 4, 12, part.footL + part.footR);
        part.run([
            { p: "glow", a: 0, b: 0.62, at: 0, ms: 170, e: "out" },
            { p: "revealUp", a: 0, b: 1, at: 70, ms: 600, e: "out" },
            { p: "revealDown", a: 0, b: 1, at: 70, ms: 500, e: "out" },
            { p: "glow", a: 0.62, b: 0, at: 240, ms: 560, e: "io", hold: true },
            { p: "heat", a: 1, b: 0, at: 430, ms: 400, e: "in", hold: true },
            { p: "shadow", a: 0, b: 1, at: 320, ms: 380, e: "out", hold: true }
        ], () => part.seated());
    }
    function alight(l: var): void {
        part.run([
            { p: "lift", a: part.reach * 0.2, b: 0, at: 0, ms: l.fall, c: [0.33, 0.1, 0.67, 0.43] },
            { p: "revealUp", a: 0, b: 1, at: 0, ms: l.fall, e: "out" },
            { p: "revealDown", a: 0, b: 1, at: 0, ms: l.fall, e: "out" },
            { p: "glow", a: 0, b: 0.4, at: 0, ms: l.fall, e: "out" }
        ], () => {
            part.burst(part.seatX, part.seatY - 4, 10, part.footL + part.footR);
            part.run([
                { p: "lift", a: 0, b: -5, at: 0, ms: 50, e: "out" },
                { p: "lift", a: -5, b: 0, at: 50, ms: 250, e: "io", hold: true },
                { p: "glow", a: 0.4, b: 0.62, at: 0, ms: 40, e: "out" },
                { p: "glow", a: 0.62, b: 0, at: 40, ms: 480, e: "io", hold: true },
                { p: "heat", a: 1, b: 0, at: 0, ms: 380, e: "out" },
                { p: "shadow", a: 0, b: 1, at: 0, ms: 280, e: "out" }
            ], () => part.seated());
        }, Math.min(l.fall, Date.now() - l.slam + l.fall));
    }
    function seated(): void {
        part.mode = "seated";
        part.clear();
        part.shadow = 1;
        part.track(part.rec);
        if (part.frames > 1) {
            part.frame = 0;
            part.loopsLeft = reelLoader.item && reelLoader.item.seg ? 4 : 3;
            part.looping = true;
        }
        if (part.again) {
            part.again = false;
            Qt.callLater(part.think);
        }
    }
    function leave(why: var, then: var): void {
        const done = () => {
            part.away();
            if (then)
                then();
            else
                Qt.callLater(part.think);
        };
        part.looping = false;
        part.springing = false;
        entry.stop();
        if (why.kind === "cut" || part.mode === "wait" || !part.rec) {
            done();
            return;
        }
        part.mode = "leave";
        const m = Hypr.monitors[part.rec.monitor];
        if (why.kind === "glaze") {
            part.burst(part.ax + part.slideX, part.ay + part.slideY - part.lift - 4, 10, part.footL + part.footR);
            part.run([
                { p: "lift", a: part.lift, b: part.lift - 4, at: 0, ms: 50, e: "io" },
                { p: "lift", a: part.lift - 4, b: part.lift + part.reach * 0.2, at: 50, ms: 270, e: "out", hold: true },
                { p: "shadow", a: part.shadow, b: 0, at: 0, ms: 50, e: "lin" },
                { p: "heat", a: part.heat, b: 1, at: 50, ms: 110, e: "out", hold: true },
                { p: "revealUp", a: Math.min(0.999, part.revealUp), b: 0, at: 80, ms: 240, e: "io" },
                { p: "revealDown", a: Math.min(0.999, part.revealDown), b: 0, at: 60, ms: 200, e: "io" },
                { p: "glow", a: part.glow, b: 0.5, at: 50, ms: 120, e: "out", hold: true },
                { p: "glow", a: 0.5, b: 0, at: 170, ms: 200, e: "io", hold: true }
            ], done);
            return;
        }
        if (why.kind === "special" || why.kind === "ws") {
            const spec = why.kind === "special" ? anim.specialOut : anim.wsOut;
            const vertical = why.kind === "special" || spec.vertical;
            const ms = Math.max(1, spec.ms);
            part.run([
                { p: "slideX", a: part.slideX, b: vertical ? 0 : -why.dir * spec.slide * (m ? m.w : Screens.design.width), at: 0, ms: ms, c: spec.curve },
                { p: "slideY", a: part.slideY, b: vertical ? spec.slide * (m ? m.h : Screens.design.height) : 0, at: 0, ms: ms, c: spec.curve },
                { p: "alpha", a: part.alpha, b: 0, at: 0, ms: ms, c: spec.curve },
                { p: "shadow", a: part.shadow, b: 0, at: 0, ms: 50, e: "lin" }
            ], done);
            return;
        }
        part.burst(part.ax + part.slideX, part.ay + part.slideY - part.lift - part.reach * 0.3, 12, part.footL + part.footR);
        part.run([
            { p: "heat", a: part.heat, b: 1, at: 0, ms: 110, e: "out" },
            { p: "revealUp", a: Math.min(0.999, part.revealUp), b: 0, at: 40, ms: 360, e: "in" },
            { p: "revealDown", a: Math.min(0.999, part.revealDown), b: 0, at: 40, ms: 300, e: "in" },
            { p: "glow", a: part.glow, b: 0.5, at: 0, ms: 200, e: "out" },
            { p: "glow", a: 0.5, b: 0, at: 300, ms: 260, e: "io", hold: true },
            { p: "shadow", a: part.shadow, b: 0, at: 0, ms: 180, e: "out" }
        ], done);
    }

    function hop(next: var): void {
        const s = next.seat;
        const fx = part.ax + part.slideX;
        const fy = part.ay + part.slideY - part.lift;
        part.springing = false;
        if (!part.video)
            part.looping = false;
        part.clear();
        part.ax = fx;
        part.ay = fy;
        part.rec = next;
        part.seatX = s.x;
        part.seatY = s.y;
        part.mode = "hop";
        part.track(null);
        part.shadow = 0;
        const dist = Math.hypot(s.x - fx, s.y - fy);
        const ms = Math.round(Math.max(460, Math.min(840, 380 + dist * 0.3)));
        const ma = survey.monAt(fx, fy);
        const mb = survey.monAt(s.x, s.y);
        const roof = Math.max(ma ? ma.y : 0, mb ? mb.y : 0) + part.reach + 6;
        const apex = Math.max(roof, Math.min(fy, s.y) - (40 + dist * 0.16));
        part.hopFrom = { x: fx, y: fy };
        part.hopTo = { x: s.x, y: s.y };
        part.hopH = Math.max(0, (fy + s.y) / 2 - apex);
        part.hopP = 0;
        const dir = s.x >= fx ? 1 : -1;
        part.flip = s.flip;
        const l = Math.max(part.spanL, part.spanR) + 40;
        const screens = survey.screensOver(Math.min(fx, s.x) - l, apex - part.reach - 40, Math.max(fx, s.x) + l, Math.max(fy, s.y) + part.legs + 40);
        part.toFlight(screens, () => {
            part.burst(fx, fy - 6, 7, part.footL + part.footR);
            part.run([
                { p: "lift", a: 0, b: -4, at: 0, ms: 90, e: "io" },
                { p: "hopP", a: 0, b: 1, at: 90, ms: ms, e: "lin", hold: true },
                { p: "lift", a: -4, b: 0, at: 90, ms: 120, e: "out", hold: true },
                { p: "tilt", a: 0, b: dir * 5, at: 90, ms: ms * 0.45, e: "out", hold: true },
                { p: "tilt", a: dir * 5, b: 0, at: 90 + ms * 0.45, ms: ms * 0.55, e: "io", hold: true },
                { p: "glow", a: 0, b: 0.5, at: 90, ms: 180, e: "out", hold: true },
                { p: "glow", a: 0.5, b: 0, at: 60 + ms, ms: 420, e: "io", hold: true },
                { p: "lift", a: 0, b: -5, at: 90 + ms, ms: 80, e: "out", hold: true },
                { p: "lift", a: -5, b: 0, at: 170 + ms, ms: 230, e: "io", hold: true },
                { p: "shadow", a: 0, b: 1, at: 90 + ms, ms: 280, e: "out", hold: true }
            ], () => part.landed());
        });
    }
    onHopPChanged: {
        if (part.mode !== "hop" || !part.hopFrom)
            return;
        const p = part.hopP;
        const f = part.hopFrom;
        const t = part.hopTo;
        part.ax = f.x + (t.x - f.x) * p;
        part.ay = f.y + (t.y - f.y) * p - 4 * p * (1 - p) * part.hopH;
        if (p > 0.04 && p < 0.97 && Math.random() < 0.7)
            part.burst(part.ax, part.ay - part.reach * 0.15, 1, part.footL);
    }
    function landed(): void {
        part.ax = part.hopTo.x;
        part.ay = part.hopTo.y;
        part.toPerch(survey.perchFor(part.rec, part.ax, part.ay));
        part.burst(part.ax, part.ay - 4, 6, part.footL + part.footR);
        part.seated();
    }

    function float(s: var): void {
        part.target = { x: s.x, y: s.y };
        part.targetAt = Date.now();
        part.seatX = s.x;
        part.seatY = s.y;
        if (part.mode === "float") {
            if (!part.springing) {
                part.springAt = Date.now();
                part.springing = true;
                part.run([
                    { p: "lift", a: part.lift, b: 9, at: 0, ms: 140, e: "out" },
                    { p: "glow", a: part.glow, b: 0.45, at: 0, ms: 160, e: "out" }
                ], null);
            }
            return;
        }
        part.mode = "float";
        if (!part.video)
            part.looping = false;
        part.vx = 0;
        part.vy = 0;
        part.track(null);
        part.run([
            { p: "lift", a: part.lift, b: 9, at: 0, ms: 160, e: "out" },
            { p: "glow", a: part.glow, b: 0.45, at: 0, ms: 200, e: "out" },
            { p: "shadow", a: part.shadow, b: 0, at: 0, ms: 110, e: "out" }
        ], null);
        part.toFlight([part.rec.monitor], () => {
            part.springAt = Date.now();
            part.springing = true;
        });
    }
    function spring(t: double): void {
        const dt = Math.min(0.05, Math.max(0.001, (t - part.springAt) / 1000));
        part.springAt = t;
        const w = 15;
        const ex = part.ax - part.target.x;
        const ey = part.ay - part.target.y;
        part.vx += (-2 * w * part.vx - w * w * ex) * dt;
        part.vy += (-2 * w * part.vy - w * w * ey) * dt;
        part.ax += part.vx * dt;
        part.ay += part.vy * dt;
        if (part.mode === "drag") {
            part.tilt = Math.max(-9, Math.min(9, -part.vx * 0.011));
            return;
        }
        const near = Math.abs(ex) < 0.6 && Math.abs(ey) < 0.6 && Math.abs(part.vx) < 6 && Math.abs(part.vy) < 6;
        if (near && t - part.targetAt > 240) {
            part.springing = false;
            part.ax = part.target.x;
            part.ay = part.target.y;
            if (part.dragTravel >= 0)
                Sfx.play("volume", 0.5);
            part.dragTravel = -1;
            part.run([
                { p: "lift", a: part.lift, b: -3, at: 0, ms: 170, e: "io" },
                { p: "lift", a: -3, b: 0, at: 170, ms: 170, e: "io", hold: true },
                { p: "tilt", a: part.tilt, b: 0, at: 0, ms: 260, e: "io" },
                { p: "glow", a: part.glow, b: 0, at: 0, ms: 300, e: "io" },
                { p: "shadow", a: 0, b: 1, at: 150, ms: 240, e: "out" }
            ], () => {
                part.toPerch(survey.perchFor(part.rec, part.ax, part.ay));
                part.seated();
            });
        }
    }

    function grab(gx: real, gy: real): void {
        if (part.mode !== "seated" || !part.rec)
            return;
        part.mode = "drag";
        if (!part.video) {
            part.looping = false;
            part.frame = 0;
        }
        part.grabDX = gx - part.ax;
        part.grabAt = Date.now();
        part.dragTravel = 0;
        part.dragLastX = gx;
        part.vx = 0;
        part.vy = 0;
        part.target = { x: part.ax, y: part.ay };
        part.targetAt = Date.now();
        part.track(null);
        part.run([
            { p: "lift", a: 0, b: 16, at: 0, ms: 180, e: "out" },
            { p: "glow", a: 0, b: 0.38, at: 0, ms: 220, e: "out" },
            { p: "shadow", a: part.shadow, b: 0, at: 0, ms: 140, e: "out" }
        ], null);
        Sfx.play("focus", 0.6);
        part.toFlight([part.rec.monitor], () => {
            if (part.mode !== "drag")
                return;
            part.perchHide = true;
            part.springAt = Date.now();
            part.springing = true;
        }, true);
    }
    function drag(gx: real, gy: real): void {
        if (part.mode !== "drag" || !part.rec)
            return;
        const w = part.rec;
        part.dragTravel += Math.abs(gx - part.dragLastX);
        part.dragLastX = gx;
        const lo = w.x + 46 + (part.flip ? part.footR : part.footL);
        const hi = w.x + w.w - 46 - (part.flip ? part.footL : part.footR);
        part.target = { x: Math.round(Math.max(lo, Math.min(hi, gx - part.grabDX))), y: Math.round(w.y - survey.cameOf(w) - 1) };
        part.targetAt = Date.now();
        if (!part.springing) {
            part.springAt = Date.now();
            part.springing = true;
        }
    }
    function drop(): void {
        if (part.mode !== "drag")
            return;
        const w = part.rec;
        if (w && part.dragTravel >= 5) {
            const s = Object.assign({}, spots.seats);
            s[w.cls] = [Math.round((part.target.x - w.x) / w.w * 1000) / 1000, part.flip];
            spots.seats = s;
        }
        part.seatX = part.target.x;
        part.seatY = part.target.y;
        part.mode = "float";
        part.targetAt = 0;
        if (!part.springing) {
            part.springAt = Date.now();
            part.springing = true;
        }
    }

    function nextFrame(): void {
        const f = part.frame + 1;
        if (f < part.frames) {
            part.frame = f;
            return;
        }
        part.frame = 0;
        part.lapped();
    }
    function lapped(): void {
        if (--part.loopsLeft <= 0 && !(part.playing && part.mode === "seated" && !Her.idle)) {
            part.looping = false;
            fidget.interval = 26000 + Math.round(Math.random() * 20000);
            fidget.restart();
        }
    }
    function reelIn(slot: string, out: var): void {
        const r = Object.assign({}, part.reels);
        r[slot] = out;
        part.reels = r;
    }
    function reelOut(slot: string, out: var): void {
        if (part.reels[slot] !== out)
            return;
        const r = Object.assign({}, part.reels);
        delete r[slot];
        part.reels = r;
    }
    onPlayingChanged: if (part.playing && part.mode === "seated" && part.frames > 1)
        part.looping = true

    Timer {
        id: fx
        interval: part.step
        repeat: true
        running: part.ticking
        onTriggered: part.tick()
    }
    Timer {
        id: loop
        interval: Math.round(1000 / (part.meta ? part.meta.fps : 12))
        repeat: true
        running: !part.video && part.looping && part.mode === "seated"
        onTriggered: part.nextFrame()
    }
    Timer {
        id: fidget
        onTriggered: if (part.mode === "seated" && !Her.idle && part.frames > 1) {
            part.loopsLeft = 1;
            part.looping = true;
        }
    }
    Timer {
        interval: 60000
        running: part.mode === "away" && part.warm
        onTriggered: part.warm = false
    }
    Timer {
        id: entry
        onTriggered: if (part.mode === "wait")
            part.entrance()
    }
    Timer {
        id: handover
        interval: 90
        onTriggered: {
            if (part.video && part.reelTarget && !part.reelTarget.ready && ++part.waited < 10) {
                handover.restart();
                return;
            }
            part.waited = 0;
            const then = part.handoverThen;
            part.handoverThen = null;
            if (then)
                then();
        }
    }

    LazyLoader {
        id: reelLoader
        active: part.video && part.warm
        source: Qt.resolvedUrl("Reel.qml")
        onItemChanged: if (item)
            item.her = part
    }

    Spots {
        id: spots
    }

    Variants {
        model: Screens.list
        Stage {
            her: part
        }
    }

    Sheets {
        her: part
    }

    Ears {
        her: part
    }
    onMetaChanged: Qt.callLater(part.think)
    onOnChanged: Qt.callLater(part.think)

    function ruleOut(): void {
        const end = String.fromCharCode(36);
        Quickshell.execDetached(["hyprctl", "eval", "hl.layer_rule({ name = 'glasshouse-sill', match = { namespace = '^(glasshouse-sill)" + end + "' }, no_anim = true })"]);
    }

    Remote {
        her: part
        reel: reelLoader.item
    }

    Component.onCompleted: {
        part.ruleOut();
        Qt.callLater(part.think);
    }
}
