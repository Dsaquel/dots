import os

from .dsp import SR, band, fade, hits, norm, read

CAND = os.path.join(os.environ.get("GLASSHOUSE_PACK") or os.path.expanduser("~/.local/share/glasshouse"), "foley", "vitrail", "cand")


def take(stem, k):
    return band(read(os.path.join(CAND, f"{stem}-{k}.wav")), 35, None, 2)


def bank(stem, k, gap=0.035, db=-26, length=0.25):
    return [norm(h, -20, 0.02) for h in hits(take(stem, k), gap, db, length) if len(h) > 480]


def cards(stem, keep=0.035):
    return [fade(norm(h[:int(keep * SR)], -20, 0.005), 0.0005, 0.012) for k in range(3) for h in hits(take(stem, k), 0.03, -30, 0.12) if len(h) > 0.02 * SR]
