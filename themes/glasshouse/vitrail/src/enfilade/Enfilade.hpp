#pragma once

#include <hyprland/src/desktop/DesktopTypes.hpp>

#include <array>
#include <optional>

namespace Enfilade {
    inline constexpr float WALK = 400, STRIDE = 340, STAGGER = 26;

    void                                begin(const PHLWORKSPACE& to);
    bool                                holding(const PHLMONITOR& monitor);
    bool                                flies(const PHLMONITOR& monitor);
    float                               walk(const PHLMONITOR& monitor, const PHLWORKSPACE& to);
    float                               length(const PHLMONITOR& monitor);
    void                                lead(const PHLMONITOR& monitor);
    void                                finish(const PHLMONITOR& monitor);
    std::array<float, 4>                lens(const PHLMONITOR& monitor);
    std::optional<std::array<float, 3>> view(const PHLMONITOR& monitor);
    std::array<float, 2>                pose(const PHLMONITOR& monitor, bool forward, float t);
    void                                pre(const PHLMONITOR& monitor);
    void                                stage(const PHLMONITOR& monitor);
    void                                exit();
    bool                                warm();
    void                                destroy();
}
