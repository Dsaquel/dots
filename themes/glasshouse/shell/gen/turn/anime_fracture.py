import json, math, os
import numpy as np
import cairo

W, H = 1920, 1080
CX, CY = 960.0, 580.0
MAXR = 1180.0
TOPA = -math.pi / 2
STEP = math.pi / 48
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "turn")
TMP = (os.environ.get("GH_TURN_TMP") or f"{os.environ.get('XDG_RUNTIME_DIR') or '/tmp'}/glasshouse-gen-turn-{os.getuid()}") + "/"
rng = np.random.default_rng(7)

def polar(r, a): return (CX + r * math.cos(a), CY + r * math.sin(a))

def area(poly):
    return sum(poly[i][0] * poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * poly[i][1] for i in range(len(poly))) / 2

def centroid(poly):
    a = area(poly)
    if abs(a) < 1e-9:
        return (sum(p[0] for p in poly) / len(poly), sum(p[1] for p in poly) / len(poly))
    cx = cy = 0.0
    for i in range(len(poly)):
        x1, y1 = poly[i]; x2, y2 = poly[(i + 1) % len(poly)]
        f = x1 * y2 - x2 * y1
        cx += (x1 + x2) * f; cy += (y1 + y2) * f
    return (cx / (6 * a), cy / (6 * a))

def clip_half(poly, nx, ny, c):
    out = []
    for i in range(len(poly)):
        p, q = poly[i], poly[(i + 1) % len(poly)]
        dp, dq = nx * p[0] + ny * p[1] - c, nx * q[0] + ny * q[1] - c
        if dp <= 0: out.append(p)
        if (dp <= 0) != (dq <= 0):
            k = dp / (dp - dq)
            out.append((p[0] + (q[0] - p[0]) * k, p[1] + (q[1] - p[1]) * k))
    return out

def clip_screen(poly):
    for nx, ny, c in ((-1, 0, 0), (1, 0, W), (0, -1, 0), (0, 1, H)):
        poly = clip_half(poly, nx, ny, c)
        if len(poly) < 3: return []
    return poly

def arc(r, a0, a1):
    n = max(1, round(abs(a1 - a0) / STEP))
    return [polar(r, a0 + (a1 - a0) * i / n) for i in range(n + 1)]

shards = []
lead, cracks = [], []

for i in range(6):
    a0 = TOPA + i * math.pi / 3
    shards.append(([(CX, CY)] + arc(104, a0, a0 + math.pi / 3), 0, 0.05 + i * 0.13))
for i in range(12):
    a0, a1 = TOPA + i * math.pi / 6, TOPA + (i + 1) * math.pi / 6
    am = (a0 + a1) / 2
    pane = rng.uniform()
    shards.append((arc(104, a0, a1) + arc(150, a1, a0), 0, rng.uniform()))
    shards.append((arc(150, a0, am) + arc(412, am, a0), 0, pane))
    shards.append((arc(150, am, a1) + arc(412, a1, am), 0, pane))
    shards.append((arc(412, a0, a1) + arc(446, a1, a0), 0, rng.uniform()))
for i in range(24):
    a0, a1 = TOPA + i * math.pi / 12, TOPA + (i + 1) * math.pi / 12
    shards.append((arc(446, a0, a1) + arc(494, a1, a0), 0, rng.uniform()))
for poly, _, _ in shards:
    lead.append(poly + [poly[0]])

NR = 18
base = [TOPA + (i + 0.5) * 2 * math.pi / NR + rng.uniform(-0.09, 0.09) for i in range(NR)]
rings = [494, 640, 840, 1090, 1450]
pts = [[None] * len(rings) for _ in range(NR)]
for i in range(NR):
    a = base[i]
    for k, r in enumerate(rings):
        if k: a += rng.uniform(-0.05, 0.05)
        rr = r if k == 0 else r * rng.uniform(0.9, 1.1)
        pts[i][k] = (a, rr)
for i in range(NR):
    j = (i + 1) % NR
    for k in range(len(rings) - 1):
        ai0, ri0 = pts[i][k]; aj0, rj0 = pts[j][k]
        ai1, ri1 = pts[i][k + 1]; aj1, rj1 = pts[j][k + 1]
        if aj0 < ai0: aj0 += 2 * math.pi
        if aj1 < ai1: aj1 += 2 * math.pi
        inner = arc(494, ai0, aj0) if k == 0 else [polar(ri0, ai0), polar(rj0, aj0)]
        A, B = inner[0], inner[-1]
        C, D = polar(rj1, aj1), polar(ri1, ai1)
        if (i + k) % 2:
            t1 = inner + [C]
            t2 = [A, C, D]
        else:
            t1 = inner + [D]
            t2 = [B, C, D]
        for t in (t1, t2):
            cc = clip_screen(t)
            if cc and abs(area(cc)) > 0.5: shards.append((cc, 1, 0.0))
        cracks.append([A, D]); cracks.append([D, C])
        cracks.append([A, C] if (i + k) % 2 else [B, D])

