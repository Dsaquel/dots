#pragma once

#include "frame/FramePass.hpp"
#include "core/Gl.hpp"

namespace Frame {
    using Gl::SProgram;
    using Gl::ready;
    using Gl::areaOf;
    using Gl::paint;
    using Gl::rgb;
    using Gl::bindTex;
    using Gl::unbindAll;

    extern SProgram ornamentProgram;
    extern SProgram plateProgram;
    extern SProgram letterProgram;

    bool drawPiece(const SPiece& pc, const SPalette& P, float alpha, double S);
    bool drawPlate(const SPlateSpec& pl, const SPalette& P, const Vector2D& light, float alpha, double S);
}
