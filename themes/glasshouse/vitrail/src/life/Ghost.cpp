#include "life/Internal.hpp"

using namespace Life;

namespace Life {
    class CGhostPass : public IPassElement {
      public:
        CGhostPass(WP<CGhost> ghost) : m_ghost(ghost) {}
        virtual ~CGhostPass() = default;

        virtual std::vector<UP<IPassElement>> draw(Render::CRenderContext& ctx) override {

            Gl::ctx = &ctx;
            if (const auto G = m_ghost.lock())
                G->paint();
            return {};
        }
        virtual bool needsLiveBlur(Render::CRenderContext& ctx) override {
            return false;
        }
        virtual bool needsPrecomputeBlur(Render::CRenderContext& ctx) override {
            return false;
        }
        virtual std::optional<CBox> boundingBox(Render::CRenderContext& ctx) override {
            const auto G = m_ghost.lock();
            return G ? std::optional<CBox>{G->region()} : std::nullopt;
        }
        virtual const char* passName() override {
            return "CGhostPass";
        }
        virtual ePassElementType type() override {
            return EK_CUSTOM;
        }

      private:
        WP<CGhost> m_ghost;
    };
}

SP<CGhost> CGhost::create(const PHLWINDOW& w, SP<Render::IFramebuffer> snapshot) {
    const auto MON = w->m_monitor.lock();
    if (!MON || !snapshot)
        return nullptr;
    auto g           = SP<CGhost>(new CGhost());
    g->m_self        = g;
    g->m_address     = std::format("{:x}", rc<uintptr_t>(w.get()));
    g->m_monitor     = MON;
    g->m_workspace   = w->m_workspace;
    g->m_framebuffer = snapshot;
    const auto& ALL  = Desktop::windowState()->windows();
    const auto  IT   = std::ranges::find(ALL, w);
    g->m_zIndex      = IT == ALL.end() ? 0 : int(std::distance(ALL.begin(), IT));
    g->m_plane       = w->isFloating() ? Desktop::FADEOUT_PLANE_WINDOW_FLOATING : Desktop::FADEOUT_PLANE_WINDOW_TILED;
    g->m_box         = boxOf(w).translate(-MON->m_position);
    g->m_radius      = w->presentation().rounding();
    g->m_seed        = float(std::fmod(g->m_box.x * 0.37 + g->m_box.y * 0.11, 17.0));
    if (auto* const F = CGlassFrame::of(w))
        g->m_skin = F->build(MON, 1.F);
    if (g->m_skin) {
        g->m_skin->lantern.reset();
        g->m_skin->hinge = {-1, 0, 0, 0};
        g->m_skin->build = {-1, 0, 0, 0};
        g->m_skin->reach = 0;
    }
    Animation::mgr()->createAnimation(0.F, g->m_clock, vitrailClock(LIFE), AVARDAMAGE_NONE);
    const WP<CGhost> WEAK = g;
    g->m_clock->setUpdateCallback([WEAK](auto) {
        if (const auto G = WEAK.lock(); G && G->m_monitor)
            g_pHyprRenderer->damageBox(G->region().copy().translate(G->m_monitor->m_position).expand(2));
    });
    g->m_clock->setValueAndWarp(0.F);
    *g->m_clock = 1.F;
    return g;
}

PHLMONITORREF CGhost::monitor() const {
    return m_monitor;
}

Desktop::eFadeoutPlane CGhost::plane() const {
    return m_plane;
}

int CGhost::zIndex() const {
    return m_zIndex;
}

CBox CGhost::renderBox() const {
    return {};
}

float CGhost::alpha() const {
    return 1.F;
}

bool CGhost::done() const {
    return m_over || !m_clock || !m_clock->isBeingAnimated();
}

void CGhost::finish() {
    m_over = true;
}

float CGhost::ms() const {
    return m_clock ? m_clock->value() * LIFE * m_pace : LIFE;
}

void CGhost::pace(float k) {
    m_pace = k;
}

