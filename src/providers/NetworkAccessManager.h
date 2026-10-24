#pragma once
#include <QNetworkAccessManager>
namespace MusicProviders {
// Compatibility containment for the observed Qt HTTP/2 HEADERS crash. Keep
// transport security/session policies at their callers; only disable HTTP/2.
class NetworkAccessManager final : public QNetworkAccessManager {
public:
    using QNetworkAccessManager::QNetworkAccessManager;
protected:
    QNetworkReply *createRequest(Operation, const QNetworkRequest &, QIODevice *) override;
};
}
