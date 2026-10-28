import math

from .draw import oval
from .raster import K, area, coords
from .specs import LOOK, PLATES


class Design:
    world = ""

    def __init__(self, side):
        self.side = side
        self.box = PLATES[self.world][side]
        self.look = LOOK[self.world]
        self.left = side == "left"
        self.o = -1 if self.left else 1
        self._slots = None

    def area(self, draw, k=K):
        return area(self.box, draw, k)

    def coords(self, k=K):
        return coords(self.box, k)

    def slots(self):
        if self._slots is None:
            out_ = []
            for n, j in enumerate(self.jewels()):
                cx, cy, rx, ry, rot = j["cx"], j["cy"], j["rx"], j["ry"], math.radians(j.get("rot", 0.0))
                if "shape" not in j:
                    j["shape"] = lambda c, cx=cx, cy=cy, rx=rx, ry=ry, rot=rot: oval(c, cx, cy, rx, ry, rot)
                j["r"] = max(rx, ry)
                j["centre"] = (cx, cy)
                out_.append(j)
            top = max(j["d"] for j in out_) or 1
            for j in out_:
                j["order"] = j["d"] / top
            self._slots = out_
        return self._slots
