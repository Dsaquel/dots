import pathlib
import wave

import numpy as np

from synth import SR, GLASS, CRYSTAL, SPARK, hz, secs, ramp, band, strike, bubble, burst, sweep, dust, layered, laying, solder, render, loud40, write

OUT = pathlib.Path(__file__).resolve().parent.parent.parent / "sounds"
JEWELS = "C6 D6 E6 G6 A6 C7".split()


def read(path):
    with wave.open(str(path)) as w:
        return np.frombuffer(w.readframes(w.getnframes()), "<i2") / 32768


def crinkles(t0, t1, count, fc, amp, rng, shape=lambda u: np.sin(np.pi * u) ** .6):
    return [(t, amp * shape((t - t0) / (t1 - t0)) * rng.uniform(.25, 1) ** 2
             * layered(burst(fc * rng.uniform(.7, 1.6), .45, rng.uniform(.0003, .0009), rng=rng), .35 * burst(fc * 1.9, .5, .0004, rng=rng)))
            for t in np.sort(t0 + (t1 - t0) * rng.uniform(0, 1, count) ** .9)]


def hiss(dur, fc, rng):
    t = secs(dur)
    whine = np.sin(2 * np.pi * np.cumsum(fc * .5 * (1 + .02 * band(len(t), 30, 1, rng))) / SR)
    return (band(len(t), fc, .35, rng) + .25 * whine) * np.sin(np.pi * t / dur) ** .8


