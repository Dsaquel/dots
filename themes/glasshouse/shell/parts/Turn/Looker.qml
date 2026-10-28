import Quickshell.Hyprland
import Quickshell.Io
import qs.core

Process {
    id: looker

    required property var host
    property var wins: []
    stdout: StdioCollector {
        onStreamFinished: {
            const parts = text.split(/\n\s*\n/).map(s => s.trim()).filter(s => s.length);
            const vals = parts.map(s => {
                try {
                    const j = JSON.parse(s);
                    if (j.option !== undefined)
                        return j.int !== undefined ? j.int : (j.float !== undefined ? j.float : j.bool);
                    const k = Object.keys(j);
                    return k.length ? j[k[0]] : null;
                } catch (e) {
                    return null;
                }
            });
            const n = looker.wins.length;
            const g = vals.slice(n * 6);
            const dimOn = g[0] === true || g[0] === 1;
            const dimK = Number(g[1]) || 0;
            const blurOn = g[2] === true || g[2] === 1;
            const aAct = g[3] === null || g[3] === undefined ? 1 : Number(g[3]);
            const aIn = g[4] === null || g[4] === undefined ? 1 : Number(g[4]);
            const num = (x, d) => x === null || x === undefined || isNaN(Number(x)) ? d : Number(x);
            looker.host.blurSpec = { on: blurOn, size: num(g[5], 7), passes: num(g[6], 2), noise: num(g[7], 0.012), contrast: num(g[8], 0.8916), brightness: num(g[9], 0.8172), vibrancy: num(g[10], 0.1696), vibDark: num(g[11], 0) };
            const act = Hyprland.activeToplevel ? Hypr.clean(Hyprland.activeToplevel.address) : "";
            const out = {};
            for (let i = 0; i < n; i++) {
                const v = vals.slice(i * 6, i * 6 + 6);
                const a = looker.wins[i];
                const focused = a === act;
                const pw = v[1] === null ? 2 : Number(v[1]);
                const rr = v[0] === null ? 8 : Number(v[0]);
                out[a] = {
                    radius: Math.max(0, Math.floor(rr * pw / 2) - 1),
                    power: pw,
                    dim: 0,
                    blur: blurOn && v[3] !== true,
                    alpha: focused ? (v[4] === null ? 1 : Number(v[4])) * aAct : (v[5] === null ? 1 : Number(v[5])) * aIn
                };
            }
            looker.host.looks = out;
            looker.host.looked = true;
        }
    }
    onExited: code => {
        if (code !== 0)
            looker.host.looked = true;
    }
}
