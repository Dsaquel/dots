import math

import cairo
import numpy as np

from kit import TAU, bevel, leaf, rounded, straight_rgba

from .design import Design
from .draw import beads, crocket, eo, fleur, knob, lancet, lozenge, pointed_arch, ribbon, scroll, stroke
from .gems import cabochon, facets
from .raster import K, ctx, dimples, grain, lift, rgb, shade, soft
from .specs import GABLE


class Gable(Design):
    world = "light"
    APEX = (62.5, 106.4)
    SILL = (294.0, 312.2)
    FBOT = 925.3
    BOT = dict(mould=(923.5, 937.0), fillet=(937.0, 950.0), strip=(957.5, 982.0), rule=(984.5, 986.0), motto=(986.5, 1011.0), base=(1012.0, 1023.0))
    HINGES = (357.0, 587.0, 822.0, 966.0)
    ROSE = (76.0, 72.0, 64.0)
    ARC = ((112.3, 247.0), (75.1, 192.6))
    ARC_Y = 283.7
    GABLET_Y = 262.0

    def __init__(self, side):
        super().__init__(side)
        self.s = GABLE[side]
        self.xa, self.xb = sorted((self.s["xo"], self.s["xi"]))
        self.fa, self.fb = sorted((self.s["fo"], self.s["fi"]))

    def arc_of(self, t):
        return self.ARC[0][0] + (self.ARC[1][0] - self.ARC[0][0]) * t, self.ARC[0][1] + (self.ARC[1][1] - self.ARC[0][1]) * t

    def gable(self, c, t=0.0, bottom=None):
        e, rho = self.arc_of(t)
        pointed_arch(c, self.s["ax"], self.ARC_Y, e, rho, self.SILL[0] if bottom is None else bottom)

    def gable_pts(self, t, step):
        e, rho = self.arc_of(t)
        ax, yc = self.s["ax"], self.ARC_Y
        top = math.atan2(-math.sqrt(rho * rho - e * e), -e) + TAU
        n = max(2, int(rho * (top - math.pi) / step))
        pts = []
        for a in np.linspace(math.pi, top, n):
            x, y = ax + e + rho * math.cos(a), yc + rho * math.sin(a)
            pts += [(x, y), (2 * ax - x, y)]
        for y in np.arange(yc, self.SILL[0], step):
            pts += [(ax + e - rho, y), (ax - e + rho, y)]
        return pts

    def gablet(self, c, g, t=0.0):
        cx, tip, apex, x0, x1 = g
        a = (x1 - x0) / 2
        h = self.GABLET_Y - apex
        e = (h * h - a * a) / (2 * a)
        rho = a + e
        pointed_arch(c, cx, self.GABLET_Y, e, rho - 11.0 * t, self.SILL[0])

    def pinnacle(self, c, p, body=True):
        cx, tip, x0, x1 = p
        hw = (x1 - x0) / 2
        c.new_sub_path()
        c.move_to(cx, tip)
        c.line_to(cx + hw * 0.5, 206)
        c.line_to(cx - hw * 0.5, 206)
        c.close_path()
        if body:
            c.new_sub_path()
            c.move_to(cx - hw * 0.8, 232)
            c.line_to(cx, 196)
            c.line_to(cx + hw * 0.8, 232)
            c.close_path()
            c.rectangle(cx - hw * 0.72, 226, hw * 1.44, 300 - 226)
            c.rectangle(cx - hw * 0.86, 222, hw * 1.72, 8)

    def stile(self, c):
        x0, x1 = (self.fb, self.xb) if self.left else (self.xa, self.fa)
        c.rectangle(x0, 300, x1 - x0, self.BOT["base"][1] - 300)

    def outer_side(self, c):
        sh0, sh1 = self.s["shaft"]
        c.rectangle(sh0, 330, sh1 - sh0, 950 - 330)
        for r0, r1 in self.s["rails"]:
            c.rectangle(r0, 300, r1 - r0, self.BOT["base"][1] - 300)

    def capital(self, c):
        c0, c1 = self.s["cap"]
        b0, b1, bt = self.s["base"]
        rounded(c, c0, 292, c1, 302, 2)
        rounded(c, c0 + 3, 302, c1 - 3, 312, 2)
        c.move_to(c0 + 5, 312)
        c.line_to(c1 - 5, 312)
        c.line_to(c1 - 10, 340)
        c.line_to(c0 + 10, 340)
        c.close_path()
        rounded(c, c0 + 6, 338, c1 - 6, 346, 2)
        rounded(c, b0 + 6, 940, b1 - 6, 950, 2)
        rounded(c, b0 + 2, 950, b1 - 2, 962, 3)
        c.rectangle(b0 + 8, 962, b1 - b0 - 16, 36)
        rounded(c, b0, 996, b1, 1008, 3)
        rounded(c, b0 + 3, 1008, b1 - 3, 1018, 3)
        c.move_to(b0 + 10, 1018)
        c.line_to(b1 - 10, 1018)
        c.line_to(bt, 1033)
        c.close_path()

    def plinth(self, c):
        B = self.BOT
        s0, s1 = self.s["strip"]
        c.rectangle(s0 - 6, B["mould"][0], s1 - s0 + 12, B["fillet"][1] - B["mould"][0])
        c.rectangle(s0 - 6, B["fillet"][1], s1 - s0 + 12, B["strip"][0] - B["fillet"][1])
        c.rectangle(s0 - 6, B["strip"][1], s1 - s0 + 12, B["motto"][0] - B["strip"][1])
        c.rectangle(s0 - 6, B["motto"][1], s1 - s0 + 12, B["base"][1] - B["motto"][1])

    def hinge(self, c, yc, k):
        bx, tip, k0, k1 = self.s["hinge"]
        d = 1 if self.left else -1
        c.rectangle(bx - 6, yc - 38, 12, 78)
        for sy in (-1, 1):
            knob(c, bx, yc + sy * 36, 7.5)
        lozenge(c, bx, yc, 16, 15)
        c.new_sub_path()
        x0 = bx if k == 3 else tip + d * 14
        c.rectangle(min(x0, k1 if self.left else k0), yc - 4.5, abs((k1 if self.left else k0) - x0), 9)
        if k != 3:
            fleur(c, tip + d * 22, yc, 44, -d * math.pi / 2)
        c.rectangle(k0, yc - 11, k1 - k0, 25)

    def colours(self):
        L = self.look
        sp = self.s
        s, c = ctx(self.box)
        c.new_path()
        self.gable(c, 0.0, 300)
        for g in sp["gablets"]:
            self.gablet(c, g)
        for p in sp["pins"]:
            self.pinnacle(c, p)
        c.rectangle(self.xa, 292, self.xb - self.xa, self.BOT["base"][1] - 292)
        c.set_source_rgba(*L["backing"], 1)
        c.fill()
        c.save()
        c.new_path()
        self.gable(c, 1.0)
        for g in sp["gablets"]:
            self.gablet(c, g, 1.0)
        c.clip()
        rx, ry = sp["rose"]
        g = cairo.RadialGradient(rx, ry, 50, rx, ry, 200)
        g.add_color_stop_rgba(0, *L["tympan_b"], 1)
        g.add_color_stop_rgba(1, *L["tympan"], 1)
        c.set_source(g)
        c.paint()
        c.set_source_rgba(1, 0.9, 0.75, 0.08)
        c.set_line_width(0.8)
        for a in np.radians(np.arange(-180, 1, 12)):
            c.move_to(rx, ry)
            c.line_to(rx + 300 * math.cos(a), ry + 300 * math.sin(a))
        c.stroke()
        c.restore()
        c.rectangle(self.fa, self.SILL[1], self.fb - self.fa, self.FBOT - self.SILL[1])
        c.save()
        c.clip()
        g = cairo.LinearGradient(0, self.SILL[1], 0, self.FBOT)
        g.add_color_stop_rgba(0, *lift(L["top"], 0.06), 1)
        g.add_color_stop_rgba(1, *L["low"], 1)
        c.set_source(g)
        c.paint()
        c.set_source_rgba(*L["damask"], L["damask_a"])
        c.set_line_width(0.7)
        step = 34.0
        for k in range(-40, 40):
            x = sp["ax"] + k * step
            c.move_to(x - 700, self.SILL[1] - 700 * 1.25)
            c.line_to(x + 700, self.SILL[1] + 700 * 1.25)
            c.move_to(x + 700, self.SILL[1] - 700 * 1.25)
            c.line_to(x - 700, self.SILL[1] + 700 * 1.25)
        c.stroke()
        c.restore()
        s0, s1 = sp["strip"]
        for y0, y1 in (self.BOT["strip"], self.BOT["motto"]):
            c.rectangle(s0, y0, s1 - s0, y1 - y0)
            c.set_source_rgba(*L["strip"], 1)
            c.fill()
            c.save()
            c.rectangle(s0, y0, s1 - s0, y1 - y0)
            c.clip()
            c.set_source_rgba(*L["trace"], L["trace_a"])
            c.set_line_width(0.7)
            h = y1 - y0
            x = s0 - h
            while x < s1 + h:
                c.move_to(x, y0)
                c.line_to(x + h, y1)
                c.move_to(x + h, y0)
                c.line_to(x, y1)
                x += h
            c.stroke()
            c.restore()
        c.arc(*sp["rose"], self.ROSE[0], 0, TAU)
        c.set_source_rgba(*L["rose"], 1)
        c.fill()
        arr = straight_rgba(s)
        body = self.area(lambda c: (c.rectangle(self.fa, self.SILL[1], self.fb - self.fa, self.FBOT - self.SILL[1]), c.fill()))
        grain(arr, body, 31 if self.left else 32, 0.07)
        shade(arr, body, self.area(lambda c: (c.rectangle(self.xa - 20, 260, self.xb - self.xa + 40, self.SILL[1] - 260 + 4),
                                              c.rectangle(self.fb - 2 if self.left else self.xa - 10, 300, 12 + (self.xb - self.fb if self.left else self.fa - self.xa), 700), c.fill())), 0.45, -self.o)
        return arr

    def lead(self):
        sp = self.s
        wx, wy = self.coords()
        gab = self.area(lambda c: eo(c, lambda c: self.gable(c, 0.0), lambda c: self.gable(c, 1.0)))
        rolls = self.area(lambda c: [(self.gable(c, t), stroke(c, 1.6)) for t in (0.3, 0.62)]) * gab
        hid = self.area(lambda c: (self.gable(c, 0.0, 300), c.fill()))
        glet = self.area(lambda c: [eo(c, lambda c, g=g: self.gablet(c, g), lambda c, g=g: self.gablet(c, g, 1.0)) for g in sp["gablets"]]) * (1 - hid)
        pins = self.area(lambda c: ([self.pinnacle(c, p) for p in sp["pins"]], c.fill()))
        stile = self.area(lambda c: (self.stile(c), c.fill()))
        x0, x1 = (self.fb, self.xb) if self.left else (self.xa, self.fa)
        sgroove = self.area(lambda c: ([c.rectangle(x, 300, 1.4, self.BOT["base"][1] - 300) for x in (x0 + 6, x0 + 11, x1 - 8)], c.fill()))
        side = self.area(lambda c: (self.outer_side(c), c.fill()))
        sh0, sh1 = sp["shaft"]
        cxs, hw = (sh0 + sh1) / 2, (sh1 - sh0) / 2
        tcol = np.clip(1 - ((wx - cxs) / hw) ** 2, 0, 1)
        twist = 0.5 + 0.5 * np.cos(TAU * (wy + (wx - cxs) * 1.6) / 22.0)
        shaft = ((wy > 340) & (wy < 945) & (np.abs(wx - cxs) < hw)).astype(np.float32)
        col_h = np.sqrt(tcol) * (0.55 + 0.45 * twist) * shaft
        cap = self.area(lambda c: (self.capital(c), c.fill()))
        sill = self.area(lambda c: (c.rectangle(self.fa - 14, self.SILL[0], self.fb - self.fa + 28, self.SILL[1] - self.SILL[0]), c.fill()))
        sillg = self.area(lambda c: ([c.rectangle(self.fa - 14, y, self.fb - self.fa + 28, 1.4) for y in (299.0, 305.0)], c.fill()))
        rim = self.area(lambda c: eo(c, lambda c: c.rectangle(self.fa - 5, self.SILL[1] - 2, self.fb - self.fa + 10, self.FBOT - self.SILL[1] + 7),
                                     lambda c: c.rectangle(self.fa, self.SILL[1], self.fb - self.fa, self.FBOT - self.SILL[1])))
        pl = self.area(lambda c: (self.plinth(c), c.fill()))
        plg = self.area(lambda c: ([c.rectangle(sp["strip"][0] - 6, y, sp["strip"][1] - sp["strip"][0] + 12, 1.3) for y in (929.0, 1016.0, 1019.5)], c.fill()))
        mull = self.area(lambda c: ([(j["shape"](c), stroke(c, 2.6)) for j in self.slots() if j["group"] != "rose"]))
        hng = self.area(lambda c: ([self.hinge(c, y, k) for k, y in enumerate(self.HINGES)], c.fill()))
        kn0, kn1 = sp["hinge"][2], sp["hinge"][3]
        kcx = (kn0 + kn1) / 2
        barrel = np.sqrt(np.clip(1 - ((wx - kcx) / ((kn1 - kn0) / 2)) ** 2, 0, 1)) * self.area(lambda c: ([c.rectangle(kn0, y - 11, kn1 - kn0, 25) for y in self.HINGES], c.fill()))
        rr = self.area(lambda c: eo(c, lambda c: c.arc(*sp["rose"], self.ROSE[0], 0, TAU), lambda c: (c.new_sub_path(), c.arc(*sp["rose"], self.ROSE[2], 0, TAU))))
        rrg = self.area(lambda c: (c.arc(*sp["rose"], self.ROSE[1], 0, TAU), stroke(c, 1.4)))
        hs = np.maximum.reduce([bevel(gab, 3.0 * K, "smooth") - rolls * 0.35, bevel(glet, 2.4 * K, "smooth"), bevel(pins, 2.6 * K),
                                bevel(stile, 3.0 * K) - soft(sgroove, 1.0 * K) * 0.35, bevel(side, 2.4 * K), col_h,
                                bevel(cap, 2.0 * K), bevel(sill, 2.6 * K) - soft(sillg, 1.0 * K) * 0.35, bevel(rim, 1.8 * K),
                                bevel(pl, 2.4 * K) - soft(plg, 1.0 * K) * 0.3, bevel(mull, 1.0 * K), (0.4 + 0.6 * bevel(hng, 2.2 * K)) * hng, barrel,
                                bevel(rr, 2.4 * K, "smooth") - soft(rrg, 1.0 * K) * 0.3])
        cover = np.maximum.reduce([gab, glet, pins, stile, side, np.clip(tcol * 6, 0, 1) * shaft, cap, sill, rim, pl, mull, hng, rr])
        holes = np.maximum(self.lights_mask(), self.area(lambda c: (c.arc(*sp["rose"], self.ROSE[2] - 0.5, 0, TAU), c.fill())))
        return np.clip(hs, 0, 1) * (1 - holes), cover * (1 - holes)

    def gcrocket(self, c, x, y):
        ax = self.s["ax"]
        e, rho = self.ARC[0]
        ox, oy = (ax + e, self.ARC_Y) if x < ax else (ax - e, self.ARC_Y)
        d = math.hypot(x - ox, y - oy)
        nx, ny = (x - ox) / d, (y - oy) / d
        fx, fy = ox + nx * (rho - 3), oy + ny * (rho - 3)
        ribbon(c, [(fx, fy), (x - nx * 4, y - ny * 4)], 5.0, 3.6)
        fleur(c, x, y, 17.0, math.atan2(ny, nx) + math.pi / 2)

    def lights_mask(self):
        return self.area(lambda c: ([j["shape"](c) for j in self.slots() if j["group"] != "rose"], c.fill()))

    def gilt(self):
        sp = self.s
        ax = sp["ax"]
        hid = self.area(lambda c: (self.gable(c, 0.0, 300), c.fill()))
        crock = self.area(lambda c: ([self.gcrocket(c, x, y) for x, y in sp["crockets"]], c.fill()))
        top = self.APEX[0]
        fin = self.area(lambda c: (
            c.rectangle(ax - 2.6, top - 18, 5.2, 18),
            fleur(c, ax, 30, 34),
            c.rectangle(ax - 17, 38, 34, 5),
            [knob(c, ax + sx * 18, 40.5, 3.2) for sx in (-1, 1)],
            knob(c, ax, top - 1, 3.6),
            c.fill()))
        gfin = self.area(lambda c: ([(fleur(c, g[0], g[1] + 12, 24), knob(c, g[0], g[2] - 1, 2.6), c.rectangle(g[0] - 1.6, g[1] + 18, 3.2, g[2] - g[1] - 18)) for g in sp["gablets"]], c.fill())) * (1 - hid)
        gcrock = self.area(lambda c: ([crocket(c, g[0] + sx * (g[4] - g[3]) * 0.3, g[2] + 14, -math.pi / 2 + sx * 0.9, 9) for g in sp["gablets"] for sx in (-1, 1)], c.fill())) * (1 - hid)
        pk = []
        for cx, tip, x0, x1 in sp["pins"]:
            hw = (x1 - x0) / 2
            for f in np.linspace(0.25, 1.0, 4 if hw < 23 else 5):
                y = tip + (205 - tip) * f
                w = hw * (0.45 + 0.5 * f)
                pk += [(cx - w, y, -math.pi / 2 - 1.05), (cx + w, y, -math.pi / 2 + 1.05)]
        stalks = [(cx + (1 if x > cx else -1) * hw * 0.3 * ((y - tip) / (206 - tip)), y + 3, x, y, a) for cx, tip, x0, x1 in sp["pins"] for hw in ((x1 - x0) / 2,) for x, y, a in pk if x0 - 4 < x < x1 + 4]
        pcrock = self.area(lambda c: ([(fleur(c, x, y, 10.0, a + math.pi / 2), c.new_sub_path()) for x, y, a in pk], [ribbon(c, [(sx_, sy_), (x, y + 1.5)], 3.2, 2.4) for sx_, sy_, x, y, a in stalks],
                                      [(knob(c, p[0], p[1] + 10, 3.4), lozenge(c, p[0], p[1] + 4, 3.2, 8), c.new_sub_path()) for p in sp["pins"]], c.fill()))
        niche = self.area(lambda c: ([(lancet(c, p[0] - 8, 238, p[0] + 8, 296), stroke(c, 1.4)) for p in sp["pins"]]))
        sx, sy = sp["sprig"]
        d = -1 if sx < ax else 1
        sprig = self.area(lambda c: (scroll(c, (sx + d * 10, 204), (sx + d * 3, 188), (sx - d * 6, 170), (sx + d * 3, 152), 7.5, 4.5, -d * 5.0, 0.9),
                                     leaf(c, sx + d * 6, 196, -math.pi / 2 - d * 0.5, 20, 4.0, -d * 0.2), c.fill()))
        fil = self.area(lambda c: eo(c, lambda c: self.gable(c, 0.84), lambda c: self.gable(c, 1.0))) * (1 - self.area(lambda c: (c.arc(*sp["rose"], self.ROSE[0] + 2, 0, TAU), c.fill())))
        s0, s1 = sp["strip"]
        pf = self.area(lambda c: (c.rectangle(s0, self.BOT["fillet"][0], s1 - s0, self.BOT["fillet"][1] - self.BOT["fillet"][0]), c.fill()))
        rule = self.area(lambda c: (c.rectangle(s0, self.BOT["rule"][0], s1 - s0, self.BOT["rule"][1] - self.BOT["rule"][0]),
                                    [c.rectangle(s0, y - 0.7, s1 - s0, 1.4) for y in (self.BOT["strip"][0], self.BOT["strip"][1], self.BOT["motto"][1])], c.fill()))
        bez_ = self.area(lambda c: ([(j["shape"](c), stroke(c, 1.6)) for j in self.slots() if j["group"] == "strip"]))
        caps = self.area(lambda c: ([leaf(c, (sp["cap"][0] + sp["cap"][1]) / 2 + sx_ * 7, 336, -math.pi / 2 + sx_ * 0.5, 22, 4.5, -sx_ * 0.15) or c.new_sub_path() for sx_ in (-1, 0, 1)], c.fill()))
        dots = [(x, (self.BOT["fillet"][0] + self.BOT["fillet"][1]) / 2 + dy) for x in np.arange(s0 + 3, s1 - 2, 4.4) for dy in ((-3, 3) if int(x) % 2 else (0,))]
        dd = dimples(self.box, dots, 1.0)
        fpts = self.gable_pts(0.92, 3.8)
        sx0, sx1 = (self.fb, self.xb) if self.left else (self.xa, self.fa)
        fpts += [((sx0 + sx1) / 2 + dx, y) for y in np.arange(312, 920, 4.6) if min(abs(y - h) for h in self.HINGES) > 46 for dx in ((-2.2, 2.2) if int(y / 4.6) % 2 else (0.0,))]
        fb = self.area(lambda c: beads(c, [p for p in fpts if math.hypot(p[0] - sp["rose"][0], p[1] - sp["rose"][1]) > self.ROSE[0] + 3], 1.2))
        hb = np.maximum.reduce([bevel(crock, 1.4 * K), bevel(fin, 1.6 * K), bevel(gfin, 1.3 * K), bevel(gcrock, 1.2 * K), bevel(pcrock, 1.2 * K),
                                bevel(niche, 0.7 * K) * 0.85, bevel(sprig, 1.4 * K), bevel(fil, 1.0 * K, "smooth") * 0.9, bevel(pf, 1.2 * K) - dd * 0.5,
                                bevel(rule, 0.7 * K), bevel(bez_, 0.8 * K), bevel(caps, 1.2 * K), bevel(fb, 1.0 * K)])
        cover = np.maximum.reduce([crock, fin, gfin, gcrock, pcrock, niche, sprig, fil, pf, rule, bez_, caps, fb])
        holes = np.maximum(self.lights_mask(), self.area(lambda c: (c.arc(*sp["rose"], self.ROSE[2] - 0.5, 0, TAU), c.fill())))
        return np.clip(hb, 0, 1) * (1 - holes), cover * (1 - holes)

    def jewels(self):
        sp = self.s
        ax = sp["ax"]
        rx_, ry_ = sp["rose"]
        out_ = []
        for kind, a, b, cc, dd, hx in sp["jewels"]:
            col = rgb(hx)
            if kind == "l":
                x0, y0, x1, y1 = a, b, cc, dd
                j = dict(cx=(x0 + x1) / 2, cy=(y0 + y1) / 2, rx=(x1 - x0) / 2, ry=(y1 - y0) / 2, kind="lancet", colour=col, group="top",
                         shape=lambda c, x0=x0, y0=y0, x1=x1, y1=y1: lancet(c, x0, y0, x1, y1))
            elif kind == "p":
                j = dict(cx=a, cy=b, rx=cc, ry=dd, kind="pearl", colour=col, group="rose")
            else:
                j = dict(cx=a, cy=b, rx=cc, ry=dd, kind="diamond", colour=col, group="strip" if b > 900 else "top",
                         shape=lambda c, x=a, y=b, w=cc, h=dd: lozenge(c, x, y, w, h))
            out_.append(j)
        for j in out_:
            j["d"] = math.hypot(j["cx"] - rx_, j["cy"] - ry_)
        reach = max(j["d"] for j in out_ if j["group"] != "strip")
        half = max(abs(j["cx"] - ax) for j in out_ if j["group"] == "strip")
        for j in out_:
            if j["group"] == "strip":
                j["d"] = reach + 120 + (half - abs(j["cx"] - ax)) * 0.8
        return out_

    def light_art(self, c, j, n):
        if j["kind"] == "pearl":
            cabochon(c, j["cx"], j["cy"], j["rx"], j["ry"], 0.0, j["colour"], True)
        else:
            facets(c, j["shape"], tuple(v * 0.94 for v in j["colour"]), j["cx"], j["cy"] - j["ry"] * 0.2, max(j["rx"], j["ry"]) * 1.1, 70 + n)

    def spots(self):
        sp = self.s
        pts = [(p[0], p[1] + 6) for p in sp["pins"]]
        pts += [(g[0], g[1] + 10) for g in sp["gablets"]]
        pts.append((sp["ax"], 30.0))
        return pts