void CGhost::strand() {
    if (m_kind != GIVE || !m_hoisted || ms() >= SLAM)
        return;
    const auto  R = m_receiver.lock();
    auto* const F = validMapped(R) ? CGlassFrame::of(R) : nullptr;
    if (F && F->role() == CGlassFrame::ROLE_RECEIVER)
        m_hoisted = F->gone() == area();
    else
        decide(nullptr, -1, BURN);
}

bool CGhost::skinned() const {
    return m_skin.has_value();
}

bool CGhost::pending() const {
    return m_kind == PENDING;
}

void CGhost::hasten(float k) {
    m_clock->setConfig(vitrailClock(LIFE / k));
    m_clock->setValueAndWarp(0.F);
    *m_clock = 1.F;
}

std::array<float, 5> CGhost::front(float end) const {
    const auto MON = m_monitor.lock();
    const CBox BOX = m_box.copy().expand(CGlassFrame::MARGIN).scale(MON ? MON->m_scale : 1.0).round();
    return {float(BOX.y), float(BOX.h), 20.F, end, m_seed};
}

Desktop::SFadeoutRenderEffects CGhost::effects() const {
    if (!done() && g_glass && g_glass->enabled->value() && !(m_laid && m_kind == GIVE))
        g_pHyprRenderer->addPassElement(*Gl::ctx, makeUnique<CGhostPass>(m_self));
    return m_effects;
}

void CGhost::lay(const PHLMONITOR& monitor) {
    const auto WS = m_workspace.lock();
    if (m_laid || m_kind != GIVE || done() || !g_glass->enabled->value() || m_monitor.lock() != monitor || !WS || WS != monitor->m_activeWorkspace)
        return;
    g_pHyprRenderer->addPassElement(*Gl::ctx, makeUnique<CGhostPass>(m_self));
    m_laid = true;
}

CBox CGhost::area() const {
    const auto M = m_monitor.lock();
    return m_box.copy().translate(M ? M->m_position : Vector2D{});
}

float CGhost::level() const {
    return m_skin ? m_skin->level : 0.F;
}

CBox CGhost::region() const {
    const CBox FRAME = m_box.copy().expand(CGlassFrame::MARGIN);
    if (m_kind == GIVE) {
        const auto R = m_receiver.lock();
        const auto M = m_monitor.lock();
        if (!R || !M)
            return FRAME;
        const CBox   B  = boxOf(R).translate(-M->m_position).expand(CGlassFrame::MARGIN);
        const CBox   F  = FRAME.copy().expand(m_hoisted ? SHADE : 0.0);
        const double X0 = std::min(F.x, B.x), Y0 = std::min(F.y, B.y);
        return {X0, Y0, std::max(F.x + F.w, B.x + B.w) - X0, std::max(F.y + F.h, B.y + B.h) - Y0};
    }
    return CBox{FRAME.x - 120, FRAME.y - 360, FRAME.w + 240, FRAME.h + 380};
}

void CGhost::decide(const PHLWINDOW& receiver, int side, eKind alone) {
    m_receiver = receiver;
    m_side     = side;
    m_kind     = receiver && side >= 0 && m_skin ? GIVE : alone;
}

