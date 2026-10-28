#include "frame/Internal.hpp"
#include "core/Assets.hpp"
#include <hyprland/src/workspace/HLWorkspace.hpp>

#include <cmath>
#include <cstdlib>
#include <ranges>
#include <unordered_map>

namespace Frame {
    struct SScreen {
        bool main  = true;
        int  first = 1, last = 5;
    };

    SScreen screenOf(const std::string& name) {
        static std::string                              spec;
        static std::unordered_map<std::string, SScreen> roles;
        const std::string                               NOW{g_glass->screens->value()};
        if (NOW != spec) {
            spec = NOW;
            roles.clear();
            for (const auto PART : std::views::split(spec, ',')) {
                const std::string P{PART.begin(), PART.end()};
                const auto        EQ = P.find('='), COLON = P.find(':'), DASH = P.rfind('-');
                if (EQ == std::string::npos || COLON == std::string::npos || DASH == std::string::npos || DASH < COLON)
                    continue;
                roles[P.substr(0, EQ)] = SScreen{.main  = P.substr(EQ + 1, COLON - EQ - 1) != "side",
                                                 .first = std::atoi(P.substr(COLON + 1, DASH - COLON - 1).c_str()),
                                                 .last  = std::atoi(P.substr(DASH + 1).c_str())};
            }
        }
        const auto IT = roles.find(name);
        return IT == roles.end() ? SScreen{} : IT->second;
    }

    Vector2D worldLight(const PHLMONITOR& m, const SPalette& p) {
        const auto   SCREEN = screenOf(m->m_name);
        const auto   WS     = m->m_activeWorkspace ? idOf(m->m_activeWorkspace) : -1;
        const int    INDEX  = WS >= SCREEN.first && WS <= SCREEN.last ? int(WS - SCREEN.first) : 0;
        const auto&  UV     = SCREEN.main ? p.mainUV : p.sideUV;
        const double W = m->m_size.x, H = m->m_size.y, FW = W * 1.025, FH = FW * 9 / 16;
        return {-(FW - W) * INDEX / 4 + UV[0] * FW, (H - FH) / 2 + UV[1] * FH};
    }

    SP<Hyprutils::Animation::SAnimationPropertyConfig> clockOf(float ms) {
        auto& clock = g_glass->clocks[int(ms)];
        if (!clock) {
            clock                  = makeShared<Hyprutils::Animation::SAnimationPropertyConfig>();
            clock->overridden      = true;
            clock->internalBezier  = "linear";
            clock->internalSpeed   = ms / 100.F;
            clock->internalEnabled = 1;
            clock->pValues         = clock;
        }
        return clock;
    }

    double cameOf(const PHLWINDOW& w, const CBox& box) {
        return w->onSpecialWorkspace() || box.w < 360 || box.h < 220 ? 7.5 : 9.5;
    }
}

using namespace Frame;

SP<Hyprutils::Animation::SAnimationPropertyConfig> vitrailClock(float ms) {
    return clockOf(ms);
}

Vector2D worldLightOn(const PHLMONITOR& monitor) {
    return worldLight(monitor, pal());
}
