import pathlib

import numpy as np

from synth import SR, PANE, GLASS, CRYSTAL, SPARK, hz, secs, ramp, rolloff, band, strike, ring, bubble, burst, sweep, pad, dust, layered, crack, \
    solder, laying, render, loud40, write

HASTE = 1
OUT = pathlib.Path(__file__).resolve().parent.parent / "sounds"
LADDER = {"dark": "C5 D5 E5 G5 A5".split(), "light": "C6 D6 E6 G6 A6".split()}

def events(world):
    dark = world == "dark"
    V = GLASS if dark else CRYSTAL
    L = LADDER[world]
    up = 1 if dark else 2
    s = {}
    for i, n in enumerate(L, 1):
        s[f"ws-{i}"] = (1.6 if dark else .9, 0, .16 if dark else .1, [(0, strike(hz(n), V))]
                        + ([] if dark else [(.02, strike(hz(n) * 2, SPARK, .25))]))
    hi = ["C6", "D6", "E6", "G6", "A6"] if dark else ["E7", "G7", "A7", "C8", "D8"]
    tick = 2600 if dark else 4200
    chime = [(.08, strike(hz("G5" if dark else "G6"), V, .5, .14 if dark else .07)), (.12, strike(hz("C6" if dark else "C7"), V, .6, .22 if dark else .1))]
    s["open"] = (1.1 if dark else .9, -2, .14, chime + [(t + .12, x) for t, x in dust(.1, .4, 3, ["E7", "G7"] if dark else ["E7", "G7", "C8"], .04 if dark else .06)]
                 + [(0, .18 * sweep(.3, 1600 if dark else 2600, 4200 if dark else 7000, .5, 1.2, .5, PANE))]
                 + laying(0, .08, 9, hi, .36 if dark else .3) + solder(.14, 5, .032, tick, .9 if dark else .6))
    sling = np.random.default_rng(6119)
    spin, sparks, swell = secs(.36), secs(.62), secs(.9)
    laps = np.cumsum(np.interp(spin, [0, .04, .23, .33, .36], [2, 5.5, 6.7, 9.5, 9.5])) / SR
    pulse = (.5 + .5 * np.cos(2 * np.pi * laps)) ** 2
    opened = np.clip((spin - .04) / .19, 0, 1) ** .7 * np.clip((.36 - spin) / .006, 0, 1)
    ks = 2 ** np.arange(7.5, 13.2, .25)
    hum = sum(w * band(len(spin), k, .15, sling) for w, k in zip(np.exp(-.5 * (np.log2(ks[:, None] / ((650 if dark else 1100) * (1 + .9 * pulse) * (1 + 1.4 * spin / .36))) / .45) ** 2), ks))
    whir = hum / np.sqrt(np.mean(hum ** 2)) * (.25 + .75 * pulse) * opened * ramp(spin, .02)
    hits = (sling.random(len(sparks)) < np.interp(sparks, [0, .04, .23, .36, .37, .56, .62], [80, 320, 1500, 2400, 900, 60, 0]) / SR) * sling.uniform(.15, 1, len(sparks)) ** 2
    grains = np.convolve(hits * np.interp(sparks, spin, .35 + .65 * pulse, right=1), np.exp(-secs(.004) / .0006))[:len(sparks)]
    crackle = grains * (.75 * band(len(sparks), 3400 if dark else 6400, .8, sling) + .4 * band(len(sparks), 1700 if dark else 3200, .6, sling))
    glide = np.cumsum(2 ** (-60 * (1 - np.minimum(swell / .36, 1)) / 1200)) / SR
    choir = sum(a * rolloff(hz(n) * r, 7000) * np.sin(2 * np.pi * hz(n) * r * 2 ** (c / 1200) * glide + sling.uniform(0, 2 * np.pi))
                for n in (["D5", "A5", "E6", "B6"] if dark else ["D6", "A6", "E7", "B7"]) for r, a in ((1, 1), (2.76, .3), (5.4, .12)) for c in (-9, 0, 9))
    choir = (choir / np.abs(choir).max() * np.clip((swell - .03) / .33, 0, 1) ** 1.5 * np.exp(-np.maximum(swell - .36, 0) / .12)
             * (1 + .3 * np.interp(swell, spin, pulse, right=0)) * (1 + .35 * np.sin(2 * np.pi * 11 * swell)))
    sub = np.sin(2 * np.pi * np.cumsum(38 + 22 * spin / .36) / SR) * (spin / .36) ** 2.2 * np.clip((.36 - spin) / .008, 0, 1)
    thud, hiss = secs(.5), secs(.3)
    snap = lambda fc, amp: amp * layered(burst(fc, .6, .003, rng=sling), .5 * burst(fc / 2.6, .5, .009, fc / 3.1, sling))
    s["athanor"] = (.95 if dark else .85, -2 if dark else -4, .16, [(0, strike(hz("E7" if dark else "E8"), SPARK, .4, rng=sling)), (0, snap(4200 if dark else 6400, .3)),
                                               (0, .12 * sweep(.08, 2000 if dark else 3200, 7000 if dark else 10000, .4, .5, .8, sling)),
                                               (.04, .18 * sweep(.22, 900 if dark else 1500, 4200 if dark else 6800, .5, .3, 1.2, sling)),
                                               (0, .5 * whir), (0, 1.5 * crackle), (0, .5 * choir), (0, .35 * sub),
                                               (.36, .75 * np.sin(2 * np.pi * (44 + 85 * np.exp(-thud / .012)) * thud) * np.exp(-thud / .12) * ramp(thud, .0015)),
                                               (.36, snap(3000 if dark else 4800, .6)), (.36, .3 * burst(1400 if dark else 2200, .5, .02, 1250 if dark else 2000, sling)),
                                               (.362, strike(hz("D5" if dark else "D6"), V, .55, .26 if dark else .13, sling)), (.366, strike(hz("A5" if dark else "A6"), V, .4, .2 if dark else .1, sling)),
                                               (.37, strike(hz("E7" if dark else "E8"), SPARK, .35, rng=sling)), (.39, strike(hz("B7" if dark else "B8"), SPARK, .25, rng=sling)),
                                               (.365, .2 * band(len(hiss), 6800 if dark else 9000, .7, sling) * np.exp(-hiss / .1) * ramp(hiss, .003))]
                    + dust(.4, .64, 9, ["E7", "G7", "A7", "C8"] if dark else ["G7", "A7", "C8", "D8"], .07 if dark else .09, sling))
    s["close"] = (1.0, -4, .18, [(.04, .42 * sweep(.6, 5000 if dark else 7000, 1400 if dark else 2200, .4, .2, 1.4))]
                  + [(.06 * i + .08, strike(hz(n), SPARK, .3 - .045 * i)) for i, n in enumerate((["A6", "G6", "E6", "D6", "C6"] if dark else ["A7", "G7", "E7", "D7", "C7"]))]
                  + [(0, crack(3600 if dark else 5600, .8))])
    fuse = np.random.default_rng(8317)
    crinkle = lambda fc, amp: amp * layered(burst(fc, .45, fuse.uniform(.0004, .0009), rng=fuse), .35 * burst(fc * 1.9, .5, .0004, rng=fuse))
    crackle = [(t, crinkle((3800 if dark else 5600) * fuse.uniform(.7, 1.6), (.12 + .5 * fuse.uniform() ** 3) * np.sin(np.pi * min((t - .02) / .4, 1)) ** .6))
               for t in np.sort(.02 + .4 * fuse.uniform(0, 1, 36) ** .8)]
    s["burn"] = (.9, -6, .14, [(.02, .14 * sweep(.4, 5200 if dark else 7000, 7600 if dark else 10000, .45, .4, 1.1, fuse))]
                 + [(t, .12 * burst((5200 if dark else 7400) * fuse.uniform(.8, 1.25), .5, fuse.uniform(.0008, .0018), rng=fuse)) for t in np.sort(fuse.uniform(.03, .4, 18))]
                 + [(.02, .2 * sweep(.46, 2800 if dark else 4200, 6200 if dark else 9000, .55, 1.1, 1.3, fuse))]
                 + crackle + [(t + .0035, .6 * x) for t, x in crackle[::5]]
                 + [(.4, strike(hz("C7" if dark else "C8"), SPARK, .14)), (.47, strike(hz("G6" if dark else "G7"), CRYSTAL, .1, .08, fuse))])
    s["focus"] = (.6 if dark else .4, -9, .1, [(.12, strike(hz("E6" if dark else "E7"), V, .6, .12 if dark else .05)),
                                               (0, .12 * sweep(.13, 1200 if dark else 2200, 3400 if dark else 6000, .5, 1.5, .3, PANE))])
    s["share"] = (1.2 if dark else 1.0, -1, .14, [(0, crack(4200 if dark else 6200, .9 if dark else .55)), (.03, .2 * sweep(.38, 5200 if dark else 7800, 1800 if dark else 2800, .45, .3, .9, PANE))]
                  + laying(.06, .34, 11, hi, .36 if dark else .3)
                  + [(.34, strike(hz("G5" if dark else "G6"), V, .5, .14 if dark else .07, PANE)), (.39, strike(hz("C6" if dark else "C7"), V, .6, .22 if dark else .1, PANE))]
                  + solder(.39, 6, .024, tick, .9 if dark else .6))
    s["give"] = (1.2 if dark else 1.0, -3, .16, [(0, .4 * sweep(.36, 1500 if dark else 2400, 4800 if dark else 7600, .45, 1.4, .4, PANE))]
                 + [(.5, strike(hz("E6" if dark else "E7"), V, .65, .16 if dark else .07, PANE))]
                 + solder(.36, 5, .024, tick, .45))
    s["notify"] = (1.1 if dark else .7, -1, .14, [(0, strike(hz("G5" if dark else "G6"), V, .85)), (.09, strike(hz("D6" if dark else "D7"), V, .7, .3 if dark else .12))]
                   + ([] if dark else dust(.12, .45, 4, ["G7", "A7", "C8"], .1)))
    s["volume"] = (.25, -6, .06, [(0, bubble(hz("G4" if dark else "C6"), hz("D5" if dark else "G6"), .022 if dark else .014)),
                                  (.012, .25 * strike(hz("D6" if dark else "D7"), SPARK, .5))])
    s["menu-open"] = (1.6 if dark else 1.2, 1, .2, [(0, .5 * burst(900 if dark else 1600, .5, .012, 700 if dark else 1300)),
                                                     (.03, .3 * burst(240, .8, .03)),
                                                     (.08, 1.4 * pad(["C4", "G4", "E5"] if dark else ["C5", "G5", "E6", "C7"], .05, .55 if dark else .4))]
                      + [(.1 + .045 * i, strike(hz(n), V, .45 + .1 * i, .25 if dark else .1)) for i, n in enumerate(["C5", "E5", "G5"] if dark else ["C6", "E6", "G6", "C7"])]
                      + ([] if dark else dust(.25, .9, 7, ["G7", "A7", "C8", "D8"], .1)))
    s["menu-close"] = (.8, -3, .14, [(0, .4 * burst(800 if dark else 1400, .5, .01, 650 if dark else 1200)),
                                     (.04, strike(hz("G5" if dark else "G6"), V, .55, .14 if dark else .06)),
                                     (.1, strike(hz("C5" if dark else "C6"), V, .6, .2 if dark else .08))])
    lull = ["G5", "E5", "C5"] if dark else ["E6", "D6", "C6"]
    s["lock"] = (2.6 if dark else 1.8, 0, .22, [(.32 * i, strike(hz(n), V, .8 - .1 * i, .6 if dark else .3)) for i, n in enumerate(lull)]
                 + [(.66, .6 * pad(["C4", "G4"] if dark else ["C5", "G5"], .2, .9 if dark else .6))])
    arp = ["C5", "E5", "G5", "C6", "E6"] if dark else ["C6", "E6", "G6", "C7", "E7"]
    s["unlock"] = (1.8 if dark else 1.4, 0, .18, [(.06 * i, strike(hz(n), V, .5 + .1 * i, .3 if dark else .14)) for i, n in enumerate(arp)]
                   + [(.3, .9 * pad(["C5", "E5", "G5"] if dark else ["C6", "E6", "G6"], .05, .5))]
                   + dust(.3, 1.0, 6 if dark else 10, ["G7", "C8"] if dark else ["G7", "A7", "C8", "D8"], .08 if dark else .12))
    mull = np.random.default_rng(5121)
    shards = ["E7", "G7", "A7", "C8", "D8"] if dark else ["G7", "A7", "C8", "D8", "E8"]
    snap = lambda fc, amp: amp * layered(burst(fc, .6, .003, rng=mull), .5 * burst(fc / 2.6, .5, .009, fc / 3.1, mull))
    flare = [(0, strike(hz("E7" if dark else "E8"), SPARK, .35, rng=mull)), (.012, strike(hz("B6" if dark else "B7"), SPARK, .25, rng=mull))]
    s["unframe"] = (.6, -4 if dark else -5, .12, flare + [(.05, snap(4200 if dark else 6200, .7)), (.05, .12 * sweep(.24, 5000 if dark else 7600, 2600 if dark else 4200, .5, .3, 1.2, mull))]
                    + [(t, snap(3000 if dark else 5000, .3 * (1 - .08 * i))) for i, t in enumerate(np.linspace(.07, .27, 8))]
                    + dust(.07, .3, 10, shards, .18 if dark else .22, mull))
    s["melt"] = (.6, -6, .12, flare + [(.04, .3 * sweep(.4, 2200 if dark else 3600, 6800 if dark else 9600, .6, 1.2, .5, mull)),
                                       (.2, bubble(hz("G5" if dark else "G6"), hz("C5" if dark else "C6"), .05, .4))])
    s["expand"] = (.75, -7, .16, [(0, .2 * sweep(.42, 1600 if dark else 2600, 5600 if dark else 8800, .5, 1.1, .6, mull))]
                   + dust(.04, .42, 9, hi, .1 if dark else .12, mull)
                   + [(.38, strike(hz("E6" if dark else "E7"), V, .35, .14 if dark else .07, mull))])
    s["weld"] = (.22, -18, .08, [(0, layered(burst(tick, .25, .0025, tick * 1.07, mull), .1 * burst(tick * 2, .9, .03, rng=mull))),
                                 (.01, .06 * sweep(.09, 5000 if dark else 7000, 8000 if dark else 11000, .4, .2, 1.5, mull))])
    s["confirm"] = (.85, -5, .16, laying(0, .22, 8, hi, .22 if dark else .2)
                    + [(.14, strike(hz("G5" if dark else "G6"), V, .5, .14 if dark else .07, mull)), (.21, strike(hz("C6" if dark else "C7"), V, .6, .22 if dark else .1, mull))])
    s["gather"] = (.55, -14, .2, [(0, .2 * sweep(.4, 5000 if dark else 7000, 9000 if dark else 12000, .5, 1.6, .25, mull))] + dust(.05, .4, 6, shards, .06, mull))
    knock = secs(.2)
    for i, n in enumerate(["C4", "D4", "E4", "G4", "A4", "C5", "D5", "E5"] if dark else ["C5", "D5", "E5", "G5", "A5", "C6", "D6", "E6"], 1):
        thud = .5 * np.sin(2 * np.pi * (95 + 60 * np.exp(-knock / .008)) * knock) * np.exp(-knock / .035) * ramp(knock, .001)
        s[f"stone-{i}"] = (.4, -7, .1, [(0, snap(2600 if dark else 4000, .5)), (0, thud), (.004, strike(hz(n), V, .55, .18 if dark else .08, mull))])
    s["blink"] = (.22, -9, .1, [(0, strike(hz("C8"), SPARK, .4, rng=mull)), (.05, strike(hz("C8"), SPARK, .4, rng=mull)), (0, .1 * sweep(.1, 7000, 9000, .4, .5, 1, mull))])
    thump = secs(.6)
    s["boom"] = (1.6, -1 if dark else -4, .22, [(0, .9 * np.sin(2 * np.pi * (48 + 70 * np.exp(-thump / .025)) * thump) * np.exp(-thump / .16) * ramp(thump, .002)),
                                (0, snap(3200 if dark else 5200, .9)), (0, .45 * burst(900 if dark else 1500, .9, .06, rng=mull)),
                                (.01, .25 * sweep(.5, 6000 if dark else 9000, 1500 if dark else 2400, .5, .1, 1.4, mull))]
                 + dust(.03, .7, 16, shards, .22 if dark else .26, mull)
                 + [(.19, strike(hz("G5" if dark else "G6"), V, .55, .2 if dark else .09, mull)), (.24, strike(hz("C6" if dark else "C7"), V, .65, .3 if dark else .12, mull))]
                 + laying(.15, .5, 8, hi, .14))
    pane = np.random.default_rng(7305)
    snap = lambda fc, amp: amp * layered(burst(fc, .6, .003, rng=pane), .5 * burst(fc / 2.6, .5, .009, fc / 3.1, pane))
    s["shatter"] = (.45, -5 if dark else -9, .1, [(0, snap(4200 if dark else 6200, .8))]
                    + [(.004, .14 * sweep(.18, 4200 if dark else 7000, 9000 if dark else 12000, .5, .6, 1, pane))]
                    + dust(.01, .19, 16, shards, .22 if dark else .26, pane)
                    + [(.06, strike(hz("E7" if dark else "E8"), SPARK, .3, rng=pane))])
    run = ["C6", "D6", "E6", "G6", "A6"] if dark else ["C7", "D7", "E7", "G7", "A7"]
    thump = secs(.5)
    s["set"] = (1.0, -2, .16, [(.03 * i, strike(hz(n), SPARK, .3 + .08 * i, rng=pane)) for i, n in enumerate(run)]
                + [(.17, .55 * np.sin(2 * np.pi * (62 + 40 * np.exp(-thump / .02)) * thump) * np.exp(-thump / .09) * ramp(thump, .002))]
                + [(.17, strike(hz(n), V, a, .5 if dark else .24, pane)) for n, a in zip(["C5", "G5", "E6"] if dark else ["C6", "G6", "E7"], (.7, .6, .5))]
                + solder(.17, 5, .02, tick, .6 if dark else .45, pane)
                + dust(.24, .75, 8, ["G7", "A7", "C8", "D8"], .1, pane))
    s["relead"] = (.5, -12, .1, [(0, .35 * sweep(.34, 1500 if dark else 2400, 4600 if dark else 7600, .5, 1, .6, pane))]
                   + laying(0, .3, 6, hi, .22 if dark else .2)
                   + [(.3 + .06 * i, strike(hz(n), V, .4 - .08 * i, .1 if dark else .05, pane)) for i, n in enumerate(["E6", "G6", "C7"] if dark else ["E7", "G7", "C8"])])
    lay = np.random.default_rng(3191)
    tone = lambda f, i: f * 2 ** (i // 3 + (0, 4, 7)[i % 3] / 12)
    run = lambda bass, chord: [up * hz(bass) * 2 ** (k / 12) for k in range(48) if ("C D EF G A B".index(bass[0]) + k) % 12 in chord][:12]
    s["forge"] = (.8, -12, .14, [(.01 * k, strike(tone(up * hz("C4"), i), {**V, "attack": .02}, .6, .25 if dark else .12, lay)) for k, i in enumerate((0, 2))])
    for o, (bass, chord, hold) in enumerate([("G3", (0, 2, 4, 7), .34), ("A3", (0, 5, 7, 9), .24), ("B3", (2, 7, 9, 11), .16), ("C4", (0, 2, 4, 7), .13)], 1):
        for i, f in enumerate(run(bass, chord), 1):
            s[f"link-{o}-{i}"] = (hold + .4, (-8 if dark else -7) - 3 * (12 - i) / 11, .14 if dark else .1, [(0, ring(f, V, 1, hold))])
    for o, (root, low) in enumerate((("C5", -1), ("F4", 0), ("G4", 0), ("C5", 0))):
        s[f"turn-{o}"] = (.9, -8, .14 if dark else .1, [(.009 * k, ring(tone(up * hz(root), low + i), V, a, .3)) for k, (i, a) in enumerate(zip((0, 1, 2, 3), (.9, .7, .65, .6)))])
    roll = list(zip((0, 2, 3, 4, 5, 6, 7), (.8, .6, .55, .5, .5, .5, .55)))
    for name, notes, spark in (("seal", roll, .1), ("seal-down", roll[::-1], 0)):
        s[name] = (1.9, -1, .18, [(.013 * k, ring(tone(up * hz("C4"), i), V, a, .9, .3)) for k, (i, a) in enumerate(notes)]
                   + ([] if dark else [(spark, strike(2 * tone(up * hz("C4"), 6), SPARK, .25))]))
    pyre = np.random.default_rng(6907)
    snap = lambda fc, amp: amp * layered(burst(fc, .6, .003, rng=pyre), .5 * burst(fc / 2.6, .5, .009, fc / 3.1, pyre))
    crackle = lambda t0, t1, count, fc, amp: [(t, amp * (1 - (t - t0) / (t1 - t0)) ** .7 * pyre.uniform(.25, 1) * burst(fc * pyre.uniform(.6, 1.6), .6, pyre.uniform(.0012, .004), rng=pyre))
                                              for t in np.sort(pyre.uniform(t0, t1, count))]
    roar = secs(.62 / HASTE)
    flicker = 1 + .45 * band(len(roar), 7 * HASTE, 1.2, pyre)
    whump = secs(.3)
    s["blaze"] = (.9 / HASTE + .1 * (HASTE - 1), -4, .14, [(0, .55 * band(len(roar), 520 if dark else 900, 1.1, pyre) * flicker * (1 - np.exp(-roar / (.05 / HASTE))) * np.exp(-roar / (.22 / HASTE))),
                                 (0, .5 * np.sin(2 * np.pi * (58 + 40 * np.exp(-whump / .02)) * whump) * np.exp(-whump / .07) * ramp(whump, .003)),
                                 (0, snap(3400 if dark else 5600, .55)), (.01 / HASTE, .3 * sweep(.5 / HASTE, 900 if dark else 1600, 3200 if dark else 5200, .7, .4, 1.2, pyre))]
                  + crackle(.01 / HASTE, .48 / HASTE, 70, 2800 if dark else 4600, .5 if dark else .4))
    rise = ["C6", "D6", "E6", "G6", "A6", "C7", "D7", "E7"] if dark else ["C7", "D7", "E7", "G7", "A7", "C8", "D8", "E8"]
    s["embers"] = (.75 / HASTE + .075 * (HASTE - 1), -11, .14, [((.04 + .055 * i + .012 * pyre.uniform()) / HASTE, strike(hz(n), SPARK, (.16 + .02 * i) * pyre.uniform(.7, 1))) for i, n in enumerate(rise)]
                   + [(0, .2 * sweep(.55 / HASTE, 1100 if dark else 1900, 5200 if dark else 8400, .5, .8, .9, pyre))]
                   + dust(.05 / HASTE, .5 / HASTE, 9, shards, .07 if dark else .09, pyre))
    s["draft"] = (.75 / HASTE + .075 * (HASTE - 1), -9, .2, [(0, .2 * sweep(.13 / HASTE, 1500 if dark else 2400, 850 if dark else 1400, .6, .5, 1.2, pyre)),
                                (.05 / HASTE, .6 * sweep(.34 / HASTE, 560 if dark else 950, 3800 if dark else 6200, .55, 1.4, .7, pyre)),
                                (.12 / HASTE, .16 * sweep(.24 / HASTE, 3000 if dark else 5000, 8000 if dark else 11000, .4, 1.1, 1, pyre))]
                  + dust(.16 / HASTE, .32 / HASTE, 5, shards, .05 if dark else .07, pyre))
    fall = ["E7", "D7", "C7", "A6", "G6", "E6"] if dark else ["E8", "D8", "C8", "A7", "G7", "E7"]
    s["pour"] = (1.0 / HASTE + .1 * (HASTE - 1), -7, .2, [(0, strike(hz("E6" if dark else "E7"), V, .4, .16 if dark else .08, pyre)),
                              (0, .16 * sweep(.5 / HASTE, 2400 if dark else 4000, 7600 if dark else 11000, .5, .25, 1.3, pyre))]
                  + [((.02 + .44 * (1 - (1 - i / 18) ** .5)) / HASTE, strike(hz(fall[i % len(fall)]), SPARK if dark else CRYSTAL, (.28 - .01 * i) * pyre.uniform(.6, 1), rng=pyre)) for i in range(18)])
    thud = secs(.6)
    halo = ["E6", "B6", "E7", "G7", "B7"] if dark else ["E7", "B7", "E8", "G8"]
    s["strike"] = (1.4, -3, .24, [(0, .8 * np.sin(2 * np.pi * (42 + 80 * np.exp(-thud / .014)) * thud) * np.exp(-thud / .13) * ramp(thud, .0015)),
                                  (0, .45 * burst(650 if dark else 1000, .9, .016, rng=pyre)), (0, snap(4600 if dark else 7200, .9))]
                  + crackle(.003, .08, 26, 3600 if dark else 5800, .6)
                  + [(.012 + .03 * i, strike(hz(n), V, (.42 - .06 * i) * pyre.uniform(.8, 1), .5 if dark else .3, pyre)) for i, n in enumerate(halo)]
                  + [(.015, .22 * sweep(1.0, 3000 if dark else 5000, 9000 if dark else 12500, .5, .15, 1.8, pyre))]
                  + dust(.06, .8, 12, shards, .08 if dark else .1, pyre))
    turn = np.random.default_rng(3011)
    snap = lambda fc, amp: amp * layered(burst(fc, .6, .003, rng=turn), .5 * burst(fc / 2.6, .5, .009, fc / 3.1, turn))
    grind = secs(.26)
    speed = grind / .26
    rasp = band(len(grind), 1400 if dark else 2400, .9, turn) * (1 + .7 * band(len(grind), 45, 1, turn))
    s["scrape"] = (.45, -9, .12, [(0, .55 * rasp * (.2 + .8 * speed ** 1.6) * ramp(grind, .02)),
                                  (0, .3 * sweep(.26, 800 if dark else 1400, 4600 if dark else 7600, .45, 1.8, .03, turn))]
                   + [(t, (.15 + .5 * t / .26) * burst((2600 if dark else 4200) * turn.uniform(.7, 1.4), .5, turn.uniform(.001, .003), rng=turn))
                      for t in .26 * np.sqrt(np.sort(turn.uniform(0, 1, 40)))]
                   + dust(.14, .26, 7, shards, .07 if dark else .09, turn))
    thud = secs(.5)
    peal = ["C5", "G5", "C6", "E6"] if dark else ["C6", "G6", "C7", "E7"]
    s["slam"] = (1.0, -3 if dark else -4.5, .2, [(0, (.8 if dark else .45) * np.sin(2 * np.pi * (50 + 75 * np.exp(-thud / .012)) * thud) * np.exp(-thud / .1) * ramp(thud, .0015)),
                               (0, snap(3800 if dark else 6000, 1.)), (.007, snap(2300 if dark else 3700, .6)),
                               (0, .4 * burst(750 if dark else 1200, .8, .03, rng=turn))]
                  + [(.012 + .022 * i, strike(hz(n), V, .42 - .07 * i, .3 if dark else .16, turn)) for i, n in enumerate(peal)]
                  + dust(.02, .45, 12, shards, .1 if dark else .12, turn))
    gate = np.random.default_rng(4129)
    flow = secs(.26)
    swell = (.25 + .75 * (flow / .26) ** 1.5) * (1 - np.exp(-(.26 - flow) / .004)) * ramp(flow, .01)
    fifth = ["E7", "A6"] if dark else ["E8", "A7"]
    s["sluice"] = (.45, -9, .12, [(0, .4 * band(len(flow), 3200 if dark else 5200, .8, gate) * swell),
                                  (0, .35 * band(len(flow), 480 if dark else 820, 1., gate) * swell * (1 + .5 * band(len(flow), 30, 1, gate)))]
                   + [(t, layered(strike(hz(fifth[i % 2]), SPARK, .1 + .25 * t / .26),
                                  (.1 + .3 * t / .26) * burst((2600 if dark else 4200) * gate.uniform(.8, 1.25), .5, gate.uniform(.0008, .002), rng=gate)))
                      for i, t in enumerate((np.sqrt(1600 + 960 * np.arange(25)) - 40) / 480)])
    quarry = np.random.default_rng(5813)
    snap = lambda fc, amp: amp * layered(burst(fc, .6, .003, rng=quarry), .5 * burst(fc / 2.6, .5, .009, fc / 3.1, quarry))
    zap = lambda fc, amp: amp * layered(burst(fc, .45, quarry.uniform(.0004, .0009), rng=quarry), .35 * burst(fc * 1.9, .5, .0004, rng=quarry))
    hammer = {**V, "attack": .0015}
    for i, n in enumerate(["G4", "A4", "B4", "D5", "E5", "G5", "A5", "B5"], 1):
        s[f"glaze-{i}"] = (.4, -14.5 + 4 * i / 8, .1 if dark else .08, [(0, snap(3400 if dark else 5400, .45)), (0, ring(up * hz(n), hammer, 1, .07, .08))])
    s["glaze-slam"] = (.9, -3 if dark else -4.5, .16, [(0, snap(3800 if dark else 6000, 1.)), (.006, snap(2300 if dark else 3700, .6)), (.03, snap(3000 if dark else 4800, .2)),
                                                      (0, .45 * burst(800 if dark else 1300, .6, .012, 640 if dark else 1050, quarry))]
                      + [(.004 * k, ring(up * hz(n), hammer, .5, .16, .2)) for k, n in enumerate(["C4", "G4", "E5", "C6"])])
    s["glaze-run"] = (.4, -8, .1, [(t, zap((2600 if dark else 4400) * (1 + .6 * t / .11) * quarry.uniform(.8, 1.25), (.4 + .6 * quarry.uniform() ** 2) * np.sin(np.pi * min(t / .11, 1)) ** .4))
                                   for t in np.sort(.11 * quarry.uniform(0, 1, 70) ** .8)]
                     + [(0, .12 * sweep(.11, 3000 if dark else 5000, 5200 if dark else 8600, .4, .4, .8, quarry))]
                     + [(.012 + .022 * k, strike(up * hz(n), SPARK, .1 + .03 * k)) for k, n in enumerate(["G6", "C7", "E7", "G7"])])
    s["glaze-weld"] = (.4, -13, .1, [(.016 * k * (1 + .2 * k), (1 - .12 * k) * layered(burst(hz(n) / 1.07, .25, .0025, hz(n), quarry), .12 * burst(2 * hz(n), .9, .03, rng=quarry)))
                                     for k, n in enumerate(["C8", "G7", "E7", "C7", "G6"] if dark else ["G8", "E8", "C8", "G7", "E7"])]
                      + [(0, .05 * sweep(.12, 5000 if dark else 7000, 8000 if dark else 11000, .4, .2, 1.5, quarry))])
    s["glaze-gild"] = (.6, -10, .12, [(0, snap(5000 if dark else 7400, .3)), (0, strike(up * hz("C7"), V, .55, .1 if dark else .05, quarry)), (.008, strike(up * hz("G7"), SPARK, .35))]
                      + dust(.02, .14, 9, shards, .3 if dark else .34, quarry))
    s["glaze-crack"] = (.5, -8 if dark else -9, .12, [(0, snap(4400 if dark else 6600, .8)), (0, strike(up * hz("E7"), SPARK, .3)), (.01, strike(up * hz("C7"), SPARK, .22))]
                       + [(t, zap((3400 if dark else 5600) * quarry.uniform(.75, 1.5), (.25 + .6 * quarry.uniform()) * (1 - t / .08) ** .7)) for t in np.sort(.08 * quarry.uniform(0, 1, 24) ** 1.6)]
                       + [(.02, .08 * sweep(.11, 4600 if dark else 7000, 2400 if dark else 3800, .5, .3, 1.2, quarry))])
    for i, n in enumerate(["E6", "D6", "C6", "A5", "G5", "E5", "D5", "C5"], 1):
        s[f"glaze-lift-{i}"] = (.35, -11 - 2 * i / 8, .1 if dark else .08, [(0, .8 * burst(3800 if dark else 6400, .5, .0012, rng=quarry)), (0, ring(up * hz(n), hammer, 1, .05, .07)),
                                                                          (.004, strike(2 * up * hz(n), SPARK, .18))])
    return s

def main():
    report = []
    for world in ("dark", "light"):
        fc = 5200 if world == "dark" else 9000
        rendered = {name: (render(dur, ev, wet, fc), trim) for name, (dur, trim, wet, ev) in events(world).items()}
        ref = loud40(rendered["ws-3"][0])
        for name, (x, trim) in rendered.items():
            x = x * 10 ** ((ref + trim - loud40(x)) / 20)
            rendered[name] = (x, trim)
        top = max(np.abs(x).max() for x, _ in rendered.values())
        for name, (x, _) in rendered.items():
            y = x / top * 10 ** (-3 / 20)
            write(OUT / world / f"{name}.wav", y)
            report.append(f"{world:5} {name:11} {len(y) / SR:5.2f} s  peak {20 * np.log10(np.abs(y).max()):6.1f} dB  L40 {loud40(y):6.1f}")
    print("\n".join(report))

if __name__ == "__main__":
    main()
