import sys, os
import numpy as np
from scipy import ndimage
from PIL import Image
mode = sys.argv[1]
T = (os.environ.get("GH_TURN_TMP") or f"{os.environ.get('XDG_RUNTIME_DIR') or '/tmp'}/glasshouse-gen-turn-{os.getuid()}") + "/"
msk = np.load(T + f"{mode}-mask.npy").astype(np.float32) / 255.0
tim = np.load(T + f"{mode}-time.npy").astype(np.float32) / 255.0
core = msk > 0.35
dist, (iy, ix) = ndimage.distance_transform_edt(~core, return_indices=True)
arr = tim[iy, ix]
wgt = msk[iy, ix]
R = np.clip(dist / 24.0, 0, 1)
out = np.stack([R * 255, arr * 255, wgt * 255, np.full_like(R, 255)], -1).round().astype(np.uint8)
dst = os.path.join(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "turn"), f"cracks-{mode}.png")
Image.fromarray(out, "RGBA").save(dst)
print(mode, "crack px", int(core.sum()), "arrival range", float(arr[core].min()), float(arr[core].max()))
