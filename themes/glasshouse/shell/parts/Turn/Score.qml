import QtQuick
import Quickshell
import qs.core

Scope {
    id: score

    property string runDir: ""
    property string warmDir: ""
    readonly property string dir: score.warmDir !== "" ? score.warmDir : (score.phase === "rest" || score.runDir === "" ? (World.name === "light" ? "dusk" : "dawn") : score.runDir)
    readonly property bool dawn: dir === "dawn"
    readonly property string leave: dawn ? "dark" : "light"
    readonly property string arrive: dawn ? "light" : "dark"

    property string phase: "rest"

    readonly property color gold: dawn ? "#ffcf6a" : "#bcd4ff"
    readonly property color ink: dawn ? "#140d24" : "#0a1030"
    readonly property color hiCol: dawn ? "#fff4d8" : "#f2f7ff"
    readonly property color hot: dawn ? "#fff3d6" : "#dbe8ff"
    readonly property color warm: dawn ? "#ffa53a" : "#3f7bff"
    readonly property real cx: 960
    readonly property real cy: 580

    property real t: 0
    property bool running: false

    readonly property real stopIn: 0.35
    readonly property real starT: 0.95
    readonly property real flyT: 1.00
    readonly property real touchT: 1.95
    readonly property real relDur: 0.45
    readonly property var beats: [2.20, 2.53, 2.79, 2.97, 3.10, 3.20]
    readonly property real holdT: 3.28
    readonly property var steps: [0.10, 0.18, 0.26, 0.33, 0.38, 0.425]
    readonly property real snapT: 3.42
    readonly property real hsB: 3.50
    readonly property real hushT: 3.42
    readonly property real burstT: 3.57
    readonly property real blastT: 4.07
    readonly property real endT: 11.0
    readonly property real clipT: blastT - 0.1
    readonly property real switchT: 0.40

    function win(a: real, b: real): real { return Math.max(0, Math.min(1, (t - a) / (b - a))); }
    function outCubic(x: real): real { return 1 - Math.pow(1 - x, 3); }
    function inCubic(x: real): real { return x * x * x; }
    function inOut(x: real): real { return x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2; }
    function decay(t0: real, tau: real): real { return t < t0 ? 0 : Math.exp(-(t - t0) / tau); }

    readonly property real stopR: running ? 1450 * outCubic(win(0, stopIn)) : 0
    readonly property real startT: -0.1
    readonly property real stopOn: running && t >= 0 && t < stopIn + 0.05 ? 1 : 0
    readonly property real relR: 1500 * win(touchT, touchT + relDur)
    readonly property real relOn: t > touchT && t < touchT + relDur + 0.05 ? 1 : 0
    readonly property real reveal: win(0.40, 0.95)
    readonly property real beatE: beats.reduce((s, b, i) => s + (0.5 + 0.12 * i) * decay(b, 0.11), 0)
    readonly property real front: {
        if (t < touchT) return 0;
        let f = 0.075 * outCubic(win(touchT, touchT + 0.12));
        for (let i = 0; i < beats.length; i++) {
            if (t < beats[i]) break;
            const prev = i ? steps[i - 1] : 0.075;
            f = prev + (steps[i] - prev) * outCubic(win(beats[i], beats[i] + 0.16));
        }
        return f;
    }
    readonly property real web: t < snapT ? 0 : 1.02 * Math.min(1, 0.55 / 1.02 + (1 - 0.55 / 1.02) * win(snapT, snapT + 0.035))
    readonly property real leak: (0.6 * win(snapT, snapT + 0.03) + 1.4 * sep + 1.2 * bulge) * (1 - win(burstT, burstT + 0.1))
    readonly property real snapK: win(snapT, snapT + 0.02) * (1 - 0.6 * win(hsB, burstT))
    readonly property real sep: outCubic(win(hsB, burstT))
    readonly property real bulge: inCubic(win(burstT - 0.05, burstT)) * (t < burstT + 0.2 ? 1 : 0)
    readonly property bool held: t >= snapT && t < hsB
    readonly property real tc: t < snapT ? t : (t < hsB ? snapT : t - (hsB - snapT))
    readonly property real hush: win(hushT, burstT)
    readonly property real pre: t < burstT ? 1 : 0
    readonly property real dimK: dawn ? 0.28 : 0.45
    readonly property real dimHold: 0.15 * win(holdT - 0.02, snapT) * (1 - win(snapT, snapT + 0.05))
    readonly property real dim: t < burstT ? dimK * win(touchT + 0.1, touchT + 0.6) + 0.2 * hush + dimHold : dimK * 0.9 * (1 - win(burstT, blastT))
    readonly property real cool: dawn ? 0 : 0.85 * win(touchT, hushT) * (1 - win(blastT - 0.1, blastT + 0.35))

    readonly property var hits: [[0.0, 7, 0.25], [touchT, 20, 0.28]].concat(beats.map((b, i) => [b, 3 + 2 * i, 0.12])).concat([[hsB, 14, 0.1], [burstT, 26, 0.3], [blastT, 10, 0.25], [landT, 5, 0.07]])
    readonly property real shakeX: hits.reduce((s, h) => t < h[0] ? s : s + h[1] * Math.exp(-(t - h[0]) / h[2]) * Math.sin((t - h[0]) * 75), 0)
    readonly property real shakeY: hits.reduce((s, h) => t < h[0] ? s : s + h[1] * Math.exp(-(t - h[0]) / h[2]) * Math.sin((t - h[0]) * 61 + 1.3), 0) - hits.reduce((s, h) => t < h[0] ? s : s + h[1] * Math.exp(-(t - h[0]) / h[2]) * Math.sin(1.3) * Math.exp(-(t - h[0]) / 0.012), 0)
    readonly property real push: 42 * inOut(win(0.25, touchT)) * (1 - inOut(win(blastT, blastT + 0.7)))
    readonly property real still: t >= hsB ? 1 : 1 - win(holdT - 0.05, holdT + 0.01)
    readonly property real ringK: 1 - win(holdT - 0.02, holdT + 0.06)
    readonly property real tremK: t < snapT ? 1.3 * win(holdT, snapT) : 0
    readonly property real tremX: tremK * (0.6 * Math.sin(t * 331) + 0.4 * Math.sin(t * 197 + 1.3))
    readonly property real tremY: tremK * (0.6 * Math.sin(t * 293 + 0.7) + 0.4 * Math.sin(t * 173 + 2.1))
    readonly property real camZ: running ? 2015.3 - punch - push : 2015.3
    readonly property real drift: 16 * inOut(win(0.25, touchT)) * (1 - inOut(win(blastT, blastT + 0.7)))
    readonly property real punch: 70 * decay(touchT, 0.16) + 60 * decay(burstT, 0.18) + 16 * beats.reduce((s, b) => s + decay(b, 0.08), 0) + 14 * decay(landT, 0.1)
    readonly property vector3d camPos: running ? Qt.vector3d((held ? 0 : shakeX) * still + tremX + drift, (held ? 0 : shakeY) * still + tremY, camZ) : Qt.vector3d(0, 0, 2015.3)

    function flyAt(x: real): real { return Math.max(0, Math.min(1, (x - flyT) / (touchT - flyT))); }
    function roseZAt(x: real): real {
        if (x >= touchT) return 1;
        const f = flyAt(x);
        const sc = 0.16 + (0.978 - 0.16) * Math.pow(f, 2.4);
        return 2015.3 * (1 - 1 / sc);
    }
    function roseSpinAt(x: real): real {
        const p = Math.max(0, Math.min(1, (x - touchT) / (holdT - 0.02 - touchT)));
        return -300 * Math.pow(1 - flyAt(x), 1.6) - 30 * p * p * (3 - 2 * p);
    }
    function roseTiltAt(x: real): real { return 28 * Math.pow(1 - flyAt(x), 1.4); }
    readonly property real fly: flyAt(t)
    readonly property real draw: inOut(win(flyT, touchT - 0.1))
    readonly property real fillI: 0.85 * (1 - 0.4 * hush)
    readonly property real level: (1.0 + 0.1 * decay(touchT, 0.12)) * (0.85 - 0.35 * hush) * (1 - 0.35 * decay(touchT, 0.1)) * (1 - 0.38 * decay(touchT, 0.35))
    function thumpS(x: real): real { return x <= 0 ? 0 : (1 - Math.exp(-x / 0.014)) * Math.exp(-x / 0.075) - 0.22 * (x > 0.07 ? (1 - Math.exp(-(x - 0.07) / 0.03)) * Math.exp(-(x - 0.07) / 0.09) : 0); }
    readonly property real bump: 0.05 * thumpS(t - touchT) + beats.reduce((s, b, i) => s + (0.14 + 0.015 * i) * thumpS(t - b), 0)
    readonly property real drawIn: 0.018 * inOut(win(holdT - 0.02, snapT)) * (1 - outCubic(win(snapT, snapT + 0.05)))
    readonly property real cscale: (1 + bump) * (1 - drawIn) * (1 - 0.1 * outCubic(hush)) * (1 + 1.4 * outCubic(win(burstT, burstT + 0.35)))
    readonly property real lift: 15
    readonly property real liftK: (2015.3 - 1 - lift) / (2015.3 - 1)
    readonly property real roseS: cscale * liftK * camZ / (camZ - 1 - lift)
    readonly property real knockW: touchT + 0.10
    readonly property var writeDur: [0.27, 0.21, 0.15, 0.11, 0.08, 0.06]
    readonly property color hlCol: dawn ? "#ffb63d" : "#5d8dff"
    readonly property real cfade: 1 - win(burstT + 0.01, burstT + 0.2)
    readonly property real star: 2.6 * win(starT - 0.02, starT + 0.08) * (1 - 0.8 * win(flyT + 0.25, touchT)) * (1 - win(touchT, touchT + 0.12)) + 0.6 * decay(touchT, 0.06)
    readonly property real touchRing: 0.9 * decay(touchT, 0.2)
    readonly property real lattice: 0.6 * win(burstT - 0.02, burstT + 0.04) * (1 - win(burstT + 0.3, blastT + 0.25))
    readonly property real light: 0.12 * hush * pre + 0.45 * decay(burstT, 0.04) + 0.16 * decay(landT, 0.05) * (t < landT + 0.5 ? 1 : 0)
    readonly property real holdR: t < snapT ? win(holdT - 0.04, holdT + 0.02) : 0
    readonly property real rays: 0.9 * win(starT, starT + 0.1) * (1 - win(touchT - 0.3, touchT)) * 0.6 + 1.4 * decay(touchT, 0.2)
        + (0.2 * win(touchT, hushT) * (1 - 0.7 * holdR) + 0.2 * hush) * pre + 0.55 * decay(burstT, 0.08) + 0.3 * win(burstT, blastT) * (1 - win(blastT, blastT + 0.3))
        + 0.25 * decay(landT, 0.08) * (t < landT + 0.6 ? 1 : 0)
    readonly property real impAmt: t >= burstT && t < burstT + 0.034 ? 1 : 0
    readonly property real impInv: t >= burstT + 0.017 && t < burstT + 0.034 ? 1 : 0

    readonly property real rbFrom: 8.7
    readonly property real landT: 10.0
    readonly property real rbOn: t >= rbFrom ? 1 : 0
    readonly property real rbSpan: 0.66
    readonly property real rbK: 1.6
    readonly property real rbA0: 0.25
    readonly property real rbDur: 0.55
    readonly property real rbSnap: 0.045
    readonly property real rbHover: 0.13
    readonly property real rbHold: 0.7
    readonly property real mixr: win(landT - 0.02, landT + 0.14)
    readonly property real rbSweep: -0.35 + 3.3 * win(landT + 0.1, landT + 0.6)
    readonly property real rbGlint: (dawn ? 0.42 : 0.4) * win(landT + 0.08, landT + 0.14) * (1 - win(landT + 0.54, landT + 0.61))
    readonly property real rbWin: 0.55
    readonly property real rbJointsL: 0.5 * decay(landT, 0.12)
    readonly property real rbJointsW: 0.12 * decay(landT, 0.08)
    readonly property real rbJointsOn: 1 - win(landT + 0.3, landT + 0.42)
    readonly property real landRing: 0.75 * decay(landT, 0.18) * (t < landT + 0.7 ? 1 : 0)
    readonly property bool deskLive: running && t >= rbFrom - 0.3
    readonly property real fadeT: 10.85
}
