#pragma once

#include <hyprland/src/desktop/DesktopTypes.hpp>

#include <array>
#include <optional>

namespace Passage {
    bool                                claims(const PHLMONITOR& monitor, const PHLWORKSPACE& from, const PHLWORKSPACE& to, bool pyre);
    void                                take(const PHLMONITOR& monitor, const PHLWORKSPACE& from, const PHLWORKSPACE& to, bool pyre);
    void                                lead(const PHLMONITOR& monitor);
    void                                finish(const PHLMONITOR& monitor);
    void                                cut(const PHLMONITOR& monitor);
    bool                                flies(const PHLMONITOR& monitor);
    bool                                holding(const PHLMONITOR& monitor);
    float                               walk(const PHLMONITOR& monitor, const PHLWORKSPACE& to);
    float                               length(const PHLMONITOR& monitor);
    std::array<float, 4>                lens(const PHLMONITOR& monitor);
    std::optional<std::array<float, 3>> view(const PHLMONITOR& monitor);
    std::array<float, 2>                pose(const PHLMONITOR& monitor, float t);
    void                                pre(const PHLMONITOR& monitor);
    void                                stage(const PHLMONITOR& monitor);
    void                                exit();
    bool                                warm();
    void                                destroy();
}
