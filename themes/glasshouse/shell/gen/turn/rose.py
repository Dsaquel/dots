import heapq, math, os
import numpy as np
import cairo
from PIL import Image, ImageFilter

S = 1024
C = S / 2
TOP = -math.pi / 2
STEP = math.pi / 6
LOBE = TOP
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "turn")
SYM = "Noto Sans Symbols"
LAT = "Cinzel"
BOLD = cairo.FONT_WEIGHT_BOLD
ZODIAC = "♈♉♊♋♌♍♎♏♐♑♒♓"
OPS = ["CALCINATIO", "CONGELATIO", "FIXATIO", "SOLUTIO", "DIGESTIO", "DISTILLATIO", "SUBLIMATIO", "SEPARATIO",
       "CERATIO", "FERMENTATIO", "MULTIPLICATIO", "PROJECTIO"]
BEAT = {0: 0, 6: 0, 3: 1, 9: 1, 1: 2, 7: 2, 4: 3, 10: 3, 2: 4, 8: 4, 5: 5, 11: 5}
PAL = {"light": ["#e0344f", "#f07f22", "#2f63d8", "#27a36e", "#e2579f", "#f3c63f"],
       "dark": ["#3a5bd9", "#1fb5a8", "#7a45e0", "#4fa6ff", "#b3a9f2", "#2cc4e0"]}
GROUND = {"light": ("#2442b8", 0.62, "#b3203c", 0.62), "dark": ("#27288c", 0.7, "#5b3fc4", 0.62)}

def P(r, a, cx=C, cy=C):
    return (cx + r * math.cos(a), cy + r * math.sin(a))

def grab(s, ch=None):
    s.flush()
    a = np.frombuffer(s.get_data(), np.uint8).reshape(s.get_height(), s.get_stride())
    if ch is None:
        return a[:, :s.get_width()].astype(np.float32) / 255
    return a.reshape(s.get_height(), s.get_stride() // 4, 4)[:, :s.get_width(), ch].astype(np.float32) / 255

def spread(val, have, iters):
    for _ in range(iters):
        nv, nh = val.copy(), have.copy()
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)):
            sv, sh = np.roll(val, (dy, dx), (0, 1)), np.roll(have, (dy, dx), (0, 1))
            take = sh & ~nh
            nv[take] = sv[take]
            nh |= take
        val, have = nv, nh
    return val, have

def geodesic(mask, ang):
    on = mask > 0.35
    H, W = mask.shape
    lab = np.zeros(mask.shape, np.int32)
    n = 0
    for y, x in zip(*np.nonzero(on)):
        if lab[y, x]:
            continue
        n += 1
        st = [(y, x)]
        lab[y, x] = n
        while st:
            cy, cx = st.pop()
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    yy, xx = cy + dy, cx + dx
                    if 0 <= yy < H and 0 <= xx < W and on[yy, xx] and not lab[yy, xx]:
                        lab[yy, xx] = n
                        st.append((yy, xx))
    ca, sa = math.cos(-ang), math.sin(-ang)
    comps = []
    for k in range(1, n + 1):
        ys, xs = np.nonzero(lab == k)
        ux = (xs - W / 2) * ca - (ys - H / 2) * sa
        uy = (xs - W / 2) * sa + (ys - H / 2) * ca
        j = int(np.argmin(ux + uy * 1.4))
        comps.append((float(ux[j] * 0.6 + uy[j]), k, (int(ys[j]), int(xs[j]))))
    comps.sort()
    dist = np.full(mask.shape, np.inf)
    off = 0.0
    for _, k, (sy, sx) in comps:
        d = np.full(mask.shape, np.inf)
        d[sy, sx] = 0.0
        pq = [(0.0, sy, sx)]
        while pq:
            dd, y, x = heapq.heappop(pq)
            if dd > d[y, x]:
                continue
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    yy, xx = y + dy, x + dx
                    if (dy or dx) and 0 <= yy < H and 0 <= xx < W and lab[yy, xx] == k:
                        nd = dd + (1.4142 if dy and dx else 1.0)
                        if nd < d[yy, xx]:
                            d[yy, xx] = nd
                            heapq.heappush(pq, (nd, yy, xx))
        m = np.isfinite(d)
        dist[m] = d[m] + off
        off = float(dist[m].max()) + 5.0
    m = np.isfinite(dist)
    order = np.zeros(mask.shape, np.float32)
    order[m] = 0.02 + 0.98 * dist[m] / max(float(dist[m].max()), 1.0)
    return order, m

