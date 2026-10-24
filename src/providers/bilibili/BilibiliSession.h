#pragma once
#include "../contracts/ProviderTypes.h"
#include "../contracts/Request.h"
#include <QNetworkAccessManager>
#include <QNetworkCookieJar>
#include <QUrlQuery>
namespace MusicProviders {
// Native-only session. No credentials are exposed as QObject/QML properties.
class BilibiliSession : public QObject {
public:
    enum class Origin { Api, Passport };
    explicit BilibiliSession(QObject *parent = nullptr);
    Request *get(Origin, const QString &, const QUrlQuery &, QObject *, Completion<QByteArray>);
    QByteArray credentials() const;
    bool restore(const QByteArray &);
    void clear();
    bool hasSession() const;
    quint64 generation() const { return m_generation; }
private:
    QNetworkAccessManager m_manager;
    QNetworkCookieJar *m_cookies;
    QList<QPointer<Request>> m_active;
    quint64 m_generation = 0;
};
}
