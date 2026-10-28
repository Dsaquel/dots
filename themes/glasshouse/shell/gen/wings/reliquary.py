import math

import cairo
import numpy as np

from kit import TAU, bevel, leaf, rounded, star4, straight_rgba

from .design import Design
from .draw import beads, bez, eo, fleur, knob, lozenge, oval, scroll, spiral, stroke
from .gems import cabochon, facets
from .raster import K, ctx, grain, lift, rgb, shade, soft
from .specs import RELIQUARY


class Reliquary(Design):
    world = "dark"
    SPRING, FOOT, FBOT = 347.0, 1013.0, 940.5
    ARCH_CUT = 288.0
    RAILS = (940.5, 955.0, 1002.5, 1013.0)
    COL = dict(tip=138.0, cap=(190.0, 200.0), shaft=(200.0, 272.0), collar=(272.0, 292.0))
    ROD = ((476.0, 481.0), (655.0, 666.0))
    PIL = (430.0, 707.5, (482.5, 571.0, 654.0))
    MEDAL = (40.0, 31.8, 26.1)

    def __init__(self, side):
        super().__init__(side)
        self.s = RELIQUARY[side]
        self.xa, self.xb = sorted((self.s["xo"], self.s["xi"]))
        self.fa, self.fb = sorted((self.s["fo"], self.s["fi"]))

    def top(self, x, rx, ry):
        t = (x - self.s["ax"]) / rx
        return self.SPRING - ry * math.sqrt(max(0.0, 1 - t * t))

    def arched(self, c, x0, x1, rx, ry, bottom, n=200):
        c.new_sub_path()
        c.move_to(x0, bottom)
        for i in range(n + 1):
            x = x0 + (x1 - x0) * i / n
            c.line_to(x, min(self.top(x, rx, ry), bottom))
        c.line_to(x1, bottom)
        c.close_path()

    def field(self, c, g=0.0, bottom=None):
        frx, fry = self.s["field"]
        self.arched(c, self.fa - g, self.fb + g, frx + g, fry + g, (self.FBOT if bottom is None else bottom) + max(0.0, g))

    def outer(self, c, g=0.0, bottom=None):
        arx, ary = self.s["arch"]
        self.arched(c, self.xa + g, self.xb - g, arx - g, ary - g, self.FOOT if bottom is None else bottom)

    def field_pts(self, g, step, top_only=False):
        frx, fry = self.s["field"]
        ax = self.s["ax"]
        pts = []
        n = int((frx + g) * math.pi / step)
        for i in range(n + 1):
            a = math.pi - math.pi * i / n
            pts.append((ax + (frx + g) * math.cos(a), self.SPRING - (fry + g) * math.sin(a)))
        if not top_only:
            for y in np.arange(self.SPRING + step, self.FBOT - 2, step):
                pts += [(self.fa - g, y), (self.fb + g, y)]
        return pts

    def centre_line(self, f):
        frx, fry = self.s["field"]
        arx, ary = self.s["arch"]
        ri = (frx + 22, fry + 22)
        ro = (arx - 5, ary - 5)
        return ri[0] + (ro[0] - ri[0]) * f, ri[1] + (ro[1] - ri[1]) * f

    def band_pt(self, phi, f):
        rx, ry = self.centre_line(f)
        return self.s["ax"] + rx * math.cos(phi), self.SPRING - ry * math.sin(phi)

    def phi_of(self, x, y):
        rx, ry = self.centre_line(0.5)
        return math.atan2((self.SPRING - y) / ry, (x - self.s["ax"]) / rx)

    def columns(self):
        return [(cx, tx) for cx, tx in self.s["cols"]]

    def col_body(self, c):
        C = self.COL
        for cx, tx in self.columns():
            c.rectangle(cx - 16, C["cap"][0], 32, C["cap"][1] - C["cap"][0])
            c.rectangle(cx - 10, C["shaft"][0], 20, C["shaft"][1] - C["shaft"][0])
            rounded(c, cx - 20, C["collar"][0], cx + 20, C["collar"][1], 3)

    def rod_body(self, c):
        cx, foot = self.s["rod"]
        c.rectangle(cx - 6.75, 466, 13.5, 667 - 466)
        for y0, y1 in self.ROD:
            x0, x1 = (cx - 10, self.s["chan"][0][0] + 10.5) if self.left else (self.s["chan"][0][0] - 10.5, cx + 10)
            rounded(c, x0, y0, x1, y1, 1.5)

    def pil_body(self, c):
        cx, hw = self.s["pil"]
        tip, foot, ks = self.PIL
        c.rectangle(cx - hw, tip + 30, 2 * hw, foot - tip - 60)

    def bars(self, c):
        b0, b1 = self.s["bars"]
        cx = self.s["pil"][0]
        for y in self.PIL[2]:
            c.move_to(b0, y)
            c.line_to(b0 + 7, y - 4.5)
            c.line_to(b1 - 7, y - 4.5)
            c.line_to(b1, y)
            c.line_to(b1 - 7, y + 4.5)
            c.line_to(b0 + 7, y + 4.5)
            c.close_path()
            lozenge(c, cx, y, 7, 9)

    def blocks(self, c):
        for x0, x1 in self.s["blocks"]:
            rounded(c, x0 + 5, 940, x1 - 5, 1010, 4)
            rounded(c, x0 + 1, 1008, x1 - 1, 1018, 3)
            rounded(c, x0 + 3, 932, x1 - 3, 942, 3)

    def plinth_rails(self, c):
        R = self.RAILS
        x0, x1 = self.s["plinth"]
        c.rectangle(x0 + 6, R[0], x1 - x0 - 12, R[1] - R[0])
        c.rectangle(x0 + 6, R[2], x1 - x0 - 12, R[3] - R[2])

    def colours(self):
        L = self.look
        sp = self.s
        s, c = ctx(self.box)
        c.new_path()
        self.outer(c)
        self.col_body(c)
        self.rod_body(c)
        self.pil_body(c)
        self.blocks(c)
        x0, x1 = sp["plinth"]
        c.rectangle(x0 + 4, self.RAILS[0], x1 - x0 - 8, self.RAILS[3] - self.RAILS[0])
        c.set_source_rgba(*L["backing"], 1)
        c.fill()
        c.save()
        c.new_path()
        c.set_fill_rule(cairo.FILL_RULE_EVEN_ODD)
        self.outer(c, 4.0, self.FBOT)
        self.field(c)
        c.clip()
        c.set_fill_rule(cairo.FILL_RULE_WINDING)
        c.set_source_rgba(*L["enamel"], 1)
        c.paint()
        rng = np.random.default_rng(5 if self.left else 6)
        for _ in range(900):
            x, y = rng.uniform(self.xa, self.xb), rng.uniform(90, 960)
            c.set_source_rgba(*L["enamel_b"], rng.uniform(0.1, 0.45))
            oval(c, x, y, rng.uniform(3, 11), rng.uniform(2, 6), rng.uniform(0, math.pi))
            c.fill()
        g = cairo.LinearGradient(0, 120, 0, 900)
        g.add_color_stop_rgba(0, 1, 1, 1, 0.08)
        g.add_color_stop_rgba(1, 0, 0, 0, 0.25)
        c.set_source(g)
        c.paint()
        c.restore()
        for cx, h in sp["chan"]:
            c.rectangle(cx - h, self.ARCH_CUT, 2 * h, self.FBOT - self.ARCH_CUT)
            c.set_source_rgba(*L["channel"], 1)
            c.fill()
        p0, p1 = sp["panel"]
        c.rectangle(p0, self.RAILS[1], p1 - p0, self.RAILS[2] - self.RAILS[1])
        g = cairo.LinearGradient(0, self.RAILS[1], 0, self.RAILS[2])
        g.add_color_stop_rgba(0, *lift(L["panel"], 0.12), 1)
        g.add_color_stop_rgba(1, *[v * 0.7 for v in L["panel"]], 1)
        c.set_source(g)
        c.fill()
        c.save()
        c.new_path()
        self.field(c)
        c.clip()
        g = cairo.LinearGradient(0, 200, 0, self.FBOT)
        g.add_color_stop_rgba(0, *[min(1, v * 1.2) for v in L["top"]], 1)
        g.add_color_stop_rgba(0.35, *L["top"], 1)
        g.add_color_stop_rgba(1, *L["low"], 1)
        c.set_source(g)
        c.paint()
        c.set_source_rgba(*L["diaper"], L["diaper_a"])
        c.set_line_width(0.7)
        ax = sp["ax"]
        step = 42.0
        for k in range(-30, 31):
            c.move_to(ax + k * step - 1200 * 0.62, -60)
            c.line_to(ax + k * step + 1200 * 0.62, 1140)
            c.move_to(ax + k * step + 1200 * 0.62, -60)
            c.line_to(ax + k * step - 1200 * 0.62, 1140)
        c.stroke()
        for m in range(-2, 50):
            for n in range(-8, 9):
                star4(c, ax + n * step / 2, 190 + m * step * 0.5 + (step * 0.31 if n % 2 else 0), 2.2, 0.2)
        c.set_source_rgba(*L["diaper"], L["diaper_a"] * 1.3)
        c.fill()
        c.restore()
        arr = straight_rgba(s)
        body = self.area(lambda c: (self.field(c), c.fill()))
        grain(arr, body, 33 if self.left else 34, 0.06)
        shade(arr, body, self.area(lambda c: (eo(c, lambda c: self.outer(c, -12.0), lambda c: self.field(c, -6.0)))), 0.4, -self.o)
        return arr

    def crest(self, c):
        mx, my = self.s["medal"]
        fx = self.s["crest"]
        fleur(c, fx, 77.0, 57.0)
        c.rectangle(fx - 2.8, 93, 5.6, 16)
        knob(c, fx, 98.5, 4.2)
        c.rectangle(fx - 8, 104, 16, 4)
        for sx in (-1, 1):
            scroll(c, (fx + sx * 4, 104), (fx + sx * 9, 96), (fx + sx * 16, 93), (fx + sx * 20, 98), 3.2, 2.2, sx * 3.2, 0.9)
            a = math.radians(38)
            p0 = (mx + sx * 40 * math.sin(a), my - 40 * math.cos(a))
            scroll(c, p0, (mx + sx * 30, 104), (mx + sx * 46, 92), (mx + sx * 57, 106), 6.0, 4.6, sx * 9.5, 1.0)
            leaf(c, mx + sx * 19, 107, math.atan2(86 - 107, sx * 20), 27, 4.2, sx * 0.12)
            c.new_sub_path()
            a = math.radians(82)
            p0 = (mx + sx * 40 * math.sin(a), my - 40 * math.cos(a))
            scroll(c, p0, (mx + sx * 66, my - 10), (mx + sx * 92, my - 22), (mx + sx * 110, my - 14), 5.4, 3.2, sx * 5.4, 1.0)
            scroll(c, (mx + sx * 66, my - 8), (mx + sx * 66, my - 20), (mx + sx * 72, my - 30), (mx + sx * 80, my - 27), 3.0, 2.0, sx * 3.0, 0.9)
            scroll(c, (mx + sx * 92, my - 18), (mx + sx * 96, my - 30), (mx + sx * 104, my - 36), (mx + sx * 110, my - 31), 2.8, 1.8, sx * 2.8, 0.9)
            leaf(c, mx + sx * 52, my - 6, -math.pi / 2 - sx * 0.35, 16, 3.2, sx * 0.3)
            c.new_sub_path()
            leaf(c, mx + sx * 84, my - 17, -math.pi / 2 - sx * 0.55, 13, 2.8, sx * 0.3)
            c.new_sub_path()

    def drop(self, c):
        dx, dy = self.s["drop"]
        lozenge(c, dx, 190, 4.6, 7)
        c.new_sub_path()
        lozenge(c, dx, 241.5, 4.0, 6.5)
        c.new_sub_path()
        knob(c, dx, 234.0, 2.6)
        for sx in (-1, 1):
            scroll(c, (dx + sx * 13, 207), (dx + sx * 22, 198), (dx + sx * 34, 199), (dx + sx * 38, 208), 3.6, 2.4, sx * 3.6, 0.9)
            scroll(c, (dx + sx * 12, 224), (dx + sx * 22, 226), (dx + sx * 30, 220), (dx + sx * 31, 214), 2.8, 1.8, -sx * 2.6, 0.9)
            leaf(c, dx + sx * 5, 196, -math.pi / 2 + sx * 0.9, 12, 3.0, -sx * 0.2)
            c.new_sub_path()

    def col_orn(self, c):
        for cx, tx in self.columns():
            fleur(c, tx, 165.0, 54.0)
            knob(c, tx, 186.5, 3.6)
            for y in (204.0, 228.0, 266.0):
                c.rectangle(cx - 11, y - 1.6, 22, 3.2)
            for y in (277.0, 287.0):
                c.rectangle(cx - 21, y - 1.4, 42, 2.8)
            lozenge(c, cx, 247, 4.5, 11)
            c.new_sub_path()
        for x0, x1 in self.s["blocks"]:
            bx = (x0 + x1) / 2
            for sx in (-1, 1):
                scroll(c, (bx + sx * 15, 950), (bx + sx * 24, 958), (bx + sx * 25, 972), (bx + sx * 21, 984), 3.0, 2.0, -sx * 3.0, 0.9)
                scroll(c, (bx + sx * 15, 1000), (bx + sx * 24, 992), (bx + sx * 25, 986), (bx + sx * 22, 982), 2.6, 1.8, sx * 2.6, 0.9)
            lozenge(c, bx, 940, 5, 7)
            c.new_sub_path()
            face = x0 if abs(x0 - self.s["ax"]) > abs(x1 - self.s["ax"]) else x1
            d = 1 if face > self.s["ax"] else -1
            scroll(c, (face - d * 5, 938), (face + d * 4, 924), (face + d * 6, 902), (face + d * 1, 886), 4.0, 2.4, -d * 3.6, 0.9)
        cx, foot = self.s["rod"]
        knob(c, cx, 461, 7.6)
        c.rectangle(cx - 5.5, 468, 11, 3)
        lozenge(c, cx, foot - 6, 4.5, 8)
        c.new_sub_path()
        c.rectangle(cx - 6, 666, 12, 4)
        px, hw = self.s["pil"]
        tip, foot, ks = self.PIL
        fleur(c, px, tip + 20, 40)
        fleur(c, px, foot - 20, 40, math.pi)
        c.rectangle(px - hw - 2, tip + 30, 2 * hw + 4, 4)
        c.rectangle(px - hw - 2, foot - 34, 2 * hw + 4, 4)

    def stones(self, grow=0.0):
        return self.area(lambda c: ([oval(c, j["cx"], j["cy"], j["rx"] + grow, j["ry"] + grow, math.radians(j["rot"])) for j in self.slots()], c.fill()))

    def claw(self, j, a):
        u = a * math.pi
        x, y = (j["rx"] + 1.2) * math.cos(u), (j["ry"] + 1.2) * math.sin(u)
        r = math.radians(j["rot"])
        return j["cx"] + x * math.cos(r) - y * math.sin(r), j["cy"] + x * math.sin(r) + y * math.cos(r)

    def wires(self, c):
        mx, my = self.s["medal"]
        arch = [j for j in self.slots() if j["group"] == "arch"]
        lo = self.phi_of(self.xa + 46, 262)
        hi = self.phi_of(self.xb - 46, 262)
        med = [p for p in np.linspace(hi, lo, 400) if math.hypot(self.band_pt(p, 0.5)[0] - mx, self.band_pt(p, 0.5)[1] - my) < 46]
        stops = sorted([lo, hi, min(med), max(med)] + [self.phi_of(j["cx"], j["cy"]) for j in arch])
        segs = [(a, b) for a, b in zip(stops, stops[1:]) if not (min(med) - 1e-6 <= a and b <= max(med) + 1e-6)]
        for a, b in segs:
            pad = 0.035
            a, b = a + pad, b - pad
            if b <= a:
                continue
            for sign in (1, -1):
                pts = [self.band_pt(a + (b - a) * t, 0.5 + sign * 0.3 * math.sin(math.pi * t)) for t in np.linspace(0, 1, 40)]
                c.move_to(*pts[0])
                for p in pts[1:]:
                    c.line_to(*p)
            for f, sgn in ((0.33, 1), (0.67, -1)):
                x, y = self.band_pt(a + (b - a) * f, 0.5 + sgn * 0.24)
                for q in spiral(x, y, 4.2, 0.8, 0, sgn * TAU * 1.1, 24):
                    c.line_to(*q)
                c.new_sub_path()

    def panel_orn(self, c):
        p0, p1 = self.s["panel"]
        y0, y1 = self.RAILS[1] + 5, self.RAILS[2] - 5
        ym = (y0 + y1) / 2
        cx = self.s["cart"]
        for j in self.slots():
            if j["group"] != "plinth" or not (p0 < j["cx"] < p1) or abs(j["cx"] - cx) < 30:
                continue
            x = j["cx"]
            for sx in (-1, 1):
                for sy in (-1, 1):
                    p = bez((x + sx * 16, ym + sy * 3), (x + sx * 30, ym + sy * 20), (x + sx * 52, ym + sy * 18), (x + sx * 66, ym), 30)
                    c.move_to(*p[0])
                    for q in p[1:]:
                        c.line_to(*q)
                    for q in spiral(x + sx * 34, ym + sy * 9, 5.0, 0.8, math.pi / 2 * sy, math.pi / 2 * sy - sx * sy * TAU * 1.1, 24):
                        c.line_to(*q)
                    c.new_sub_path()
        for sx_, (a, b) in ((1, (p0, p0 + 46)), (-1, (p1 - 46, p1))):
            c.move_to(a + 4, y0)
            c.line_to(b - 4, y1)
            c.move_to(a + 4, y1)
            c.line_to(b - 4, y0)
            c.new_sub_path()

    def cartouche(self, c):
        cx = self.s["cart"]
        j = [j for j in self.slots() if j["group"] == "plinth" and abs(j["cx"] - cx) < 10][0]
        oval(c, j["cx"], j["cy"], j["rx"] + 8.5, j["ry"] + 8.5)
        oval(c, j["cx"], j["cy"], j["rx"] + 4.5, j["ry"] + 4.5)
        c.set_fill_rule(cairo.FILL_RULE_EVEN_ODD)
        c.fill()
        c.set_fill_rule(cairo.FILL_RULE_WINDING)
        fleur(c, cx, 937, 26)
        lozenge(c, cx, 1012, 5, 10)
        c.new_sub_path()
        for sx in (-1, 1):
            scroll(c, (cx + sx * 22, 952), (cx + sx * 36, 948), (cx + sx * 42, 962), (cx + sx * 34, 972), 3.6, 2.4, sx * 3.4, 0.9)
            scroll(c, (cx + sx * 22, 997), (cx + sx * 36, 1001), (cx + sx * 42, 988), (cx + sx * 34, 978), 3.6, 2.4, -sx * 3.4, 0.9)
        for sx in (-1, 1):
            leaf(c, cx + sx * 6, 949, -math.pi / 2 + sx * 1.2, 13, 3.0, -sx * 0.2)
            c.new_sub_path()

    def brackets(self, c):
        for fx, d in ((self.fa, 1), (self.fb, -1)):
            x0 = fx + d * 9
            scroll(c, (x0, 939), (x0 + d * 16, 930), (x0 + d * 30, 922), (x0 + d * 46, 930), 3.4, 2.0, -d * 4.0, 1.0)
            leaf(c, x0 + d * 18, 935, -math.pi / 2 + d * 0.8, 13, 3.0, d * 0.2)
            c.new_sub_path()

    def lead(self):
        sp = self.s
        wx, wy = self.coords()
        top = (wy < self.ARCH_CUT).astype(np.float32)
        mould = self.area(lambda c: eo(c, lambda c: self.outer(c, 0.0, self.FBOT + 2), lambda c: self.outer(c, 5.0, self.FBOT + 2)))
        rim = self.area(lambda c: eo(c, lambda c: self.field(c, 6.0), lambda c: self.field(c)))
        bm = self.area(lambda c: eo(c, lambda c: self.field(c, 22.0), lambda c: self.field(c, 13.0))) * top
        rails = self.area(lambda c: ([(c.rectangle(cx - h - 2.0, self.ARCH_CUT - 4, 2.0, self.FBOT - self.ARCH_CUT + 4), c.rectangle(cx + h, self.ARCH_CUT - 4, 2.0, self.FBOT - self.ARCH_CUT + 4))
                                      for cx, h in sp["chan"]], c.fill()))
        cols = self.area(lambda c: (self.col_body(c), c.fill()))
        rod = self.area(lambda c: (self.rod_body(c), c.fill()))
        pil = self.area(lambda c: (self.pil_body(c), c.fill()))
        bars = self.area(lambda c: (self.bars(c), c.fill()))
        pr = self.area(lambda c: (self.plinth_rails(c), c.fill()))
        blk = self.area(lambda c: (self.blocks(c), c.fill()))
        rcx = sp["rod"][0]
        rod_h = np.sqrt(np.clip(1 - ((wx - rcx) / 6.75) ** 2, 0, 1)) * rod
        pcx, phw = sp["pil"]
        pil_h = np.sqrt(np.clip(1 - ((wx - pcx) / phw) ** 2, 0, 1)) * pil
        groove = self.area(lambda c: ([c.rectangle(sp["plinth"][0] + 6, y, sp["plinth"][1] - sp["plinth"][0] - 12, 1.4) for y in (947.0, 1007.0)], c.fill()))
        hs = np.maximum.reduce([bevel(mould, 2.4 * K), bevel(rim, 2.4 * K), bevel(bm, 2.4 * K, "smooth"), bevel(rails, 0.8 * K),
                                bevel(cols, 2.6 * K), rod_h * 0.95, pil_h * 0.98, bevel(bars, 2.0 * K),
                                bevel(pr, 2.6 * K) - soft(groove, 1.2 * K) * 0.4, bevel(blk, 3.0 * K)])
        cover = np.maximum.reduce([mould, rim, bm, rails, cols, rod, pil, bars, pr, blk])
        holes = np.maximum(self.stones(1.0), self.area(lambda c: (c.arc(*sp["medal"], self.MEDAL[0] - 1.0, 0, TAU), c.fill())))
        return np.clip(hs, 0, 1) * (1 - holes), cover * (1 - holes)

    def gilt(self):
        sp = self.s
        slots = self.slots()
        crest = self.area(lambda c: (self.crest(c), c.fill()))
        drop = self.area(lambda c: (self.drop(c), c.fill()))
        orn = self.area(lambda c: (self.col_orn(c), c.fill()))
        knobs = self.area(lambda c: ([lozenge(c, sp["pil"][0], y, 6, 8) for y in self.PIL[2]], c.fill()))
        enamel = self.area(lambda c: eo(c, lambda c: self.outer(c, 5.0, self.ARCH_CUT), lambda c: self.field(c, 22.0)))
        wire = self.area(lambda c: (self.wires(c), stroke(c, 1.1))) * enamel
        bezel = self.area(lambda c: [eo(c, lambda c, j=j: oval(c, j["cx"], j["cy"], j["rx"] + 2.2, j["ry"] + 2.2, math.radians(j["rot"])),
                                        lambda c, j=j: oval(c, j["cx"], j["cy"], j["rx"] - 0.3, j["ry"] - 0.3, math.radians(j["rot"]))) for j in slots])
        claws = self.area(lambda c: ([knob(c, *self.claw(j, a), 1.7 if j["r"] > 12 else 1.3) for j in slots if j["r"] > 7 for a in (0.25, 0.75, 1.25, 1.75)], c.fill()))
        side = sorted([j for j in slots if j["group"] == "side"], key=lambda j: (j["cx"], j["cy"]))
        boss_pts = []
        for cx, h in sp["chan"]:
            col = sorted([j for j in side if abs(j["cx"] - cx) < 6], key=lambda j: j["cy"])
            for a, b in zip(col, col[1:]):
                gap = (b["cy"] - b["ry"]) - (a["cy"] + a["ry"])
                if gap > 7:
                    boss_pts.append((cx, (a["cy"] + a["ry"] + b["cy"] - b["ry"]) / 2))
        boss = self.area(lambda c: beads(c, boss_pts, 2.6))
        frame = self.area(lambda c: (c.rectangle(sp["panel"][0], self.RAILS[1], sp["panel"][1] - sp["panel"][0], self.RAILS[2] - self.RAILS[1]), stroke(c, 1.6)))
        scrolls = self.area(lambda c: (self.panel_orn(c), stroke(c, 1.3)))
        stars = self.area(lambda c: ([star4(c, x, 976.7, 8.5, 0.24) or c.new_sub_path() for x in sp["stars"]], c.fill()))
        cart = self.area(lambda c: (self.cartouche(c), self.brackets(c), c.fill()))
        bp = self.field_pts(9.0, 3.4) + [(x, y) for x, y in self.field_pts(17.5, 3.6, True) if y < self.ARCH_CUT]
        bp += [(x, 947.8) for x in np.arange(sp["plinth"][0] + 10, sp["plinth"][1] - 10, 3.4)]
        bd = self.area(lambda c: beads(c, bp, 1.2))
        inside = self.stones(-0.3)
        hb = np.maximum.reduce([bevel(crest, 1.8 * K), bevel(drop, 1.5 * K), bevel(orn, 1.6 * K), bevel(knobs, 1.6 * K), bevel(wire, 0.6 * K) * 0.85,
                                bevel(bezel, 1.0 * K), bevel(claws, 0.9 * K), bevel(boss, 1.2 * K), bevel(frame, 0.7 * K) * 0.85,
                                bevel(scrolls, 0.6 * K) * 0.85, bevel(stars, 1.2 * K), bevel(cart, 1.4 * K), bevel(bd, 1.1 * K)])
        cover = np.maximum.reduce([crest, drop, orn, knobs, wire, bezel, claws, boss, frame, scrolls, stars, cart, bd])
        medal = self.area(lambda c: (c.arc(*sp["medal"], self.MEDAL[0] - 1.0, 0, TAU), c.fill()))
        keep = 1 - inside * (1 - np.maximum(bezel, claws))
        return np.clip(hb, 0, 1) * keep * (1 - medal), cover * keep * (1 - medal)

    def jewels(self):
        sp = self.s
        mx, my = sp["medal"]
        ax = sp["ax"]
        out_ = []
        for n, (cx, cy, rx, ry, rot, hx, kind) in enumerate(sp["jewels"]):
            if n == 0:
                group = "crest"
            elif n < 5:
                group = "arch"
            elif n < 7:
                group = "column"
            elif n < 41:
                group = "side"
            else:
                group = "plinth"
            out_.append(dict(cx=cx, cy=cy, rx=rx, ry=ry, rot=rot, colour=rgb(hx), kind=kind, group=group, pearl=kind == "p"))
        for j in out_:
            j["d"] = abs(j["cx"] - ax) * 0.9 + max(0.0, j["cy"] - my)
        corner = max(j["d"] for j in out_ if j["group"] == "side")
        half = max(abs(j["cx"] - ax) for j in out_ if j["group"] == "plinth")
        for j in out_:
            if j["group"] == "plinth":
                j["d"] = corner + 40 + (half - abs(j["cx"] - ax)) * 0.9
        far = max(j["d"] for j in out_)
        for j in out_:
            j["d"] += 0.02 * far
        return out_

    def light_art(self, c, j, n):
        col = lift(j["colour"], 0.3) if j["kind"] == "p" else tuple(v * 0.82 / max(j["colour"]) for v in j["colour"])
        if j["kind"] == "f":
            facets(c, j["shape"], col, j["cx"], j["cy"], j["r"] * 0.9, 70 + n)
        else:
            cabochon(c, j["cx"], j["cy"], j["rx"], j["ry"], math.radians(j["rot"]), col, j["pearl"])

    def spots(self):
        pts = [(tx, 150.0) for cx, tx in self.columns()]
        pts.append((self.s["crest"], 66.0))
        pts.append((self.s["pil"][0], 446.0))
        return pts