class Layer:
    def __init__(self, name):
        self.name = name
        self.cov = cairo.ImageSurface(cairo.FORMAT_ARGB32, S, S)
        self.tim = cairo.ImageSurface(cairo.FORMAT_RGB24, S, S)
        self.cls = cairo.ImageSurface(cairo.FORMAT_RGB24, S, S)
        self.grp = cairo.ImageSurface(cairo.FORMAT_RGB24, S, S)
        self.cc, self.ct, self.cl, self.cg = (cairo.Context(s) for s in (self.cov, self.tim, self.cls, self.grp))
        self.ct.set_source_rgb(1, 1, 1); self.ct.paint(); self.ct.set_operator(cairo.OPERATOR_DARKEN)
        for c in (self.cl, self.cg):
            c.set_source_rgb(0, 0, 0); c.paint(); c.set_operator(cairo.OPERATOR_LIGHTEN)
        for c in (self.cc, self.ct, self.cl, self.cg):
            c.set_line_cap(cairo.LINE_CAP_ROUND); c.set_line_join(cairo.LINE_JOIN_ROUND)
        self.patches = []

    def line(self, pts, t0, t1, w, cls=1.0, grp=0):
        L = [0.0]
        for (x1, y1), (x2, y2) in zip(pts[:-1], pts[1:]):
            L.append(L[-1] + math.hypot(x2 - x1, y2 - y1))
        tot = L[-1] or 1
        for c, width, src in ((self.cc, w, (1, 1, 1)), (self.cl, w + 3, (cls,) * 3), (self.cg, w + 5, (grp / 8,) * 3)):
            c.set_source_rgb(*src); c.set_line_width(width)
            c.move_to(*pts[0])
            for p in pts[1:]:
                c.line_to(*p)
            c.stroke()
        self.ct.set_line_width(w + 4)
        for i in range(len(pts) - 1):
            v = t0 + (t1 - t0) * (L[i] + L[i + 1]) / 2 / tot
            self.ct.set_source_rgb(v, v, v)
            self.ct.move_to(*pts[i]); self.ct.line_to(*pts[i + 1]); self.ct.stroke()

    def arc(self, r, a0, a1, t0, t1, w, cls=1.0, cx=C, cy=C, grp=0):
        n = max(8, int(abs(a1 - a0) * r / 4))
        self.line([P(r, a0 + (a1 - a0) * i / n, cx, cy) for i in range(n + 1)], t0, t1, w, cls, grp)

    def ring2(self, r, t0, t1, w, cls=1.0, start=TOP, cx=C, cy=C, grp=0):
        self.arc(r, start, start + math.pi, t0, t1, w, cls, cx, cy, grp)
        self.arc(r, start, start - math.pi, t0, t1, w, cls, cx, cy, grp)

    def dot(self, x, y, r, t, cls=1.0, grp=0):
        self.arc(r, 0, 2 * math.pi, t, t + 0.004, 2.2, cls, x, y, grp)

    def sign(self, ch, x, y, size, ang, t0, t1, grp, font=SYM, cls=0.8, order="pen"):
        Pz = int(size * 2.2) // 2 * 2
        s = cairo.ImageSurface(cairo.FORMAT_A8, Pz, Pz)
        c = cairo.Context(s)
        c.translate(Pz / 2, Pz / 2); c.rotate(ang)
        c.select_font_face(font, cairo.FONT_SLANT_NORMAL, BOLD)
        c.set_font_size(size)
        e = c.text_extents(ch)
        c.move_to(-e.width / 2 - e.x_bearing, -e.height / 2 - e.y_bearing)
        c.text_path(ch); c.fill()
        m = grab(s)
        if order == "pen":
            o, have = geodesic(m, ang)
        else:
            yy, xx = np.mgrid[0:Pz, 0:Pz]
            u = (xx - Pz / 2) * math.cos(-ang) - (yy - Pz / 2) * math.sin(-ang)
            o = (0.02 + 0.98 * np.clip((u + e.width / 2) / max(e.width, 1), 0, 1)).astype(np.float32)
            have = m > 0.35
        o, have = spread(o, have, 4)
        self.patches.append((int(round(x - Pz / 2)), int(round(y - Pz / 2)), m, t0 + (t1 - t0) * o, have, cls, grp))

    def text_arc(self, text, r, am, size, t0, t1, grp, width_max):
        cx = cairo.Context(cairo.ImageSurface(cairo.FORMAT_A8, 8, 8))
        cx.select_font_face(LAT, cairo.FONT_SLANT_NORMAL, BOLD)
        cx.set_font_size(size)
        adv = [cx.text_extents(ch).x_advance * 1.06 for ch in text]
        tot = sum(adv)
        if tot > width_max:
            size *= width_max / tot
            adv = [a * width_max / tot for a in adv]
            tot = width_max
        a = am - tot / 2 / r
        run = 0.0
        for ch, w in zip(text, adv):
            ac = a + (run + w / 2) / r
            u0, u1 = run / tot, (run + w) / tot
            x, y = P(r, ac)
            self.sign(ch, x, y, size, ac + math.pi / 2, t0 + (t1 - t0) * u0, t0 + (t1 - t0) * u1, grp, LAT, 0.8, "wipe")
            run += w

    def save(self):
        cov = grab(self.cov, 3)
        tim = grab(self.tim, 2)
        cls = grab(self.cls, 2)
        grp = grab(self.grp, 2)
        lead = cov.copy()
        for x, y, m, o, have, c, g in self.patches:
            h, w = m.shape
            sl = (slice(y, y + h), slice(x, x + w))
            own = have & ((m > 0.35) | (lead[sl] < 0.02))
            cov[sl] = np.maximum(cov[sl], m)
            tim[sl] = np.where(own, o, tim[sl])
            cls[sl] = np.where(own, c, cls[sl])
            grp[sl] = np.where(own, g / 8, grp[sl])
        out = np.stack([cov, tim, cls, grp], -1) * 255
        Image.fromarray(out.round().clip(0, 255).astype(np.uint8), "RGBA").save(f"{OUT}/{self.name}.png")
        g8 = np.round(grp * 8)
        blur = lambda a, r: np.asarray(Image.fromarray((a * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r)), np.float32) / 255
        lead_c = cov * (g8 <= 1)
        sign_c = cov * (g8 >= 2)
        gl = np.clip((blur(lead_c, 3.5) * 0.6 + blur(lead_c, 9) * 0.4) * 3.2, 0, 1)
        gs = np.clip((blur(sign_c, 3.5) * 0.6 + blur(sign_c, 9) * 0.4) * 3.2, 0, 1)
        gg, _ = spread(np.where(g8 >= 2, grp, 0), g8 >= 2, 20)
        glow = np.stack([gl, gs, gg, np.ones_like(gl)], -1) * 255
        Image.fromarray(glow.round().clip(0, 255).astype(np.uint8), "RGBA").save(f"{OUT}/{self.name}-glow.png")
        print("wrote", self.name, "signs", len(self.patches))

