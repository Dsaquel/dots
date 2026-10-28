MOTION = {
    "burn": (0, 0.38, [0.091, 0.220, 0.338, 0.452, 0.507, 0.546, 0.573, 0.601, 0.598, 0.584, 0.597, 0.643, 0.678, 0.680, 0.680, 0.757, 0.894, 0.982, 1.000, 0.974, 0.909, 0.722, 0.483, 0.282]),
    "sweep": (0.11, 0.75, [0.134, 0.138, 0.141, 0.144, 0.146, 0.151, 0.154, 0.156, 0.157, 0.158, 0.167, 0.184, 0.201, 0.225, 0.256, 0.295, 0.355, 0.416, 0.477, 0.538, 0.587, 0.634, 0.682, 0.722, 0.752, 0.771, 0.775, 0.781, 0.790, 0.802, 0.815, 0.826, 0.837, 0.850, 0.867, 0.886, 0.904, 0.921, 0.934, 0.945, 0.956, 0.969, 0.980, 0.989, 0.994, 0.998, 0.997, 0.993, 0.989, 0.983, 0.979, 0.975, 0.971, 0.967, 0.963, 0.959, 0.958, 0.957, 0.956, 0.957, 0.953, 0.944, 0.932, 0.920, 0.907, 0.897, 0.889, 0.873, 0.858, 0.839, 0.812, 0.791, 0.772, 0.752, 0.733, 0.727, 0.729, 0.736, 0.743, 0.757, 0.770, 0.764, 0.757, 0.751, 0.742, 0.707, 0.672, 0.637, 0.600, 0.559, 0.531, 0.514, 0.493, 0.468, 0.446, 0.429, 0.405, 0.376, 0.347, 0.321, 0.293, 0.266, 0.241, 0.220, 0.198, 0.179, 0.165, 0.159, 0.153, 0.150, 0.151, 0.153, 0.157, 0.162, 0.166, 0.163, 0.158, 0.153, 0.147, 0.138, 0.128, 0.117, 0.106, 0.094, 0.082, 0.087, 0.093, 0.105]),
    "rebuild": (0.8583, 1.5483, [0.433, 0.654, 0.722, 0.851, 1.000, 0.986, 0.947, 0.884, 0.809, 0.731, 0.646, 0.569, 0.466, 0.365, 0.230, 0.154, 0.154, 0.121, 0.092, 0.240, 0.334, 0.304, 0.299, 0.336]),
}
SLAM, STRIKE = 0.41, 0.422
GLAZE = dict(rows=[0.05, 0.1, 0.147, 0.186, 0.219, 0.247, 0.27, 0.29], slam=0.32, weld=0.328, gild=0.45, pre=0.168,
             lifts=[0.04, 0.072, 0.1, 0.127, 0.151, 0.174, 0.194, 0.213, 0.23])
MULLION = dict(blink=1.195, boom=1.295, stones=[0.89, 0.936, 0.974, 1.005, 1.03, 1.051, 1.069, 1.087, 1.105, 1.123, 1.141, 1.159, 1.177, 1.195],
               welds=[0.315, 0.335, 0.35, 0.37, 0.395, 0.415, 0.44, 0.47, 0.5, 0.54, 0.59, 0.685, 0.69, 0.7, 0.705, 0.71, 0.715, 0.72, 0.73, 0.755])
HOIST = dict(shatter=0.055, rows=[0.091, 0.155, 0.204, 0.247, 0.285, 0.32, 0.354], slam=0.379, pre=0.022)
MOVE = dict(draft=0.2, strike=0.66, unframe=0.6583, boom=1.9533,
            stones=[1.5483, 1.5943, 1.6323, 1.6633, 1.6883, 1.7093, 1.7273, 1.7453, 1.7633, 1.7813, 1.7993, 1.8173, 1.8353, 1.8533])
MOVE_SYNTH = ([("blaze", 0, 1), ("embers", 0.06, 0.8), ("draft", 0.2, 0.9), ("pour", 0.66, 0.9), ("strike", 0.66, 1), ("unframe", 0.658, 1), ("expand", 0.928, 1),
               ("gather", 1.293, 1), ("confirm", 1.388, 1), ("blink", 1.853, 1), ("boom", 1.953, 0.85)]
              + [(f"stone-{1 + j * 8 // 14}", t, 0.34) for j, t in enumerate(MOVE["stones"])])


