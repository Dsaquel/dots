#pragma once

#include "core/Palette.hpp"

#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/config/values/types/BoolValue.hpp>
#include <hyprland/src/config/values/types/IntValue.hpp>
#include <hyprland/src/config/values/types/StringValue.hpp>
#include <hyprland/src/helpers/signal/Signal.hpp>
#include <hyprland/src/helpers/math/Math.hpp>

#include <hyprutils/animation/AnimationConfig.hpp>

#include <chrono>
#include <map>
#include <string>
#include <vector>

inline HANDLE PHANDLE = nullptr;

struct SClosing {
    std::string     address;
    CBox            box;
    PHLWORKSPACEREF workspace;
    PHLWINDOWREF    window;
};

class CGhost;

enum class eShot : uint8_t {
    NONE,
    BARE,
    SKINNED,
};

struct SRetimed {
    PHLWINDOWREF window;
    bool         size = false;
    Vector2D     goal;
};

struct SGlobalState {
    SP<Config::Values::CBoolValue>        enabled;
    SP<Config::Values::CStringValue>      world;
    SP<Config::Values::CStringValue>      screens;
    SP<Config::Values::CStringValue>      assets;
    SP<Config::Values::CStringValue>      probe;
    SP<Config::Values::CIntValue>         debug;
    SP<Config::Values::CBoolValue>        retime;
    SP<Config::Values::CBoolValue>        enfilade;
    SP<Config::Values::CBoolValue>        translation;
    SP<Config::Values::CBoolValue>        relead;
    SP<Config::Values::CStringValue>      passage;
    SP<Config::Values::CBoolValue>        glaze;
    eShot                                 shooting = eShot::NONE;
    PHLWINDOWREF                          capturing;
    std::vector<WP<CGhost>>               ghosts;
    std::vector<SRetimed>                 retimed;
    std::map<std::string, SP<Hyprutils::Animation::SAnimationPropertyConfig>> paces;
    std::string                           worldOverride;
    PHLWINDOWREF                          lastFocus;
    bool                                  warm = false;
    std::vector<SClosing>                 closing;
    std::vector<PHLWINDOWREF>             lanterns;
    std::map<int, SP<Hyprutils::Animation::SAnimationPropertyConfig>> clocks;
    std::vector<CHyprSignalListener>      listeners;
    uint64_t                              glErrors = 0, glForeign = 0, passes = 0, timed = 0, timedNs = 0, lifeTimed = 0, lifeNs = 0, enfTimed = 0, enfNs = 0, enfMaxNs = 0;
    std::chrono::steady_clock::time_point born = std::chrono::steady_clock::now();
};

inline UP<SGlobalState> g_glass;

float                                              worldIndex();
std::string                                        worldName();
float                                              secondsAlive();
void                                               announce(const std::string& data);
void                                               settleDim(const PHLWINDOW& w);
SP<Hyprutils::Animation::SAnimationPropertyConfig> vitrailClock(float ms);
Vector2D                                           worldLightOn(const PHLMONITOR& monitor);

inline const SPalette& pal() {
    return worldIndex() > 0.5F ? LIGHT : DARK;
}

inline const SHue& hue() {
    return worldIndex() > 0.5F ? HUE_LIGHT : HUE_DARK;
}
