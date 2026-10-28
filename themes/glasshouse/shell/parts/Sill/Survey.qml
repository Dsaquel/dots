import QtQuick
import qs.core

QtObject {
    id: survey

    required property var her
    required property var memory
    required property var specialIn
    readonly property var fracs: [0.74, 0.68, 0.8, 0.62, 0.86, 0.56, 0.3, 0.36, 0.24]

    function cameOf(w: var): real {
        return w.special || w.w < 360 || w.h < 220 ? 6.5 : 8;
    }
    function isAbove(o: var, w: var): bool {
        if (o.special !== w.special)
            return o.special;
        if (o.floating !== w.floating)
            return o.floating;
        return o.floating && o.history < w.history;
    }
    function boxAt(x: real, y: real, flip: bool): var {
        const l = flip ? survey.her.spanR : survey.her.spanL;
        const r = flip ? survey.her.spanL : survey.her.spanR;
        return { x: x - l, y: y - survey.her.reach, w: l + r, h: survey.her.reach + survey.her.legs };
    }
    function coverOf(w: var, b: var): real {
        let c = 0;
        for (const o of w.shown) {
            if (o.address === w.address || !survey.isAbove(o, w))
                continue;
            const ix = Math.min(o.x + o.w, b.x + b.w) - Math.max(o.x, b.x);
            const iy = Math.min(o.y + o.h, b.y + b.h) - Math.max(o.y, b.y);
            if (ix > 0 && iy > 0)
                c += ix * iy;
        }
        return c / Math.max(1, b.w * b.h);
    }
    function plateEnd(w: var): real {
        const compact = survey.cameOf(w) < 8;
        const est = 50 + 6.6 * ((w.cls || "").length + (w.title || "").length);
        return w.x + (compact ? 48 : 64) + Math.min(est, compact ? w.w - 128 : w.w / 2 - 118);
    }
    function seatOn(w: var, keepX: real): var {
        if (!w || w.full || w.fullscreen || !(w.floating || w.special))
            return null;
        if (w.wayland && w.wayland.parent)
            return null;
        const came = survey.cameOf(w);
        const ledge = Math.round(w.y - came - 1);
        if (ledge - survey.her.reach - 4 < w.mon.y || w.h < 1.8 * survey.her.legs || w.w < 2.2 * (survey.her.spanL + survey.her.spanR))
            return null;
        if (w.x < w.mon.x - 40 || w.x + w.w > w.mon.x + w.mon.w + 40)
            return null;
        const lo = w.x + 46;
        const hi = w.x + w.w - 46;
        const cx = w.x + w.w / 2;
        const plate = survey.plateEnd(w);
        const spot = survey.memory.seats[w.cls];
        const first = keepX > -1e8 ? { f: (keepX - w.x) / w.w, flip: survey.her.flip } : (spot ? { f: spot[0], flip: spot[1] } : null);
        const tries = first ? [first.f].concat(survey.fracs) : survey.fracs;
        let best = null;
        for (let i = 0; i < tries.length; i++) {
            const f = tries[i];
            const kept = !!first && i === 0;
            const flip = kept ? first.flip : f > 0.5;
            const hx = Math.round(w.x + f * w.w);
            const l = hx - (flip ? survey.her.footR : survey.her.footL);
            const r = hx + (flip ? survey.her.footL : survey.her.footR);
            if (l < lo || r > hi)
                continue;
            if (!kept && came >= 8 && r > cx - 46 && l < cx + 46)
                continue;
            let cost = survey.coverOf(w, survey.boxAt(hx, ledge, flip));
            if (!kept && l < plate)
                cost += 0.2;
            if (cost > 0.4)
                continue;
            if (kept && cost < 0.25)
                return { x: hx, y: ledge, flip: flip, cost: cost };
            if (!best || cost < best.cost - 0.01)
                best = { x: hx, y: ledge, flip: flip, cost: cost };
            if (cost < 0.01)
                break;
        }
        return best;
    }

    function monAt(x: real, y: real): var {
        for (const n in Hypr.monitors) {
            const m = Hypr.monitors[n];
            if (x >= m.x && x < m.x + m.w && y >= m.y && y < m.y + m.h)
                return m;
        }
        return null;
    }
    function screensOver(x0: real, y0: real, x1: real, y1: real): var {
        const out = [];
        for (const sc of Screens.list) {
            const m = Hypr.monitors[sc.name];
            if (m && m.x < x1 && m.x + m.w > x0 && m.y < y1 && m.y + m.h > y0)
                out.push(sc.name);
        }
        return out;
    }
    function perchFor(w: var, x: real, y: real): var {
        const m = Hypr.monitors[w.monitor];
        const l = survey.her.flip ? survey.her.spanR : survey.her.spanL;
        const r = survey.her.flip ? survey.her.spanL : survey.her.spanR;
        const x0 = Math.max(0, Math.floor(x - m.x - l - 150));
        const x1 = Math.min(m.w, Math.ceil(x - m.x + r + 150));
        const y0 = Math.max(0, Math.floor(y - m.y - survey.her.reach - 70));
        const y1 = Math.min(m.h, Math.ceil(y - m.y + survey.her.legs + 50));
        return { screen: w.monitor, x: x0, y: y0, w: Math.max(1, x1 - x0), h: Math.max(1, y1 - y0) };
    }

    function shownAll(): var {
        const all = [];
        for (const sc of Screens.list) {
            const m = Hypr.monitors[sc.name];
            if (!m)
                continue;
            const list = Hypr.on(sc.name).filter(w => !(Test.on && survey.her.testHidden[w.address])).map(w => Test.on && survey.her.testScratch[w.address] ? Object.assign({}, w, { special: true }) : w);
            const full = list.some(w => w.fullscreen);
            for (const w of list)
                all.push(Object.assign({}, w, { mon: m, full: full, shown: list }));
        }
        return all;
    }

    function choose(all: var): var {
        if (!survey.her.on || !survey.her.meta)
            return null;
        const cands = [];
        for (const w of all) {
            let keepX = -1e9;
            if (survey.her.rec && w.address === survey.her.rec.address && survey.her.mode !== "hop") {
                const p = survey.her.rec;
                const dx = w.x - p.x;
                keepX = dx === (w.x + w.w) - (p.x + p.w) ? survey.her.seatX + dx : survey.her.seatX;
            }
            const s = survey.seatOn(w, keepX);
            if (s)
                cands.push(Object.assign({}, w, { seat: s }));
        }
        if (cands.length === 0)
            return null;
        const special = cands.filter(w => w.special);
        if (special.length > 0)
            return special.find(w => w.cls.indexOf("music.youtube") >= 0) || special.find(w => w.monitor === Hypr.focusedMonitor) || special[0];
        const focused = cands.find(w => w.address === Hypr.active);
        if (focused)
            return focused;
        const cur = survey.her.rec ? cands.find(w => w.address === survey.her.rec.address) : null;
        return cur || cands.slice().sort((a, b) => a.history - b.history)[0];
    }

    function fresh(monitor: string): var {
        const e = survey.her.events[monitor];
        return e && Date.now() - e.at < 450 ? e : null;
    }
    function glazeOf(w: var): var {
        const g = w.special ? survey.her.glazes[w.wsName] : null;
        return g && Date.now() - g.at < 450 ? g : null;
    }
    function why(cur: var, here: var): var {
        if (here && (here.full || here.fullscreen))
            return { kind: "cut" };
        if (!Hypr.byAddress[cur.address])
            return { kind: "closed" };
        if (survey.glazeOf(cur))
            return { kind: "glaze" };
        const e = survey.fresh(cur.monitor);
        if (e && e.kind === "special-out" && cur.special)
            return { kind: "special" };
        if (e && e.kind === "ws" && !cur.special)
            return { kind: "ws", dir: e.dir };
        return { kind: "gone" };
    }
    function how(next: var): var {
        const e = survey.fresh(next.monitor);
        const g = survey.glazeOf(next);
        if (g && g.slam >= 0)
            return { kind: "glaze", slam: g.at + g.slam - survey.her.step, fall: Math.max(1, g.slam - g.from), wait: 0 };
        if (next.special && e && e.kind === "special-in")
            return { kind: "special", wait: Math.max(0, survey.specialIn.ms + 50 - (Date.now() - e.at)) };
        if (e && e.kind === "ws" && !next.special)
            return { kind: "ws", dir: e.dir, at: e.at };
        const b = survey.her.born[next.address];
        if (b && Date.now() - b < 1500)
            return { kind: "open", wait: Math.max(0, 760 - (Date.now() - b)) };
        return { kind: "plain", wait: 0 };
    }
}
