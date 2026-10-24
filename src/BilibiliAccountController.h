#pragma once
#include "providers/bilibili/BilibiliAccount.h"
#include <QTimer>
#include <QtQmlIntegration/qqmlintegration.h>
class BilibiliAccountController final : public QObject {
    Q_OBJECT
    QML_ANONYMOUS
    Q_PROPERTY(QString state READ state NOTIFY changed)
    Q_PROPERTY(QString message READ message NOTIFY changed)
    Q_PROPERTY(QString messageZh READ messageZh NOTIFY changed)
    Q_PROPERTY(QString nickname READ nickname NOTIFY changed)
    Q_PROPERTY(QString avatarUrl READ avatarUrl NOTIFY changed)
    Q_PROPERTY(QString qrImage READ qrImage NOTIFY changed)
    Q_PROPERTY(bool authenticated READ authenticated NOTIFY changed)
    Q_PROPERTY(bool cleanupRequired READ cleanupRequired NOTIFY changed)
    Q_PROPERTY(QString storageMessage READ storageMessage NOTIFY changed)
    Q_PROPERTY(QString storageMessageZh READ storageMessageZh NOTIFY changed)
    Q_PROPERTY(bool storageBusy READ storageBusy NOTIFY changed)
public:
    explicit BilibiliAccountController(MusicProviders::BilibiliSession &, QObject *parent = nullptr);
    QString state() const { return m_state; }
    QString message() const { return m_message; }
    QString messageZh() const { return m_messageZh; }
    QString nickname() const { return authenticated() ? m_identity.name : QString{}; }
    QString avatarUrl() const { return authenticated() ? m_identity.avatar.toString() : QString{}; }
    QString qrImage() const { return m_qr; }
    bool authenticated() const { return !m_identity.scope.account.isEmpty() && m_session.hasSession(); }
    bool cleanupRequired() const { return m_cleanup; }
    QString storageMessage() const { return m_storage; }
    QString storageMessageZh() const { return m_cleanup ? QStringLiteral("请解锁系统凭据库后重试移除。") : m_storage.isEmpty() ? QString{} : QStringLiteral("无法安全保存，仅本次会话有效。"); }
    bool storageBusy() const { return m_storageBusy; }
    MusicProviders::SourceScope scope() const { return authenticated() ? m_identity.scope : MusicProviders::SourceScope{}; }
    Q_INVOKABLE void beginLogin();
    Q_INVOKABLE void cancelLogin();
    Q_INVOKABLE void logout();
    Q_INVOKABLE void retrySession();
    void expire();
signals:
    void changed();
    void sessionChanged();
private:
    void setState(const QString &, const QString &, const QString &);
    void poll();
    void restore();
    void verify(quint64, const QString &expected = {});
    void save();
    void erase();
    void retireRequest();
    void failure(const MusicProviders::Error &);
    MusicProviders::BilibiliSession &m_session;
    MusicProviders::BilibiliAccount m_provider;
    MusicProviders::Account m_identity;
    QPointer<MusicProviders::Request> m_request;
    QTimer m_poll;
    quint64 m_epoch = 0;
    QString m_state = "restoring", m_message, m_messageZh, m_qr, m_storage;
    bool m_cleanup = false, m_storageBusy = false, m_pendingErase = false;
};
