#pragma once

#include <algorithm>
#include <cmath>

inline float unit(float k) {
    return std::clamp(k, 0.F, 1.F);
}

inline float span(float t, float a, float b) {
    return unit((t - a) / (b - a));
}

inline float smooth(float k) {
    const float X = unit(k);
    return X * X * (3.F - 2.F * X);
}

inline float outCubic(float k) {
    return 1.F - std::pow(1.F - unit(k), 3.F);
}

inline float inOutCubic(float k) {
    const float X = unit(k);
    return X < 0.5F ? 4.F * X * X * X : 1.F - std::pow(-2.F * X + 2.F, 3.F) / 2.F;
}
