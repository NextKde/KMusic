#include "WindowMaterial.h"
#include <QRegion>
#include <QTimer>
#ifdef KMUSIC_HAVE_KWINDOWSYSTEM
#include <KWindowEffects>
#endif
void WindowMaterial::setWindow(QQuickWindow *window) {
    m_window = window;
    if (window) {
        connect(window, &QWindow::visibleChanged, this, [this] { update(); });
        connect(window, &QWindow::screenChanged, this, [this] { update(); });
    }
    update();
    QTimer::singleShot(100, this, [this] { update(); });
}
void WindowMaterial::setSidebarRect(const QRectF &rect) {
    const QRect next = rect.toAlignedRect();
    if (next == m_region) return;
    m_region = next;
    update();
}
void WindowMaterial::update() {
    bool available = false;
    bool requested = false;
    QString fallback = QStringLiteral("opaque: KF6WindowSystem not built");
#ifdef KMUSIC_HAVE_KWINDOWSYSTEM
    available = m_window && KWindowEffects::isEffectAvailable(KWindowEffects::BlurBehind);
    fallback = available ? QString{} : QStringLiteral("opaque: compositor blur unavailable");
    if (m_window) {
        // Empty KDE region means the entire window, so never submit one.
        const QRect clipped = m_region.intersected(QRect(QPoint(0, 0), m_window->size()));
        requested = m_reviewBlurEnabled && available && m_window->isVisible() && !clipped.isEmpty();
        KWindowEffects::enableBlurBehind(m_window, requested, requested ? QRegion(clipped) : QRegion{});
    }
#endif
    m_effectAvailable = available;
    m_blurRequested = requested;
    m_fallback = fallback;
    emit stateChanged();
}
