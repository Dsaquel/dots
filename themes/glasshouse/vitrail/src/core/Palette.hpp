#pragma once

#include <array>

struct SRGB {
    float r = 0, g = 0, b = 0;
};

constexpr SRGB hex(unsigned v) {
    return {float((v >> 16) & 0xff) / 255.F, float((v >> 8) & 0xff) / 255.F, float(v & 0xff) / 255.F};
}

struct SMetal {
    SRGB  base, hi, low, sky;
    float metal = 1, shininess = 38, depth = 5;
};

struct SPalette {
    const char*          dir;
    bool                 dark;
    SRGB                 metalBase, metalHi, metalLow, metalSky;
    SRGB                 jewelA, jewelB, jewelC, pearl, hot;
    float                unlit, specGain, shininess;
    SRGB                 lamp, alert;
    float                poolDarker;
    std::array<float, 4> veil, shadow;
    SMetal               lead, trim;
    SRGB                 emBase, emHi, emLow;
    float                plateRim;
    SRGB                 glassTop, glassBottom;
    float                glassAlpha;
    SRGB                 plateBase, plateHi, plateLow;
    float                innerLine;
    std::array<float, 2> mainUV, sideUV;
};

inline constexpr SMetal PEARL = {hex(0xf3ede4), hex(0xffffff), hex(0x6d6480), hex(0xfff6fb), 0.5F, 60.F, 3.F};
inline constexpr SRGB   INNER = hex(0xffdc99);

inline constexpr SPalette DARK = {
    .dir         = "dark",
    .dark        = true,
    .metalBase   = hex(0x3a3950),
    .metalHi     = hex(0xd6d3f2),
    .metalLow    = hex(0x06070e),
    .metalSky    = hex(0x7d88ba),
    .jewelA      = hex(0x3558b8),
    .jewelB      = hex(0x6a4fc2),
    .jewelC      = hex(0xe3a253),
    .pearl       = hex(0xcfd8ec),
    .hot         = hex(0xffd9a0),
    .unlit       = 0.56F,
    .specGain    = 0.7F,
    .shininess   = 26.F,
    .lamp        = hex(0xf2b35e),
    .alert       = hex(0xe0668a),
    .poolDarker  = 1.6F,
    .veil        = {0.04F, 0.05F, 0.13F, 0.2F},
    .shadow      = {0.01F, 0.015F, 0.05F, 0.66F},
    .lead        = {hex(0x3a3950), hex(0xd6d3f2), hex(0x06070e), hex(0x7d88ba), 0.7F, 30.F, 4.2F},
    .trim        = {hex(0x9aa3c8), hex(0xf2f0ff), hex(0x141626), hex(0xc9d1ee), 0.8F, 40.F, 3.F},
    .emBase      = hex(0xc7cbe6),
    .emHi        = hex(0xffffff),
    .emLow       = hex(0x3a3f66),
    .plateRim    = 2.F,
    .glassTop    = {0.11F, 0.13F, 0.25F},
    .glassBottom = {0.06F, 0.07F, 0.15F},
    .glassAlpha  = 0.94F,
    .plateBase   = hex(0x4a4964),
    .plateHi     = hex(0xdcd8f6),
    .plateLow    = hex(0x07080f),
    .innerLine   = 0.F,
    .mainUV      = {0.523F, 0.323F},
    .sideUV      = {0.293F, 0.319F},
};

inline constexpr SPalette LIGHT = {
    .dir         = "light",
    .dark        = false,
    .metalBase   = hex(0xcaa36a),
    .metalHi     = hex(0xfff7e2),
    .metalLow    = hex(0x4a2f1c),
    .metalSky    = hex(0xfbe3b0),
    .jewelA      = hex(0xe8759a),
    .jewelB      = hex(0x7fb6ff),
    .jewelC      = hex(0xf3c14f),
    .pearl       = hex(0xf4efe6),
    .hot         = hex(0xfff0c8),
    .unlit       = 0.72F,
    .specGain    = 1.F,
    .shininess   = 38.F,
    .lamp        = hex(0xffd48a),
    .alert       = hex(0xcf3b4a),
    .poolDarker  = 2.2F,
    .veil        = {0.48F, 0.25F, 0.32F, 0.1F},
    .shadow      = {0.08F, 0.07F, 0.28F, 0.5F},
    .lead        = {hex(0xcaa36a), hex(0xfff7e2), hex(0x4a2f1c), hex(0xfbe3b0), 1.F, 42.F, 5.F},
    .trim        = {hex(0xc99a4e), hex(0xfff4cf), hex(0x3b2410), hex(0xf7dfa4), 1.F, 42.F, 3.F},
    .emBase      = hex(0xe9c47e),
    .emHi        = hex(0xfff6dc),
    .emLow       = hex(0x6a4320),
    .plateRim    = 2.2F,
    .glassTop    = {0.21F, 0.24F, 0.66F},
    .glassBottom = {0.12F, 0.13F, 0.42F},
    .glassAlpha  = 0.96F,
    .plateBase   = hex(0xcfa565),
    .plateHi     = hex(0xfff4d6),
    .plateLow    = hex(0x4a2f1c),
    .innerLine   = 0.4F,
    .mainUV      = {0.57F, 0.06F},
    .sideUV      = {0.184F, 0.312F},
};

struct SHue {
    SRGB  gold, hot, dust, spark, jewel0, jewel1, jewel2, sepia, leaf;
    float inked;
};

inline constexpr SHue HUE_DARK  = {hex(0xf2b35e), hex(0xffd9a0), hex(0xcfd8ec), hex(0xf2b35e), hex(0x3558b8), hex(0x6a4fc2), hex(0x3f8f86), hex(0x06070e), hex(0xf2b35e), 0.F};
inline constexpr SHue HUE_LIGHT = {hex(0xffd48a), hex(0xfff0c8), hex(0xb8873a), hex(0xfff0c8), hex(0xe8759a), hex(0xf3c14f), hex(0x5fd3e6), hex(0x4a2f1c), hex(0xcf9b3f), 1.F};
