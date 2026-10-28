import math

import cairo

from kit import TAU


def stroke(c, w):
    c.set_line_width(w)
    c.stroke()


def eo(c, *paths):
    c.set_fill_rule(cairo.FILL_RULE_EVEN_ODD)
    for p in paths:
        p(c)
    c.fill()
    c.set_fill_rule(cairo.FILL_RULE_WINDING)


def oval(c, cx, cy, rx, ry, rot=0.0):
    c.save()
    c.translate(cx, cy)
    c.rotate(rot)
    c.scale(rx, ry)
    c.new_sub_path()
    c.arc(0, 0, 1, 0, TAU)
    c.restore()


def lozenge(c, cx, cy, rx, ry):
    c.move_to(cx, cy - ry)
    c.line_to(cx + rx, cy)
    c.line_to(cx, cy + ry)
    c.line_to(cx - rx, cy)
    c.close_path()


def knob(c, x, y, r):
    c.new_sub_path()
    c.arc(x, y, r, 0, TAU)


def pointed_arch(c, cx, yc, e, rho, bottom):
    dy = math.sqrt(max(0.0, rho * rho - e * e))
    c.new_sub_path()
    c.move_to(cx + e - rho, bottom)
    c.line_to(cx + e - rho, yc)
    c.arc(cx + e, yc, rho, math.pi, math.atan2(-dy, -e) + TAU)
    c.arc(cx - e, yc, rho, math.atan2(-dy, e) + TAU, TAU)
    c.line_to(cx - e + rho, bottom)
    c.close_path()


def lancet(c, x0, y0, x1, y1):
    w = x1 - x0
    ys = y0 + w * 0.866
    c.new_sub_path()
    c.move_to(x0, y1)
    c.line_to(x0, ys)
    c.arc(x1, ys, w, math.pi, 4 * math.pi / 3)
    c.arc(x0, ys, w, 5 * math.pi / 3, TAU)
    c.line_to(x1, y1)
    c.close_path()


def fleur(c, cx, cy, s, rot=0.0):
    c.save()
    c.translate(cx, cy)
    c.rotate(rot)
    c.scale(s, s)
    c.move_to(0, -0.5)
    c.curve_to(0.17, -0.3, 0.15, -0.06, 0.055, 0.1)
    c.line_to(-0.055, 0.1)
    c.curve_to(-0.15, -0.06, -0.17, -0.3, 0, -0.5)
    c.close_path()
    for sx in (-1, 1):
        c.move_to(sx * 0.05, 0.1)
        c.curve_to(sx * 0.18, -0.06, sx * 0.44, -0.16, sx * 0.43, 0.04)
        c.curve_to(sx * 0.42, 0.17, sx * 0.31, 0.2, sx * 0.25, 0.13)
        c.curve_to(sx * 0.31, 0.1, sx * 0.32, 0.02, sx * 0.24, 0.03)
        c.curve_to(sx * 0.16, 0.05, sx * 0.11, 0.12, sx * 0.06, 0.15)
        c.close_path()
    c.rectangle(-0.17, 0.1, 0.34, 0.065)
    c.move_to(-0.045, 0.165)
    c.line_to(0.045, 0.165)
    c.line_to(0.11, 0.33)
    c.line_to(0, 0.27)
    c.line_to(-0.11, 0.33)
    c.close_path()
    c.restore()


def crocket(c, x, y, ang, s):
    ux, uy = math.cos(ang), math.sin(ang)
    bx, by = x + ux * s * 0.42, y + uy * s * 0.42
    c.move_to(x - uy * s * 0.12, y + ux * s * 0.12)
    c.line_to(bx - uy * s * 0.1, by + ux * s * 0.1)
    c.line_to(bx + uy * s * 0.1, by - ux * s * 0.1)
    c.line_to(x + uy * s * 0.12, y - ux * s * 0.12)
    c.close_path()
    for da, d, r in ((-1.15, 0.3, 0.2), (0.0, 0.42, 0.24), (1.15, 0.3, 0.2)):
        c.new_sub_path()
        c.arc(bx + math.cos(ang + da) * s * d, by + math.sin(ang + da) * s * d, s * r, 0, TAU)


def ribbon(c, pts, w0, w1, caps=True):
    n = len(pts)
    left, right = [], []
    for i, (x, y) in enumerate(pts):
        xa, ya = pts[max(0, i - 1)]
        xb, yb = pts[min(n - 1, i + 1)]
        dx, dy = xb - xa, yb - ya
        ln = math.hypot(dx, dy) or 1
        w = (w0 + (w1 - w0) * i / max(1, n - 1)) / 2
        left.append((x - dy / ln * w, y + dx / ln * w))
        right.append((x + dy / ln * w, y - dx / ln * w))
    c.move_to(*left[0])
    for p in left[1:]:
        c.line_to(*p)
    for p in reversed(right):
        c.line_to(*p)
    c.close_path()
    if caps:
        knob(c, *pts[0], w0 / 2)
        knob(c, *pts[-1], w1 / 2)


def spiral(cx, cy, r0, r1, a0, a1, n=48):
    return [(cx + (r0 * (r1 / r0) ** (i / (n - 1))) * math.cos(a0 + (a1 - a0) * i / (n - 1)),
             cy + (r0 * (r1 / r0) ** (i / (n - 1))) * math.sin(a0 + (a1 - a0) * i / (n - 1))) for i in range(n)]


def bez(p0, p1, p2, p3, n=40):
    return [tuple((1 - t) ** 3 * a + 3 * (1 - t) ** 2 * t * b + 3 * (1 - t) * t * t * cc + t ** 3 * d for a, b, cc, d in zip(p0, p1, p2, p3))
            for t in (i / (n - 1) for i in range(n))]


def scroll(c, p0, p1, p2, p3, w0, w1, curl, turn=1.15):
    p = bez(p0, p1, p2, p3)
    ribbon(c, p, w0, w1)
    (ax, ay), (bx, by) = p[-2], p[-1]
    a = math.atan2(by - ay, bx - ax)
    nx, ny = -math.sin(a) * curl, math.cos(a) * curl
    ox, oy = bx + nx, by + ny
    a0 = math.atan2(by - oy, bx - ox)
    ribbon(c, spiral(ox, oy, abs(curl), max(0.8, abs(curl) * 0.18), a0, a0 + math.copysign(TAU * turn, curl), 40), w1, max(0.8, w1 * 0.4), False)


def beads(c, pts, r):
    for x, y in pts:
        knob(c, x, y, r)
    c.fill()
