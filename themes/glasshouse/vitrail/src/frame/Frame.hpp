#pragma once

#include "frame/FramePass.hpp"

#include <hyprland/src/render/decorations/IHyprWindowDecoration.hpp>
#include <hyprland/src/helpers/AnimatedVariable.hpp>
#include <hyprland/src/render/Framebuffer.hpp>

#include <array>
#include <optional>
#include <string>

class CLens;

class CGlassFrame : public IHyprWindowDecoration {
  public:
    enum eRole : uint8_t {
        ROLE_NONE,
        ROLE_BORN,
        ROLE_GIVER,
        ROLE_RECEIVER,
    };

    CGlassFrame(PHLWINDOW window);
    virtual ~CGlassFrame();

    virtual SDecorationPositioningInfo getPositioningInfo() override;
    virtual void                       onPositioningReply(const SDecorationPositioningReply& reply) override;
    virtual void                       draw(Render::CRenderContext& ctx, PHLMONITOR monitor, float const& a, const Render::SWindowRenderPresentation& presentation) override;
    virtual eDecorationType            getDecorationType() override;
    virtual void                       updateWindow(PHLWINDOW window) override;
    virtual void                       damageEntire() override;
    virtual eDecorationLayer           getDecorationLayer() override;
    virtual uint64_t                   getDecorationFlags() override;
    virtual std::string                getDisplayName() override;

    void                               prepare();
    void                               relight(bool on);
    void                               lift(bool on);
    void                               call();
    void                               born(const PHLWINDOW& giver, int side);
    void                               lend(eRole role, const PHLWINDOW& peer, int side, const CBox& gone = {}, float goneLevel = 0);
    void                               arrive(float wait, bool grand = false, bool forward = true);
    void                               echo(double from, float wait);
    bool                               sounding() const;
    float                              lifeMs() const;
    float                              paceMs() const;
    float                              syncMs() const;
    void                               pace(float k);
    void                               sync(float pace, float lead);
    void                               hasten(float k);
    void                               hold(SP<Render::IFramebuffer> still, const CBox& box, float wait);
    void                               keep(float wait);
    float                              held() const;
    const SP<Render::IFramebuffer>&    still() const;
    void                               release();
    eRole                              role() const;
    bool                               settle();
    const CBox&                        gone() const;
    PHLWINDOW                          peer() const;
    int                                side() const;
    std::optional<CGlassPass::SData>   build(const PHLMONITOR& monitor, float alpha);

    CLens*                             m_lens = nullptr;
    bool                               damageLantern(const PHLMONITOR& monitor);
    void                               damageMotion(const PHLMONITOR& monitor);

    static void                        handoff(const PHLWINDOW& from, const PHLWINDOW& to, const std::optional<CBox>& gone);
    static std::array<int, 2>          bricksOf(const PHLWINDOW& w);
    static float                       closeMs(const PHLWINDOW& w);
    static constexpr double            MARGIN = 72;
    static CGlassFrame*                of(const PHLWINDOW& window);

  private:
    struct SFocus {
        float                level = 0, crest = 0, plate = 0;
        std::array<float, 4> plant = {};
    };

    SFocus                             focusAt(float t) const;
    SFocus                             focusNow() const;
    SFocus                             shownFocus() const;
    float                              lifted() const;
    float                              arriveMs() const;
    float                              closeAt() const;
    double                             reachNow() const;
    void                               know(const PHLWINDOW& w);
    void                               focus(bool on, double at, float wait, const PHLWINDOW& from = nullptr, double fromAt = 0);
    std::optional<CBox>                lantern(float* glow = nullptr) const;

    PHLWINDOWREF                       m_window;
    PHLANIMVAR<float>                  m_light, m_lift, m_seal, m_call, m_life, m_arrive, m_hold;
    float                              m_arriveWait = 0, m_holdWait = 0, m_run = 0, m_dir = 1, m_seed = 0, m_sealWait = 0, m_sealGain = 0.75F;
    double                             m_sealFrom = -1;
    SP<Render::IFramebuffer>           m_still;
    CBox                               m_stillBox;
    eRole                              m_role  = ROLE_NONE;
    PHLWINDOWREF                       m_peer;
    int                                m_side  = -1;
    CBox                               m_gone;
    float                              m_goneLevel = 0, m_focusAt = -1e9F, m_lentAt = 0, m_heldAt = -1;
    bool                               m_landed = false;
    double                             m_at    = 0;
    SFocus                             m_f0;
    std::array<float, 4>               m_stagger = {};
    std::array<int, 2>                 m_bricks = {};
    float                              m_wait  = 0, m_span = 0, m_plateIn = 110, m_bornPlate = -1, m_pace = 1, m_syncPace = 1, m_syncLead = 0, m_lifeLen = 0;
    size_t                             m_letters = 0;
    bool                               m_on    = false;
    float                              m_liftFrom = 0, m_liftTo = 0;
    PHLWINDOWREF                       m_from;
    double                             m_fromAt = 0;
    std::optional<CBox>                m_lanternDrawn;
    bool                               m_moving = false;
    bool                               m_known = false;
    std::string                        m_class;
    std::string                        m_app;
    std::string                        m_mark;
    std::string                        m_icon;
    bool                               m_glyph = false;
};
