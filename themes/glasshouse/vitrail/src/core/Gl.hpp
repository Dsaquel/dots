#pragma once

#include "core/Palette.hpp"

#include <hyprland/src/render/Shader.hpp>
#include <hyprland/src/render/Texture.hpp>
#include <hyprland/src/render/Context.hpp>
#include <hyprland/src/render/transformer/Transformer.hpp>
#include <hyprland/src/helpers/math/Math.hpp>

#include <optional>
#include <string>
#include <string_view>
#include <unordered_map>
#include <utility>

namespace Gl {
    struct SProgram {
        const std::string*                          frag;
        const char*                                 name;
        const std::string*                          vert   = nullptr;
        SP<CShader>                                 shader;
        bool                                        failed = false;
        std::unordered_map<std::string_view, GLint> loc;
        std::pair<const SPalette*, int>             stamp  = {nullptr, -1};

        GLint                                       operator[](const char* u);
    };

    struct SArea {
        CBox    drawn;
        CRegion region;
    };

    inline Vector2D      nudge;
    inline Render::CRenderContext* ctx = nullptr;

    bool                 ready(SProgram& p);
    void                 reset(SProgram& p);
    std::optional<SArea> areaOf(const CBox& phys, const std::optional<CBox>& hole);
    void                 paint(SProgram& p, const SArea& area);
    void                 rgb(SProgram& p, const char* u, const SRGB& c);
    void                 bindTex(int unit, const SP<Render::ITexture>& tex);
    void                 unbindAll();

    class CTransformer : public Render::IWindowTransformer {
      public:
        virtual bool active() const override;

        bool         dropped = false;
    };

    void                           drop(const PHLWINDOW& w, Render::IWindowTransformer* t);
    SP<Render::IFramebuffer>       widen(Render::CRenderContext& c, const Render::SWindowTransformBuffer& in);
    Render::SWindowTransformBuffer whole(const SP<Render::IFramebuffer>& fb);
}
