#pragma once

#include "frame/FramePass.hpp"
#include "core/Gl.hpp"

#include <hyprland/src/render/transformer/Transformer.hpp>
#include <hyprland/src/desktop/state/Fadeout.hpp>
#include <hyprland/src/render/Framebuffer.hpp>

#include <array>
#include <optional>
#include <string>

inline constexpr float LIFE = 600.F, SET = 360.F, GIVEN = 390.F, SMOLDERED = 1200.F;

class CLens : public Gl::CTransformer {
  public:
    CLens(PHLWINDOW window);
    virtual ~CLens() = default;

    virtual Render::SWindowTransformBuffer transform(Render::CRenderContext& ctx, const Render::SWindowTransformBuffer& in, const Render::SWindowTransformContext& context) override;
    virtual void                           preWindowRender(Render::CRenderContext& ctx, CSurfacePassElement::SRenderData* data) override;
    virtual CBox                           transformedExtents(const CBox& currentBox) const override;
    virtual CBox                           transformBoxForDamage(const CBox& currentBox) const override;

    void                                   stash(CGlassPass::SData&& data);

  private:
    SP<Render::IFramebuffer>         paint(SP<Render::IFramebuffer> in);

    PHLWINDOWREF                     m_window;
    std::optional<CGlassPass::SData> m_stash;
    int                              m_calls = 0;
    WP<Render::IFramebuffer>         m_out;
    CBox                             m_win;
    float                            m_radius = 8;
    bool                             m_portal = false;
    float                            m_came   = 0, m_t = 0, m_seed = 0;
};

class CGhost : public Desktop::IFadeout {
  public:
    enum eKind : uint8_t {
        PENDING,
        GIVE,
        DUST,
        BURN,
    };

    static SP<CGhost>                     create(const PHLWINDOW& window, SP<Render::IFramebuffer> snapshot);
    virtual ~CGhost() = default;

    virtual PHLMONITORREF                 monitor() const override;
    virtual Desktop::eFadeoutPlane        plane() const override;
    virtual int                           zIndex() const override;
    virtual CBox                          renderBox() const override;
    virtual float                         alpha() const override;
    virtual bool                          done() const override;
    virtual Desktop::SFadeoutRenderEffects effects() const override;

    void                                  decide(const PHLWINDOW& receiver, int side, eKind alone = DUST);
    void                                  paint(bool grains = true, float end = 370.F);
    void                                  lay(const PHLMONITOR& monitor);
    CBox                                  region() const;
    CBox                                  area() const;
    float                                 level() const;
    float                                 ms() const;
    void                                  finish();
    void                                  pace(float k);
    void                                  hasten(float k);
    bool                                  pending() const;
    void                                  strand();
    bool                                  skinned() const;
    std::array<float, 5>                  front(float end = 370.F) const;

    std::string                           m_address;
    bool                                  m_laid = false, m_bare = false, m_hoisted = false;

  private:
    CGhost() = default;

    PHLMONITORREF                    m_monitor;
    Desktop::eFadeoutPlane           m_plane  = Desktop::FADEOUT_PLANE_WINDOW_TILED;
    int                              m_zIndex = 0;
    CBox                             m_box;
    float                            m_radius = 8;
    std::optional<CGlassPass::SData> m_skin;
    PHLWINDOWREF                     m_receiver;
    int                              m_side = -1;
    eKind                            m_kind = PENDING;
    PHLANIMVAR<float>                m_clock;
    bool                             m_over = false;
    float                            m_seed = 0;
    float                            m_pace = 1;
    WP<CGhost>                       m_self;
};

namespace Life {
    void open(const PHLWINDOW& window, const PHLWINDOW& giver);
    void late(const PHLWINDOW& window);
    void quench(const PHLWINDOW& window);
    void close(const PHLWINDOW& window);
    void leave(const PHLWINDOW& window, const PHLWINDOW& receiver, float arrive, bool bare);
    void decide(const std::string& address, const PHLWINDOW& receiver);
    void follow(const PHLWINDOW& window, float ms = LIFE);
    void pre(const PHLMONITOR& monitor);
    void stage(const PHLMONITOR& monitor);
    void exit();
    void unpace();
    void curves();
    bool warm();
    void destroy();
}