void CGhost::paint(bool grains, float end) {
    const auto MON = m_monitor.lock();
    const auto TEX = m_framebuffer ? m_framebuffer->getTexture() : nullptr;
    if (!MON || !TEX || Gl::ctx->m_data.pMonitor.lock() != MON)
        return;
    const STimer TIMER;
    const float  T   = ms();
    const double S   = MON->m_scale;
    const CBox   WIN = m_box.copy().scale(S).round();
    g_pHyprOpenGL->blend(true);
    SContent c{.tex = TEX, .texSize = m_framebuffer->m_size, .win = WIN, .radius = float(m_radius * S), .t = T, .seed = m_seed};
    if (m_kind == GIVE) {
        const auto     R   = m_receiver.lock();
        const int      FAR = m_side;
        if (!m_bare) {
            const double   DX = FAR == 1 ? -1 : (FAR == 3 ? 1 : 0), DY = FAR == 2 ? -1 : (FAR == 0 ? 1 : 0);
            const Vector2D O{FAR == 1 ? m_box.x + m_box.w : (FAR == 3 ? m_box.x : m_box.x + m_box.w / 2), FAR == 2 ? m_box.y + m_box.h : (FAR == 0 ? m_box.y : m_box.y + m_box.h / 2)};
            c.mode   = 2;
            c.drawn  = WIN.copy().expand(2);
            c.origin = {float(O.x * S), float(O.y * S), float(DX), float(DY)};
            c.span   = float((DX != 0 ? m_box.w : m_box.h) * S);
            c.timing = {40.F, 560.F, 200.F, 60.F};
            c.cell   = Vector2D{std::clamp(m_box.w / 14, 44.0, 64.0), std::clamp(m_box.h / 10, 66.0, 96.0)} * S;
            if (R && validMapped(R)) {
                const CBox     B = boxOf(R).translate(-MON->m_position);
                const Vector2D E{FAR == 1 ? B.x + B.w : (FAR == 3 ? B.x : O.x), FAR == 2 ? B.y + B.h : (FAR == 0 ? B.y : O.y)};
                c.edge = float(((E.x - O.x) * DX + (E.y - O.y) * DY) * S - BITE * std::max(c.cell.x, c.cell.y));
            }
            drawContent(c, MON);
        }
        if (m_skin) {
            auto         skin = *m_skin;
            const SRing  RING(m_box, m_radius);
            const double FARU = RING.mid(FAR), HALF = RING.per / 2;
            skin.laid         = m_hoisted ? std::array<float, 4>{0.F, -1e5F, 0.F, 0.F} : std::array<float, 4>{float(FARU), float(HALF + 20 - (HALF + 40) * span(T, 60, 250)), span(T, 60, 110), 0.F};
            skin.veil         = 1.F - span(T, 70, 470);
            const auto KEPT   = [&](const Vector2D& at) { return m_hoisted ? 1.F - span(T, 0, FOLD) : unit(float((skin.laid[1] - RING.circ(RING.u(at), FARU)) / 40)); };
            for (auto& pc : skin.pieces) {
                const float K = KEPT(pc.origin);
                pc.opacity *= K;
                pc.scale *= m_hoisted ? 0.55F + 0.45F * K : 0.7F + 0.3F * K;
            }
            skin.plate.opacity *= KEPT(skin.plate.pos + Vector2D{40, 11});
            skin.lantern.reset();
            auto&         rd     = Gl::ctx->m_data;
            const CRegion DAMAGE = rd.damage.copy();
            for (const auto& w : Desktop::windowState()->windows()) {
                if (!validMapped(w) || w->isFloating() || w->m_workspace != m_workspace.lock())
                    continue;
                CBox over = boxOf(w).expand(w == R && !m_hoisted ? CGlassFrame::MARGIN : 0.0).translate(-MON->m_position).scale(S).round();
                rd.renderModif.applyToBox(over);
                rd.damage.subtract(over);
            }
            CGlassPass(std::move(skin)).paint();
            rd.damage = DAMAGE;
        }
        Gl::unbindAll();
        return;
    }
    const CBox BOX = m_box.copy().expand(CGlassFrame::MARGIN).scale(S).round();
    const bool BURNS = m_kind == DUST || m_kind == BURN;
    c.mode         = 3;
    c.drawn        = BOX;
    c.front        = BURNS ? std::array<float, 4>{float(BOX.y), float(BOX.h), 20.F, end} : std::array<float, 4>{0.F, 1.F, 1e6F, 1e6F};
    c.fire         = m_kind == BURN ? 1.F : 0.F;
    c.came         = m_skin ? m_skin->offset : 9.5F;
    drawContent(c, MON);
    if (BURNS && grains)
        drawGrains(TEX, m_framebuffer->m_size, BOX, T, c.front, m_seed, MON, WIN, c.radius, m_kind == BURN);
    if (m_kind == BURN)
        drawSlivers(BOX, WIN, c.radius, c.front, c.came, T, m_seed, MON);
}
