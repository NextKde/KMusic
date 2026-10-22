#pragma once
#include <QObject>
#include <QTimer>
#include <QElapsedTimer>
class OnlineMusicProvider;

// No cookie/token/QR key property is exposed to QML or persisted in preferences.
class AccountController final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString state READ state NOTIFY changed)
    Q_PROPERTY(QString message READ message NOTIFY changed)
    Q_PROPERTY(QString nickname READ nickname NOTIFY changed)
    Q_PROPERTY(QString avatarUrl READ avatarUrl NOTIFY changed)
    Q_PROPERTY(QString qrImage READ qrImage NOTIFY changed)
    Q_PROPERTY(bool authenticated READ authenticated NOTIFY changed)
    Q_PROPERTY(bool cleanupRequired READ cleanupRequired NOTIFY changed)
    Q_PROPERTY(QString storageMessage READ storageMessage NOTIFY changed)
public:
    AccountController(OnlineMusicProvider *provider, QObject *parent = nullptr);
    QString state() const { return m_state; }
    QString message() const { return m_message; }
    QString nickname() const { return m_nickname; }
    QString avatarUrl() const { return authenticated() ? m_avatarUrl : QString{}; }
    QString qrImage() const { return m_image; }
    QString storageMessage() const { return m_storageMessage; }
    bool cleanupRequired() const { return m_cleanupRequired; }
    bool authenticated() const { return m_state == "signedIn"; }
    Q_INVOKABLE void beginLogin();
    Q_INVOKABLE void cancelLogin();
    Q_INVOKABLE void logout();
    Q_INVOKABLE void retrySession();
signals:
    void changed();
    void sessionChanged();
private:
    void setState(const QString &state, const QString &message = {});
    void restore();
    void checkSession(quint64 generation, const QString &cookie = {});
    void poll();
    void save(const QString &cookie);
    void clearStored();
    OnlineMusicProvider *m_provider;
    QTimer m_poll;
    QElapsedTimer m_expiry;
    quint64 m_generation = 0;
    bool m_cleanupRequired = false;
    QString m_state = "restoring", m_message, m_nickname, m_avatarUrl, m_image, m_key, m_storageMessage;
};
