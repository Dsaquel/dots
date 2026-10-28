import importlib
import sys

ORDER = ("chat", "chrome", "lancet", "lock", "pointer", "profile", "rose", "sanctum", "wings")

for name in ["common"] + [n for n in sys.argv[1:] or ORDER if n != "common"]:
    mod = importlib.import_module(name)
    if hasattr(mod, "build"):
        mod.build()
        print("built", name)
