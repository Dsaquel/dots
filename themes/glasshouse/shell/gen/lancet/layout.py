import math


S = 2
HEX = lambda h: tuple(int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))  # noqa: E731

PAL = {
    "dark": dict(ground=["#141a37", "#18203f", "#1c2547", "#161d3c"], band="#1f3478", niche="#10163a",
                 panel="#111839", arch="#1a2250", sill="#232a45", seg=["#3558b8", "#6a4fc2", "#87b2aa", "#b8567e"],
                 lattice=(0.035, 0.045, 0.10), tip="#141b3a"),
    "light": dict(ground=["#1d2066", "#23277a", "#282d8c", "#20236f"], band="#5e2458", niche="#16195e",
                panel="#191c62", arch="#2b2f9a", sill="#3a3478", seg=["#e8759a", "#f3c14f", "#5fd3e6", "#8a63da"],
                lattice=(0.05, 0.04, 0.16), tip="#2a2f96"),
}
ROSE = {
    "dark": dict(deep=(0.16, 0.22, 0.46), ink=(0.10, 0.12, 0.26), dots=(0.55, 0.45, 0.84)),
    "light": dict(deep=(0.24, 0.30, 0.72), ink=(0.14, 0.14, 0.40), dots=(0.90, 0.28, 0.55)),
}


def layouts():
    main = dict(kind="main", zone=104, W=100, H=1068, x=2, y=6,
                rose=dict(cx=50, cy=74, r=44, heart=13),
                time=dict(x=17, y=126, w=66, h=100),
                niches=[dict(x=14, y=242 + i * 128, w=72, h=120) for i in range(4)],
                vials=dict(x=14, y=762, w=72, h=120),
                roundel=dict(cx=50, cy=960, r=42),
                sill=dict(y=1044, h=12),
                seps=[234, 754, 890],
                handle=dict(zone=18, inset=2, w=14, h=88, cy=960, pad=6, jewel=dict(cy=21, r=3.4), pearl=dict(cy=70, r=4)))
    side = dict(kind="side", zone=84, W=78, H=1068, x=3, y=6,
                rose=dict(cx=39, cy=58, r=34, heart=10),
                time=dict(x=12, y=102, w=54, h=96),
                niches=[], vials=None, roundel=None,
                sill=dict(y=1044, h=12),
                seps=[206],
                handle=dict(zone=18, inset=2, w=14, h=88, cy=960, pad=6, jewel=dict(cy=21, r=3.4), pearl=None),
                latch=dict(cx=39, cy=960, w=30, h=112))
    for L in (main, side):
        L["spring"] = round(L["W"] * math.sqrt(3) / 2, 2)
    return dict(main=main, side=side)
