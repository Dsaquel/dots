#pragma once

#include "core/Palette.hpp"

#include <hyprland/src/render/pass/PassElement.hpp>
#include <hyprland/src/helpers/math/Math.hpp>

#include <array>
#include <optional>
#include <string>
#include <vector>

struct SPiece {
    enum eKind : uint8_t {
        FLOWER,
        CREST,
        PEARL,
    } kind;
    Vector2D    origin;
    Vector2D    pivot;
    float       size    = 0;
    int         quarter = 0;
    float       scale   = 1;
    float       opacity = 1;
    float       glow    = 0.5;
    float       grow    = 1;
    Vector2D    metalLight;
    Vector2D    glassLight;
    std::string mark;
    std::string icon;
    bool        glyph = false;
};

struct SPlateSpec {
    bool        on = false;
    Vector2D    pos;
    float       opacity  = 0;
    float       stream   = 1;
    float       flight   = 110;
    float       spread   = 0;
    bool        leaving  = false;
    double      maxWidth = 80;
    std::string app, title;
};

class CGlassPass : public IPassElement {
  public:
    struct SData {
        CBox                 window;
        float                scale       = 1;
        float                alpha       = 1;
        float                radius      = 8;
        float                offset      = 8;
        float                hwOff       = 1.15F;
        float                hwOn        = 2.2F;
        float                level       = 0;
        float                lift        = 0;
        float                veil        = 1;
        std::array<float, 4> seal        = {0, 1e5F, 0, 0};
        std::array<float, 4> laid        = {0, 1e5F, 0, 0};
        std::array<float, 4> gap         = {0, -1, 0, 0};
        std::array<float, 4> hinge       = {-1, 0, 0, 0};
        std::array<float, 4> athanor     = {-1, 0, 0, 0};
        std::array<float, 4> grow        = {};
        std::array<float, 4> gone        = {};
        std::array<float, 2> vanish      = {};
        std::array<float, 4> build       = {-1, 0, 0, 0};
        std::array<float, 4> room        = {};
        double               reach       = 0;
        float                seed        = 0;
        std::array<float, 4> cut         = {0, 1e5F, -1e5F, 0};
        std::array<float, 4> melt        = {0, 0, 0, 1};
        float                call        = 0;
        std::optional<CBox>  lantern;
        float                lanternGlow = 0;
        Vector2D             light;
        const SPalette*      pal         = nullptr;
        bool                 probe       = false;
        std::vector<SPiece>  pieces;
        SPlateSpec           plate;
    };

    CGlassPass(SData&& data);
    virtual ~CGlassPass() = default;

    virtual std::vector<UP<IPassElement>> draw(Render::CRenderContext& ctx) override;
    virtual bool                          needsLiveBlur(Render::CRenderContext& ctx) override;
    virtual bool                          needsPrecomputeBlur(Render::CRenderContext& ctx) override;
    virtual std::optional<CBox>           boundingBox(Render::CRenderContext& ctx) override;
    virtual const char*                   passName() override;
    virtual ePassElementType              type() override;

    void                                  paint();

  private:
    SData m_data;
};

bool warmGlassPrograms();
void destroyGlassPrograms();
