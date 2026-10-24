#include "NetworkAccessManager.h"
#include <QNetworkRequest>
namespace MusicProviders {
QNetworkReply *NetworkAccessManager::createRequest(Operation operation, const QNetworkRequest &original, QIODevice *outgoing) {
    auto request = original;
    // Do not negotiate or force the path seen in the crash. This is a bounded
    // application workaround, not a repair of the unproven invalid-pointer cause.
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);
    request.setAttribute(QNetworkRequest::Http2DirectAttribute, false);
    return QNetworkAccessManager::createRequest(operation, request, outgoing);
}
}