def events(world):
    dark = world == "dark"
    V = GLASS if dark else CRYSTAL
    up = 1 if dark else 2
    rng = np.random.default_rng(7391 if dark else 7392)
    s = {}
    frost = secs(.6)
    s["cutter-freeze"] = (.9, -4, .18, [(0, .3 * band(len(frost), 5200 * up, .9, rng) * (frost / .6) ** .5 * np.exp(-frost / .25) * ramp(frost, .02)),
                                         (0, .2 * sweep(.5, 6000 * up, 2400 * up, .4, .2, 1.4, rng)),
                                         (.0, .5 * burst(3800 * up, .5, .003, 4300 * up, rng))]
                         + crinkles(.01, .5, 80, 4200 * up, .7, rng)
                         + [(.32, strike(up * hz("E7"), SPARK, .25)), (.36, strike(up * hz("B6"), CRYSTAL, .18, .12, rng))]
                         + dust(.3, .6, 6, ["E7", "B7", "E8"] if dark else ["B7", "E8", "G8"], .07, rng))
    for i, fc in enumerate(np.geomspace(2600, 6800, 6), 1):
        s[f"cutter-score-{i}"] = (.12, -14 + i * .6, .06, [(0, .55 * hiss(.11, fc * up ** .5, rng))]
                                  + crinkles(0, .1, 6, fc * 1.3 * up ** .5, .35, rng, lambda u: 1 - u))
    s["cutter-snap"] = (.8, -2, .16, [(0, layered(burst(4400 * up, .6, .003, rng=rng), .5 * burst(1700 * up, .5, .009, 1400 * up, rng))),
                                      (.004, .5 * burst(2600 * up, .5, .006, 2900 * up, rng)),
                                      (.006, strike(up * hz("C7"), CRYSTAL, .45, .12, rng)), (.01, strike(up * hz("G6"), V, .35, .2 if dark else .1, rng))]
                       + crinkles(.01, .12, 18, 5200 * up, .4, rng, lambda u: (1 - u) ** 1.5)
                       + dust(.04, .3, 5, ["G7", "C8", "E8"], .06, rng))
    s["cutter-hover"] = (.18, -18, .06, [(0, layered(burst(2400 * up, .25, .002, 2600 * up, rng), .1 * burst(5000 * up, .9, .02, rng=rng))),
                                         (.002, strike(up * hz("G5"), {**V, "attack": .001}, .25, .04, rng))])
    for i, n in enumerate(JEWELS, 1):
        s[f"cutter-jewel-{i}"] = (.3, -16, .1, [(0, strike(up * hz(n), CRYSTAL, .5, .08, rng)), (.01, strike(2 * up * hz(n), SPARK, .15))])
    s["cutter-copy"] = (.8, -5, .16, [(0, .25 * sweep(.3, 1800 * up, 7200 * up, .45, 1.5, .4, rng))]
                       + laying(.0, .22, 8, ["C7", "E7", "G7", "C8"] if dark else ["G7", "C8", "E8", "G8"], .25)
                       + [(.26, strike(up * hz("C7"), V, .5, .18 if dark else .09, rng)), (.27, strike(up * hz("G7"), SPARK, .35))])
    s["cutter-save"] = (1.0, -4, .18, [(0, .4 * burst(900 * up, .5, .02, 800 * up, rng)),
                                       (0, strike(up * hz("C5"), V, .6, .35 if dark else .16, rng)), (.04, strike(up * hz("G5"), V, .45, .3 if dark else .14, rng))]
                       + solder(.08, 4, .03, 2600 * up, .6, rng)
                       + [(.2, strike(up * hz("E6"), V, .35, .2 if dark else .1, rng))])
    scratch = secs(.28)
    s["cutter-annotate"] = (.6, -7, .12, [(0, .35 * band(len(scratch), 3400 * up, .5, rng) * (.5 + .5 * np.sin(2 * np.pi * 18 * scratch) ** 2) * np.sin(np.pi * scratch / .28))]
                           + [(.3, strike(up * hz("A6"), V, .4, .14 if dark else .07, rng))])
    s["cutter-ocr"] = (.8, -7, .14, [(.035 * k, layered(burst(3000 * up, .3, .002, 3300 * up, rng), strike(up * hz(n), SPARK, .2))) for k, n in enumerate(["C6", "D6", "E6", "G6", "A6", "C7"])]
                      + [(.24, strike(up * hz("E7"), V, .4, .16 if dark else .08, rng))])
    s["cutter-pick"] = (.5, -8, .12, [(0, bubble(hz("C6") * up, hz("G6") * up, .012, .8)), (.01, strike(up * hz("E7"), CRYSTAL, .4, .09, rng))])
    hum = secs(.7)
    s["cutter-record"] = (1.0, -5, .16, [(0, .35 * np.sin(2 * np.pi * 110 * up * hum) * (1 - np.exp(-hum / .12)) * np.exp(-hum / .3)),
                                         (0, strike(up * hz("D5"), V, .55, .4 if dark else .2, rng)), (.06, strike(up * hz("A5"), V, .45, .36 if dark else .18, rng)),
                                         (.12, strike(up * hz("D6"), V, .4, .3 if dark else .15, rng))])
    s["cutter-stop"] = (.8, -5, .14, [(0, strike(up * hz("D6"), V, .5, .2 if dark else .1, rng)), (.07, strike(up * hz("A5"), V, .45, .26 if dark else .12, rng)),
                                      (.14, strike(up * hz("D5"), V, .45, .34 if dark else .16, rng)), (0, .4 * burst(2400 * up, .5, .002, 2600 * up, rng))])
    s["cutter-thaw"] = (1.0, -6, .18, [(0, .3 * sweep(.7, 6000 * up, 1600 * up, .45, .3, 1.2, rng))]
                       + [(t, bubble(f * up, f * up * .6, rng.uniform(.01, .02), .35 * rng.uniform(.4, 1)))
                          for t, f in zip(np.sort(rng.uniform(.05, .7, 12)), np.geomspace(2400, 900, 12))]
                       + [(.5 * k / 6, strike(up * hz(n), SPARK, .14 - .015 * k)) for k, n in enumerate(["E8", "B7", "G7", "E7", "B6", "G6"])])
    return s


def main():
    report = []
    for world in ("dark", "light"):
        fc = 5200 if world == "dark" else 9000
        ref = loud40(read(OUT / world / "ws-3.wav"))
        for name, (dur, trim, wet, ev) in events(world).items():
            x = render(dur, ev, wet, fc)
            x = x * 10 ** ((ref + trim - loud40(x)) / 20)
            x = x * min(1, 10 ** (-3 / 20) / np.abs(x).max())
            write(OUT / world / f"{name}.wav", x)
            report.append(f"{world:5} {name:16} {len(x) / SR:5.2f} s  peak {20 * np.log10(np.abs(x).max()):6.1f} dB  L40 {loud40(x):6.1f}")
    print("\n".join(report))


main()