def petal_arch(i, r0=150, r1=412, inset=0.0):
    a = TOP + i * STEP
    a0, a1, am = a + STEP * 0.06 + inset, a + STEP * 0.94 - inset, a + STEP / 2
    left = [P(r0 + (r1 - r0) * (s / 20) ** 0.8, a0 + (am - a0) * (s / 20) ** 2.2) for s in range(21)]
    right = [P(r0 + (r1 - r0) * (s / 20) ** 0.8, a1 - (a1 - am) * (s / 20) ** 2.2) for s in range(21)]
    return left, right, a0, a1, am

def rose(world):
    sun = world == "light"
    L = Layer("rose-" + world)
    L.ring2(494, 0.00, 0.22, 6.0)
    L.ring2(486, 0.03, 0.25, 1.5, 0.55, start=math.pi / 2)
    L.ring2(446, 0.08, 0.30, 4.2)
    L.ring2(441, 0.10, 0.31, 1.3, 0.55, start=math.pi / 2)
    L.ring2(412, 0.14, 0.34, 3.0)
    L.ring2(418, 0.15, 0.35, 1.2, 0.55)
    for i in range(24):
        a = TOP + (i + 0.5) * math.pi / 12
        x, y = P(466, a)
        t = 0.18 + 0.008 * i
        L.arc(14, a + math.pi, a + 3 * math.pi, t, t + 0.07, 2.2, 1.0, x, y)
        L.arc(7, a, a + 2 * math.pi, t + 0.04, t + 0.08, 1.2, 0.55, x, y)
        L.dot(x, y, 1.4, t + 0.07)
        bx, by = P(466, a + math.pi / 24)
        L.dot(bx, by, 1.6, t + 0.05, 0.55)
    L.ring2(104, 0.28, 0.44, 4.6)
    L.ring2(96, 0.30, 0.45, 1.4, 0.55, start=math.pi / 2)
    L.ring2(113, 0.26, 0.40, 1.2, 0.55)
    for i in range(72):
        a = TOP + i * math.pi / 36
        t = 0.30 + 0.16 * i / 72
        L.line([P(113, a), P(126 if i % 6 == 0 else 119, a)], t, t + 0.01, 1.6 if i % 6 == 0 else 1.0, 1.0 if i % 6 == 0 else 0.55)
    for j in range(6):
        a = LOBE + j * math.pi / 3
        x, y = P(66, a)
        L.arc(25, a + math.pi, a + 3 * math.pi, 0.46 + 0.02 * j, 0.56 + 0.02 * j, 2.2, 1.0, x, y)
        L.dot(*P(84, a + math.pi / 6), 1.8, 0.58)
    L.ring2(36, 0.60, 0.68, 1.4, 0.55)
    for i in range(12):
        a = TOP + i * STEP
        L.line([P(104, a), P(446, a)], 0.34, 0.50, 3.2)
        left, right, a0, a1, am = petal_arch(i)
        L.line(left, 0.46, 0.66, 3.0)
        L.line(right, 0.46, 0.66, 3.0)
        li, ri, _, _, _ = petal_arch(i, 162, 396, 0.035)
        L.line(li, 0.50, 0.70, 1.2, 0.55)
        L.line(ri, 0.50, 0.70, 1.2, 0.55)
        L.line([P(150, a0), P(132, am), P(150, a1)], 0.44, 0.52, 2.4)
        bx, by = P(196, am)
        L.arc(8, am + math.pi, am + 3 * math.pi, 0.60, 0.66, 1.8, 1.0, bx, by)
        L.dot(bx, by, 1.5, 0.66)
        ex, ey = P(300, am)
        L.arc(30, am + math.pi, am + 3 * math.pi, 0.62, 0.72, 2.6, 1.0, ex, ey)
        for k in range(4):
            aa = am + math.pi / 4 + k * math.pi / 2
            L.arc(12, aa - 1.25, aa + 1.25, 0.70, 0.76, 1.6, 0.55, ex + 32 * math.cos(aa), ey + 32 * math.sin(aa))
        tx, ty = P(368, am)
        for k in range(3):
            aa = am + k * 2 * math.pi / 3
            L.arc(6.5, aa - 1.4, aa + 1.4, 0.72, 0.80, 1.4, 0.55, tx + 6 * math.cos(aa), ty + 6 * math.sin(aa))
        sx, sy = P(429, a)
        for k in range(4):
            aa = a + k * math.pi / 2
            L.line([(sx, sy), (sx + 6 * math.cos(aa), sy + 6 * math.sin(aa))], 0.34, 0.36, 1.6)
    if sun:
        L.ring2(23, 0.00, 0.62, 3.4, 1.0, grp=1)
        L.arc(5, 0, 2 * math.pi, 0.62, 0.74, 3.2, 1.0, grp=1)
        for k in range(8):
            aa = TOP + k * math.pi / 4
            L.line([P(27.5, aa), P(31, aa)], 0.72 + 0.03 * k, 0.76 + 0.03 * k, 2.0, 1.0, grp=1)
    else:
        a0, a1 = math.radians(-130), math.radians(130)
        L.arc(25, a1, a0 + 2 * math.pi, 0.00, 0.55, 3.4, 1.0, grp=1)
        pts = [(C - 9.5 + 20 * math.cos(a0 + (a1 - a0) * i / 30 + math.pi), C + 19 * math.sin(a0 + (a1 - a0) * i / 30 + math.pi)) for i in range(31)]
        L.line(pts, 0.50, 0.95, 2.6, 1.0, grp=1)
    planets = ("☽☿♀♂♃♄" if sun else "☉☿♀♂♃♄")
    for i in range(12):
        am = TOP + (i + 0.5) * STEP
        g = 2 + BEAT[i]
        L.sign(ZODIAC[i], *P(300, am), 38, 0.0, 0.0, 0.62, g)
        L.text_arc(OPS[i], 429.5, am, 16, 0.25, 1.0, g, 192)
    for j in range(6):
        a = LOBE + j * math.pi / 3
        L.sign(planets[j], *P(66, a), 29, 0.0, 0.05, 0.9, 2 + j, "Noto Sans Symbols 2" if planets[j] == "☉" else SYM)
    L.save()

