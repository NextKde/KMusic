#pragma once
#include <QObject>
#include <QPointer>
#include <QJsonObject>
class QQuickWindow;
class QQuickView;
class QQmlEngine;
class WindowMaterial;

// Explicit KMUSIC_REVIEW_DIR-only native compositor experiment. Never captures
// a screen/workspace: the fixed target is the interior of this app's sidebar.
class NativeReview final : public QObject {
    Q_OBJECT
public:
    NativeReview(QQmlEngine *engine, WindowMaterial *material, QString reviewDir, QObject *parent = nullptr);
    ~NativeReview() override;
    void setWindow(QQuickWindow *window);
    void showBackground();
    void hideBackground();
    void setBlurEnabled(bool enabled);
    void captureSidebar(const QString &path);
    QJsonObject status() const;
private:
    void respond(QJsonObject response) const;
    QQmlEngine *m_engine;
    WindowMaterial *m_material;
    QString m_reviewDir;
    QPointer<QQuickWindow> m_window;
    QQuickView *m_background = nullptr;
    bool m_busy = false;
    bool m_blurEnabled = true;
};
