import pathlib
import wave

import numpy as np

from synth import SR, GLASS, CRYSTAL, SPARK, hz, secs, ramp, band, strike, bubble, burst, sweep, dust, laying, render, loud40, write

OUT = pathlib.Path(__file__).resolve().parent.parent.parent / "sounds"
FILL = "C5 D5 E5 G5 A5 C6 D6 E6 G6 A6 C7 D7".split()
POUR = "G4 A4 C5 D5 E5 G5 A5 C6".split()


def read(path):
    with wave.open(str(path)) as w:
        return np.frombuffer(w.readframes(w.getnframes()), "<i2") / 32768


def gurgle(dur, fc, rng):
    t = secs(dur)
    wob = 1 + .35 * band(len(t), 14, 1, rng)
    return band(len(t), fc, .7, rng) * wob * np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 1.5


def bubbles(t0, t1, count, f0, rise, amp, rng, tau=(.006, .016)):
    return [(t, bubble(f * rng.uniform(.9, 1.1), f * rise * rng.uniform(1.2, 1.7), rng.uniform(*tau), amp * rng.uniform(.4, 1)))
            for t, f in zip(np.sort(rng.uniform(t0, t1, count)), np.geomspace(f0, f0 * 1.5, count))]


def events(world):
    dark = world == "dark"
    V = GLASS if dark else CRYSTAL
    up = 1 if dark else 2
    rng = np.random.default_rng(4471 if dark else 4472)
    s = {}
    seat = .245
    knock = secs(.08)
    s["phial-rise"] = (.9, -3, .16, [(0, .22 * sweep(.26, 1400 * up, 5200 * up, .45, 1.6, .3, rng))]
                      + laying(.02, .2, 9, ["E6", "G6", "A6", "C7", "D7", "E7"] if dark else ["E7", "G7", "A7", "C8", "D8", "E8"], .22)
                      + [(.11, strike(up * hz("E5"), V, .32, .18 if dark else .09, rng))]
                      + [(seat, .7 * burst(2600 * up, .5, .0025, 2900 * up, rng)),
                         (seat, .35 * np.sin(2 * np.pi * 180 * knock) * np.exp(-knock / .012) * ramp(knock, .001)),
                         (seat + .002, strike(up * hz("B5"), {**V, "attack": .001}, .45, .07, rng)),
                         (seat + .004, strike(up * hz("G6"), SPARK, .3))]
                      + bubbles(seat + .02, .62, 9, 700 * up, 1.4, .35, rng)
                      + [(seat + .02, .1 * gurgle(.35, 900 * up, rng))])
    s["phial-fade"] = (1.0, -6, .18, [(.0, .45 * burst(3000 * up, .5, .002, 3300 * up, rng)), (.004, strike(up * hz("A5"), SPARK, .2))]
                      + [(.03, .3 * sweep(.6, 2400 * up, 8000 * up, .5, .4, 1.6, rng))]
                      + dust(.06, .55, 10, ["A7", "G7", "E7", "D7", "C7"] if dark else ["A8", "G8", "E8", "D8", "C8"], .09, rng)
                      + bubbles(.02, .3, 6, 1400 * up, 1.2, .18, rng))
    for i, n in enumerate(FILL, 1):
        f = hz(n)
        s[f"phial-fill-{i}"] = (.45, -10, .12, [(0, bubble(f * .5 * up, f * .9 * up, .018 if dark else .012, .9)),
                                                 (.014, strike(up * f, V, .35, .14 if dark else .07, rng)),
                                                 (.02, strike(2 * up * f, SPARK, .12))]
                                + bubbles(.03, .16, 2, f * .7 * up, 1.3, .25, rng))
    for i, n in enumerate(POUR, 1):
        f = hz(n)
        s[f"phial-pour-{i}"] = (.26, -13, .1, [(0, .35 * gurgle(.16, f * 1.6 * up, rng))] + bubbles(0, .12, 4, f * up, 1.5, .55, rng)
                                + [(.03, strike(2 * up * f, SPARK, .1))])
    s["phial-lift"] = (.6, -12, .16, [(0, strike(up * hz("D6"), {**V, "attack": .006}, .4, .3 if dark else .14, rng)),
                                      (0, strike(up * hz("A6"), {**V, "attack": .006}, .2, .22 if dark else .1, rng)),
                                      (0, .12 * sweep(.2, 900 * up, 2200 * up, .5, .3, 1.5, rng))])
    thud = secs(.12)
    s["phial-clink"] = (.7, -5, .16, [(0, .6 * np.sin(2 * np.pi * (70 + 90 * np.exp(-thud / .01)) * thud) * np.exp(-thud / .035) * ramp(thud, .001)),
                                      (0, .5 * burst(3400 * up, .5, .0018, 3800 * up, rng)),
                                      (.001, strike(up * hz("E6"), {**V, "attack": .0008}, .55, .2 if dark else .1, rng)),
                                      (.045, strike(up * hz("B6"), {**V, "attack": .0008}, .3, .14 if dark else .07, rng)),
                                      (.046, .25 * burst(4200 * up, .5, .0012, rng=rng))]
                       + bubbles(.02, .2, 5, 900 * up, 1.4, .3, rng))
    s["phial-slosh"] = (.45, -11, .12, [(0, .5 * gurgle(.3, 700 * up, rng)), (.02, .3 * gurgle(.22, 1500 * up, rng))]
                       + bubbles(.03, .25, 6, 600 * up, 1.5, .4, rng))
    s["phial-mute"] = (.7, -6, .14, [(0, bubble(hz("A5") * up, hz("D5") * up, .03, .7)),
                                     (.05, .5 * burst(1500 * up, .5, .004, 1700 * up, rng)),
                                     (.06, strike(up * hz("D5"), {**V, "fc": 1600, "attack": .002}, .5, .2 if dark else .1, rng)),
                                     (.06, .25 * sweep(.4, 2600 * up, 700 * up, .5, .2, 1.4, rng))])
    s["phial-unmute"] = (.8, -6, .16, [(0, .2 * sweep(.3, 900 * up, 3600 * up, .5, 1.2, .5, rng))]
                        + bubbles(0, .22, 7, 500 * up, 1.6, .45, rng)
                        + [(.2, strike(up * hz("G5"), V, .45, .2 if dark else .1, rng)), (.24, strike(up * hz("D6"), V, .4, .26 if dark else .12, rng))])
    s["phial-boil"] = (.5, -12, .1, bubbles(0, .32, 16, 1100 * up, 1.3, .5, rng, (.003, .008)) + [(0, .12 * sweep(.35, 3000 * up, 6000 * up, .5, .4, 1.2, rng))])
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
            report.append(f"{world:5} {name:14} {len(x) / SR:5.2f} s  peak {20 * np.log10(np.abs(x).max()):6.1f} dB  L40 {loud40(x):6.1f}")
    print("\n".join(report))


main()
