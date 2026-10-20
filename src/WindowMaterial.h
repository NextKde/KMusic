#pragma once
#include <QObject>
#include <QPointer>
#include <QQuickWindow>
#include <QRectF>

// Optional application platform adapter. Portable Kos.Ui has no KF/KWin imports.
class WindowMaterial final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool effectAvailable READ effectAvailable NOTIFY stateChanged)
    Q_PROPERTY(bool blurRequested READ blurRequested NOTIFY stateChanged)
    Q_PROPERTY(QRect region READ region NOTIFY stateChanged)
    Q_PROPERTY(QString fallback READ fallback NOTIFY stateChanged)
public:
    explicit WindowMaterial(QObject *parent = nullptr) : QObject(parent) {}
    void setWindow(QQuickWindow *window);
    Q_INVOKABLE void setSidebarRect(const QRectF &rect);
    bool effectAvailable() const { return m_effectAvailable; }
    bool blurRequested() const { return m_blurRequested; }
    QRect region() const { return m_region; }
    QString fallback() const { return m_fallback; }
signals:
    void stateChanged();
private:
    void update();
    QPointer<QQuickWindow> m_window;
    QRect m_region;
    bool m_effectAvailable = false;
    bool m_blurRequested = false;
    QString m_fallback = QStringLiteral("opaque: compositor blur unavailable");
};