def noise(shape, cells, seed):
    g = np.random.default_rng(seed).uniform(0, 1, (cells[0] + 1, cells[1] + 1)).astype(np.float32)
    return np.asarray(Image.fromarray(g).resize((shape[1], shape[0]), Image.BICUBIC), np.float32)

def glass(world):
    pal = PAL[world]
    gA, kA, gB, kB = GROUND[world]
    col = cairo.ImageSurface(cairo.FORMAT_ARGB32, S, S); cc = cairo.Context(col)
    grp = cairo.ImageSurface(cairo.FORMAT_RGB24, S, S); cg = cairo.Context(grp)
    cg.set_source_rgb(0, 0, 0); cg.paint()
    hexc = lambda h: tuple(int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))

    def fill(path, rgb, g, k=1.0):
        for c, src in ((cc, tuple(v * k for v in rgb) + (1,)), (cg, (g / 8,) * 3 + (1,))):
            c.new_path(); path(c)
            c.set_source_rgba(*src)
            c.fill()

    def poly(pts):
        def f(c):
            c.move_to(*pts[0])
            for p in pts[1:]:
                c.line_to(*p)
            c.close_path()
        return f

    def disc(x, y, r):
        return lambda c: c.arc(x, y, r, 0, 2 * math.pi)

    def sector(r0, r1, a0, a1):
        def f(c):
            if r0 <= 0:
                c.move_to(C, C)
            c.arc(C, C, r1, a0, a1)
            if r0 > 0:
                c.arc_negative(C, C, r0, a1, a0)
            c.close_path()
        return f

    for i in range(12):
        a = TOP + i * STEP
        g = 2 + BEAT[i]
        fill(sector(104, 412, a, a + STEP), hexc(gA), g, kA)
        fill(sector(412, 446, a, a + STEP), hexc(gB), g, kB)
        fill(sector(446, 494, a, a + STEP), hexc(gA), g, kA)
    for j in range(6):
        a = LOBE + (j - 0.5) * math.pi / 3
        fill(sector(0, 104, a, a + math.pi / 3), hexc(gB), 2 + j, kB)
    for i in range(12):
        left, right, _, _, am = petal_arch(i)
        g = 2 + BEAT[i]
        fill(poly(left + right[::-1]), hexc(pal[i % 6]), g)
        fill(disc(*P(300, am), 29), hexc(pal[i % 6]), g, 0.42)
    for j in range(6):
        a = LOBE + j * math.pi / 3
        fill(disc(*P(66, a), 24), hexc(pal[(j + 2) % 6]), 2 + j, 0.4)
    fill(disc(C, C, 22), hexc("#ffd36b" if world == "light" else "#cfe0ff"), 1, 0.9)
    for i in range(24):
        a = TOP + (i + 0.5) * math.pi / 12
        fill(disc(*P(466, a), 12.5), hexc(pal[(i // 2) % 6]), 2 + BEAT[i // 2])
    arr = np.frombuffer(col.get_data(), np.uint8).reshape(S, S, 4).astype(np.float32) / 255
    al = arr[..., 3]
    rgb = np.where(al[..., None] > 0, arr[..., [2, 1, 0]] / np.maximum(al[..., None], 1e-3), 0)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    ang = (np.arctan2(yy - C, xx - C) + math.pi) / (2 * math.pi)
    rad = np.hypot(xx - C, yy - C) / 512
    st = noise((64, 2048), (8, 420), 3)
    streak = st[np.clip((rad * 63).astype(int), 0, 63), np.clip((ang * 2047).astype(int), 0, 2047)]
    mot = noise((S, S), (26, 26), 5) * 0.6 + noise((S, S), (90, 90), 6) * 0.4
    k = 7
    art = np.asarray(Image.open(f"{OUT}/rose-{world}.png"), np.float32) / 255
    lead = art[..., 0] * (np.round(art[..., 3] * 8) <= 1)
    cs = np.pad(lead, k).cumsum(0).cumsum(1)
    box = (cs[2 * k:, 2 * k:] - cs[:-2 * k, 2 * k:] - cs[2 * k:, :-2 * k] + cs[:-2 * k, :-2 * k]) / (2 * k) ** 2
    rim = np.clip(1 - 2.5 * box[:S, :S], 0, 1)
    dens = (0.62 + 0.55 * streak) * (0.8 + 0.4 * mot) * (0.55 + 0.45 * rim ** 2)
    seeds = np.random.default_rng(11).uniform(0, 1, (S, S)) > 0.9985
    dens = dens + seeds * 0.9
    rgb = np.clip(rgb * dens[..., None], 0, 1)
    g8 = grab(grp, 2)
    have = al > 0.02
    g8, _ = spread(g8, have, 4)
    rgb, _ = spread(rgb, al > 0.5, 8)
    out = np.concatenate([rgb * 255, g8[..., None] * 255], -1)
    Image.fromarray(out.round().clip(0, 255).astype(np.uint8), "RGBA").save(f"{OUT}/rosefill-{world}.png")
    Image.fromarray((al * 255).round().astype(np.uint8)).save(f"{OUT}/rosefill-{world}-cov.png")
    print("wrote rosefill", world)

if __name__ == "__main__":
    for w in ("light", "dark"):
        rose(w)
        glass(w)
