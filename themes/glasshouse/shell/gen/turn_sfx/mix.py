import json
import os
import subprocess
import wave

import numpy as np

from .anime import anime, clap, inhale
from .dsp import SR, WORLDS
from .gens import gen4, gen5
from .paths import FOLEY, OUT, SHEET
from .rebuild import rebuild
from .still import bolts, still


def foley():
    takes = {}
    if not os.path.isdir(FOLEY):
        print(f"turn: no pack at {FOLEY}, fx-* foley cues dropped")
        return {w: takes for w, _ in WORLDS}
    for name in sorted(f[:-4] for f in os.listdir(FOLEY) if f.endswith(".wav")):
        with wave.open(os.path.join(FOLEY, name + ".wav")) as w:
            x = np.frombuffer(w.readframes(w.getnframes()), "<i2") / 32768
        x = x * min(10 ** (-21 / 20) / np.sqrt((x ** 2).mean()), 0.95 / np.abs(x).max())
        takes["fx-" + name] = np.round(x * 32767).astype(np.int16)
    return {w: takes for w, _ in WORLDS}


def sheet():
    return json.load(open(SHEET))


def cues(sh=None):
    sh = sh or sheet()
    rb = {c[0]: c[1] for c in sh["cues"]["dawn"]["rebuild"]}
    out = {w: {} for w, _ in WORLDS}
    for part in (gen4(), gen5(), anime(), inhale(), clap(), rebuild(rb["rb-rise"], rb["rb-clinks"]), still(), bolts(sh), foley()):
        for w in out:
            out[w].update(part[w])
    return out


def limit(x, level):
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", "-",
                          "-af", f"alimiter=limit={level}", "-f", "f32le", "-"],
                         input=x.astype("<f4").tobytes(), capture_output=True, check=True).stdout
    return np.frombuffer(raw, "<f4").astype(np.float64)


def stem(world, name, sh, sounds):
    s = sh["stems"][name]
    lines = [c for c in sh["cues"][world][name] if os.path.isdir(FOLEY) or not c[0].startswith("fx-")]
    origin = s.get("from", min(c[1] for c in lines))
    n = max(int(round((c[1] - origin) * SR)) + len(sounds[c[0]]) for c in lines) + int(0.1 * SR)
    mix = np.zeros(n)
    for c in lines:
        cue, at, vol = c[0], c[1], c[2]
        opt = c[3] if len(c) > 3 else {}
        x = sounds[cue]
        if "fade" in opt:
            tt = np.arange(len(x)) / SR
            x = (x.astype(np.float64) * np.clip((opt["fade"] - tt) / 0.18, 0.0, 1.0) ** 2).astype(np.int16)
        x = x.astype(np.float64) / 32768
        if "skip" in opt:
            x = x[int(round(opt["skip"] * SR)):]
        if "cut" in opt:
            x = x[: int(round(opt["cut"] * SR))]
        if "in" in opt:
            x = x * np.minimum(1.0, np.arange(len(x)) / (opt["in"] * SR)) ** 2
        i = int(round((at - origin) * SR))
        mix[i:i + len(x)] += vol * x
    return origin, limit(mix, sh["limit"])


def write(path, x):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(np.round(np.clip(x, -1, 32767 / 32768) * 32768).astype("<i2").tobytes())


def build():
    sh = sheet()
    sounds = cues(sh)
    for world, _ in WORLDS:
        for name in sh["stems"]:
            origin, x = stem(world, name, sh, sounds[world])
            write(os.path.join(OUT, world, f"{name}.wav"), x)
            print(f"{world:4} {name:7} from {origin:6.3f}  {len(x) / SR:5.2f} s  peak {20 * np.log10(np.abs(x).max()):5.1f} dB")