def masks():
    st = cairo.ImageSurface(cairo.FORMAT_RGB24, W, H); ct = cairo.Context(st)
    ct.set_source_rgb(1, 1, 1); ct.paint(); ct.set_operator(cairo.OPERATOR_DARKEN); ct.set_line_cap(cairo.LINE_CAP_ROUND)
    sm = cairo.ImageSurface(cairo.FORMAT_RGB24, W, H); cm = cairo.Context(sm)
    cm.set_source_rgb(0, 0, 0); cm.paint(); cm.set_operator(cairo.OPERATOR_LIGHTEN)
    cm.set_line_cap(cairo.LINE_CAP_ROUND); cm.set_line_join(cairo.LINE_JOIN_ROUND)
    for lines, wgt in ((cracks, 0.5), (lead, 1.0)):
        for line in lines:
            seg = []
            for (x1, y1), (x2, y2) in zip(line[:-1], line[1:]):
                n = max(1, int(math.hypot(x2 - x1, y2 - y1) / 6))
                seg += [(x1 + (x2 - x1) * s / n, y1 + (y2 - y1) * s / n) for s in range(n)]
            seg.append(line[-1])
            ct.set_line_width(3.0)
            for (x1, y1), (x2, y2) in zip(seg[:-1], seg[1:]):
                v = min(1.0, math.hypot((x1 + x2) / 2 - CX, (y1 + y2) / 2 - CY) / MAXR * 0.92)
                ct.set_source_rgb(v, v, v); ct.move_to(x1, y1); ct.line_to(x2, y2); ct.stroke()
            cm.set_source_rgb(wgt, wgt, wgt); cm.set_line_width(1.8)
            cm.move_to(*line[0])
            for p in line[1:]: cm.line_to(*p)
            cm.stroke()
    grab = lambda s: np.frombuffer(s.get_data(), np.uint8).reshape(H, s.get_stride() // 4, 4)[:, :W, 2].copy()
    os.makedirs(TMP, exist_ok=True)
    np.save(TMP + "anime-mask.npy", grab(sm)); np.save(TMP + "anime-time.npy", grab(st))
masks()

verts, idx, corners = [], [], []
for poly, kind, pane in shards:
    if area(poly) < 0: poly = poly[::-1]
    cx, cy = centroid(poly)
    ar = abs(area(poly))
    size = math.sqrt(ar) / 100
    grown = []
    for x, y in poly:
        dx, dy = x - cx, y - cy
        L = math.hypot(dx, dy) or 1.0
        grown.append((x + dx / L * 0.6, y + dy / L * 0.6))
    dist = min(1.0, math.hypot(cx - CX, cy - CY) / MAXR)
    seed = float(rng.uniform())
    for i in range(len(grown)):
        (x1, y1), (x2, y2) = grown[i], grown[(i + 1) % len(grown)]
        ex, ey = x2 - x1, y2 - y1
        L = math.hypot(ex, ey)
        if L < 1e-6: continue
        enx, eny = ey / L, ex / L
        for (x, y, b) in ((cx, cy, 1.0), (x2, y2, 0.0), (x1, y1, 0.0)):
            verts.append([round(x - W / 2, 2), round(H / 2 - y, 2), 0, b, 0, 0, round(x / W, 5), round(1 - y / H, 5),
                          round(cx, 2), round(cy, 2), round(seed, 4), round(dist, 4), kind, round(pane, 4),
                          round(enx, 4), round(eny, 4), round(size, 3)])
            idx.append(len(verts) - 1)
    corners += [(x, y) for x, y in poly]
json.dump({"verts": verts, "idx": idx}, open(f"{OUT}/mesh-anime.json", "w"), separators=(",", ":"))
json.dump({"corners": corners}, open(f"{TMP}anime-corners.json", "w"))
print("anime shards", len(shards), "(rose", sum(1 for s in shards if s[1] == 0), ") verts", len(verts), "tris", len(idx) // 3)