GLAZE_SHOW = ([(f"glaze-{n}", t, 1) for n, t in enumerate(GLAZE["rows"][1:], 2)]
              + [("glaze-slam", GLAZE["slam"], 1), ("glaze-run", GLAZE["slam"], 1), ("glaze-weld", GLAZE["weld"], 1), ("glaze-gild", GLAZE["gild"], 1)])
GLAZE_HIDE = [("glaze-crack", 0, 1)] + [(f"glaze-lift-{min(n, 8)}", t, 1) for n, t in enumerate(GLAZE["lifts"], 1)]
MULLION_SYNTH = ([("unframe", 0, 1), ("expand", 0.27, 1), ("gather", 0.635, 1), ("confirm", 0.73, 1), ("blink", MULLION["blink"], 1), ("boom", MULLION["boom"], 0.85)]
                 + [("weld", t, 1) for t in MULLION["welds"]] + [(f"stone-{1 + j * 8 // 14}", t, 0.34) for j, t in enumerate(MULLION["stones"])])
HOIST_SYNTH = ([("give", 0, 1), ("glaze-lift-2", 0.01, 0.35), ("shatter", HOIST["shatter"], 0.3), ("slam", HOIST["slam"], 1), ("boom", HOIST["slam"], 0.3), ("weld", HOIST["slam"] + 0.003, 0.5)]
               + [(f"stone-{n}", t, 0.28) for n, t in enumerate(HOIST["rows"], 1)])


STANDIN = {"athanor-pyre": [("athanor", 0, 1)], "swap": [("shatter", 0, 0.5), ("sluice", 0.15, 1), ("slam", SLAM, 1), ("strike", STRIKE, 0.4)],
           "swap-slam": [("slam", 0, 1), ("strike", STRIKE - SLAM, 0.4)], "pivot": [("shatter", 0, 0.5), ("scrape", 0.15, 1), ("slam", SLAM, 1), ("strike", STRIKE, 0.4)],
           "pivot-slam": [("slam", 0, 1), ("strike", STRIKE - SLAM, 0.4)], "pyre-lift": [("blaze", 0, 1), ("embers", 0.06, 0.8)], "pyre-flight": [("draft", 0.02, 0.9)],
           "pyre-strike": [("pour", 0, 0.9), ("strike", 0, 1)], "sand-rebuild": [("expand", 0.07, 1)], "sand-stone": [("stone-4", 0, 0.34)], "sand-boom": [("boom", 0, 0.85)],
           "sanctum-open": [("menu-open", 0, 1)], "sanctum-close": [("menu-close", 0, 1)],
           "scratch-slam": [("glaze-slam", GLAZE["pre"], 1), ("glaze-run", GLAZE["pre"], 1), ("glaze-weld", GLAZE["pre"] + GLAZE["weld"] - GLAZE["slam"], 1)],
           "scratch-gild": [("glaze-gild", 0, 1)], "scratch-hide": GLAZE_HIDE, **{f"scratch-row-{n}": [(f"glaze-{n}", 0, 1)] for n in range(1, 9)},
           "crystal-open": [("unframe", 0, 1), ("expand", 0.27, 1), ("confirm", 0.73, 1)], "crystal-flash": [("blink", 0, 1)], "crystal-ring": [("boom", 0, 0.85)],
           **{f"crystal-shard-{j}": [(f"stone-{min(1 + (j - 1) * 8 // 14, 8)}", 0, 0.34)] for j in range(1, 17)}, **{f"crystal-spark-{k}": [] for k in range(1, 7)},
           "crystal-rise": [("give", 0, 1), ("glaze-lift-2", 0.01, 0.35)], "crystal-burst": [("shatter", 0, 0.3)],
           "crystal-slam": [("slam", HOIST["pre"], 1), ("boom", HOIST["pre"], 0.3), ("weld", HOIST["pre"] + 0.003, 0.5)], **{f"crystal-row-{n}": [(f"stone-{n}", 0, 0.28)] for n in range(1, 9)}}
