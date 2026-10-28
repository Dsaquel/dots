import json, math, sys, os
import numpy as np
mode = sys.argv[1]
rng = np.random.default_rng(3)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "turn")
CX, CY = 960.0, 580.0
msk = np.load((os.environ.get("GH_TURN_TMP") or f"{os.environ.get('XDG_RUNTIME_DIR') or '/tmp'}/glasshouse-gen-turn-{os.getuid()}") + f"/{mode}-mask.npy")
ys, xs = np.nonzero(msk > 100)
V, I = [], []
def quad(sx, sy, seed, grp, t0, life):
    b = len(V)
    for cx, cy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        V.append([cx, cy, round(sx, 1), round(sy, 1), round(seed, 4), grp, round(t0, 4), round(life, 4)])
    I.extend([b, b + 1, b + 2, b, b + 2, b + 3])
for _ in range(700):
    a = rng.uniform(0, 2 * math.pi); r = rng.uniform(520, 980)
    quad(CX + r * math.cos(a), CY + r * math.sin(a), rng.uniform(), 0, rng.uniform(0.5, 2.15), rng.uniform(0.45, 0.75))
for _ in range(900):
    a = rng.uniform(0, 2 * math.pi); r = rng.uniform(0, 40)
    quad(CX + r * math.cos(a), CY + r * math.sin(a), rng.uniform(), 1, rng.uniform(0.0, 0.05), rng.uniform(0.5, 1.4))
for _ in range(1600):
    k = rng.integers(len(xs))
    quad(float(xs[k]), float(ys[k]), rng.uniform(), 2, rng.uniform(0.0, 0.08), rng.uniform(0.9, 1.6))
for _ in range(650):
    quad(rng.uniform(0, 1920), rng.uniform(0, 1080), rng.uniform(), 3, rng.uniform(-520, 260), rng.uniform(0.6, 1.0))
json.dump({"verts": V, "idx": I}, open(f"{OUT}/sparks-{mode}.json", "w"), separators=(",", ":"))
print(mode, "particles", len(V) // 4)
