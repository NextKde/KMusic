#pragma once
#include "contracts/ProviderTypes.h"
#include "contracts/Request.h"
#include <QNetworkAccessManager>
#include <QUrlQuery>

namespace MusicProviders {
struct HttpIdentity { QByteArray userAgent; QUrl referer; };
// Provider-local manager/cookie jar. API origin is fixed; redirects are rejected.
class HttpTransport final : public QObject {
public:
    explicit HttpTransport(const QUrl &origin, const HttpIdentity &identity = {}, QObject *parent = nullptr);
    Request *get(const QString &path, const QUrlQuery &, QObject *context,
                 Completion<QByteArray>);
private:
    QUrl m_origin;
    HttpIdentity m_identity;
    QNetworkAccessManager m_manager;
};
}
