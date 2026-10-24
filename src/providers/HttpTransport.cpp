#include "HttpTransport.h"
#include <QNetworkRequest>
#include <QTimer>
#include <memory>

namespace MusicProviders {
HttpTransport::HttpTransport(const QUrl &origin, const HttpIdentity &identity, QObject *parent)
    : QObject(parent), m_origin(origin), m_identity(identity), m_manager(this) {}

Request *HttpTransport::get(const QString &path, const QUrlQuery &query,
                            QObject *context, Completion<QByteArray> done)
{
    Q_ASSERT(context);
    auto *operation = new Request(context);
    QUrl url = m_origin;
    url.setPath(path);
    url.setQuery(query);
    // Queued errors obey the same cancellation/lifetime contract as HTTP requests.
    if (!m_origin.isValid() || !m_origin.userInfo().isEmpty()
        || (m_origin.scheme() != "https" && m_origin.scheme() != "http")
        || m_origin.host().isEmpty() || !path.startsWith('/') || path.startsWith("//")) {
        QTimer::singleShot(0, operation, [operation, done] {
            done(Error{operation->m_cancelled ? ErrorCode::Cancelled : ErrorCode::InvalidRequest,
                       QStringLiteral("Invalid provider request.")});
        });
        return operation;
    }
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::ManualRedirectPolicy);
    request.setTransferTimeout(15000);
    request.setRawHeader("Accept", "application/json");
    if (!m_identity.referer.isEmpty()) request.setRawHeader("Referer", m_identity.referer.toEncoded());
    if (!m_identity.userAgent.isEmpty()) request.setRawHeader("User-Agent", m_identity.userAgent);
    auto *reply = m_manager.get(request);
    operation->m_reply = reply;
    auto body = std::make_shared<QByteArray>();
    auto oversized = std::make_shared<bool>(false);
    constexpr qsizetype limit = 4 * 1024 * 1024;
    reply->setReadBufferSize(limit + 1);
    connect(reply, &QIODevice::readyRead, operation, [reply, body, oversized] {
        body->append(reply->read(limit + 1 - body->size()));
        if (body->size() > limit) { *oversized = true; reply->abort(); }
    });
    connect(reply, &QNetworkReply::finished, operation, [operation, reply, body, oversized, done] {
        operation->m_reply = nullptr;
        const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        const auto networkError = reply->error();
        if (!*oversized) body->append(reply->read(limit + 1 - body->size()));
        reply->deleteLater();
        if (operation->m_cancelled)
            done(Error{ErrorCode::Cancelled, QStringLiteral("Request cancelled.")});
        else if (*oversized || body->size() > limit)
            done(Error{ErrorCode::InvalidResponse, QStringLiteral("Provider response is too large.")});
        else if (status == 412)
            done(Error{ErrorCode::VerificationRequired, QStringLiteral("Provider verification is required.")});
        else if (status == 429)
            done(Error{ErrorCode::RateLimited, QStringLiteral("Provider request limit reached."), true});
        else if (status == 401)
            done(Error{ErrorCode::AuthenticationRequired, QStringLiteral("Please sign in again.")});
        else if (networkError == QNetworkReply::TimeoutError)
            done(Error{ErrorCode::Timeout, QStringLiteral("Provider request timed out."), true});
        else if (networkError != QNetworkReply::NoError || status < 200 || status >= 300)
            done(Error{ErrorCode::Network, QStringLiteral("Provider request failed."), status == 0 || status >= 500});
        else done(*body);
    });
    return operation;
}
}
