#pragma once

#include "frame/Frame.hpp"
#include "core/Palette.hpp"
#include "core/Ring.hpp"
#include "core/Ease.hpp"
#include "core/globals.hpp"

#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/output/Monitor.hpp>

#include <array>

namespace Frame {
    constexpr float CARRY = 120, FADE = 90, LIFT = 300, SEAL = 420, CALL = 1500, GLOW = 132;
    constexpr float LEVEL_IN = 140, KICK = 0.35F, CREST_IN = 200, PLANT_IN = 340, STAGGER = 50, PLATE_DELAY = 20, FLIGHT = 140, SPREAD = 170, LETTER = 24;
    constexpr float LEVEL_OUT = 110, CREST_OUT = 150, PLANT_OUT = 200, PLATE_OUT = 180;
    constexpr float ARRIVAL = 760, SOW = 40, BLOOM = 240, VEIL_IN = 250, CREST_AT = 265, CREST_DROP = 105, CREST_RISE = 34, CONTACT = CREST_AT + 0.7F * CREST_DROP, PLATE_AT = 355;
    constexpr float BUILD_T0 = 230, BREATH = 50, PACE = 30, RAMP = 70, TURN = 3, PIECE = 72, CUE_GAP = 18, SOFT = 0.5F, LOUD = 0.75F, DOWN = 0.86F, CLOSE_CREST = -40, CLOSE_PLATE = 110,
                    SETTLED = 440, ECHO = 0.6F, LAP = 0.9F, REACH = 280;
    constexpr int   NOTES = 12;
    constexpr float NOT_ARRIVING = -1e9F, LET_GO = 110;
    constexpr float SLAM = 380, HOIST = 48, AFTER = 220, SETTLE_PX = 3, HOLD = 0.35F, FOLD = 60, QUICK = 150, HELD = 0.06F, AFLOAT = 45, SEAT = 36, CREST_SEAT = 250, PLATE_SEAT = 140, BUOY = 12;

    Vector2D                                           worldLight(const PHLMONITOR& m, const SPalette& p);
    SP<Hyprutils::Animation::SAnimationPropertyConfig> clockOf(float ms);
    double                                             cameOf(const PHLWINDOW& w, const CBox& box);
}
