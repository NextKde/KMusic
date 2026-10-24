#include "BilibiliSession.h"
#include "BilibiliApi.h"
#include <QJsonArray>
#include <QJsonDocument>
#include <QNetworkCookie>
#include <QNetworkRequest>
#include <QDateTime>
#include <QTimer>
#include <memory>
namespace MusicProviders {
namespace {
class Cookies : public QNetworkCookieJar {
public:
    using QNetworkCookieJar::QNetworkCookieJar;
    using QNetworkCookieJar::allCookies;
    using QNetworkCookieJar::setAllCookies;
};
bool allowed(const QNetworkCookie &c) {
    const auto domain = c.domain().toLower();
    static const QList<QByteArray> names{"SESSDATA", "bili_jct", "DedeUserID", "DedeUserID__ckMd5", "buvid3", "buvid4"};
    return names.contains(c.name()) && (domain == ".bilibili.com" || domain == "bilibili.com"
        || domain == "passport.bilibili.com" || domain == "api.bilibili.com")
        && (c.isSessionCookie() || c.expirationDate() > QDateTime::currentDateTimeUtc());
}
}
BilibiliSession::BilibiliSession(QObject *parent) : QObject(parent), m_manager(this), m_cookies(new Cookies(this)) {
    m_manager.setCookieJar(m_cookies); m_cookies->setParent(this);
}
QByteArray BilibiliSession::credentials() const {
    QJsonArray rows;
    for (const auto &cookie : static_cast<Cookies *>(m_cookies)->allCookies())
        if (allowed(cookie)) rows.append(QString::fromLatin1(cookie.toRawForm().toBase64()));
    return QJsonDocument(rows).toJson(QJsonDocument::Compact);
}
bool BilibiliSession::restore(const QByteArray &bytes) {
    clear();
    if (bytes.size() > 32768) return false;
    const auto doc = QJsonDocument::fromJson(bytes);
    if (!doc.isArray() || doc.array().size() > 32) return false;
    QList<QNetworkCookie> cookies;
    for (const auto &value : doc.array()) {
        const auto parsed = QNetworkCookie::parseCookies(QByteArray::fromBase64(value.toString().toLatin1()));
        if (parsed.size() != 1 || !allowed(parsed.first())) return false;
        auto cookie = parsed.first(); cookie.setSecure(true); cookies.append(cookie);
    }
    static_cast<Cookies *>(m_cookies)->setAllCookies(cookies);
    if (!hasSession()) { clear(); return false; }
    return true;
}
bool BilibiliSession::hasSession() const {
    for (const auto &cookie : static_cast<Cookies *>(m_cookies)->allCookies())
        if (allowed(cookie) && cookie.name() == "SESSDATA" && !cookie.value().isEmpty()) return true;
    return false;
}
void BilibiliSession::clear() {
    ++m_generation;
    const auto active = m_active;
    for (auto request : active) if (request) request->cancel();
    m_active.clear(); static_cast<Cookies *>(m_cookies)->setAllCookies({});
}
Request *BilibiliSession::get(Origin origin, const QString &path, const QUrlQuery &query,
                             QObject *context, Completion<QByteArray> done) {
    auto *operation = new Request(context);
    if (!path.startsWith('/') || path.startsWith("//") || path.contains('?') || path.contains('#')) {
        QTimer::singleShot(0, operation, [operation, done] { done(Error{operation->m_cancelled ? ErrorCode::Cancelled : ErrorCode::InvalidRequest, QStringLiteral("Invalid Bilibili request.")}); });
        return operation;
    }
    m_active.removeIf([](auto p) { return p.isNull(); }); m_active.append(operation);
    const auto epoch = m_generation;
    QUrl url(origin == Origin::Api ? "https://api.bilibili.com" : "https://passport.bilibili.com");
    url.setPath(path); url.setQuery(query);
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::ManualRedirectPolicy);
    request.setTransferTimeout(15000);
    request.setRawHeader("User-Agent", BilibiliApi::identity().userAgent);
    request.setRawHeader("Referer", "https://www.bilibili.com/");
    request.setRawHeader("Accept", "application/json");
    auto *reply = m_manager.get(request); operation->m_reply = reply;
    auto bytes = std::make_shared<QByteArray>();
    auto tooLarge = std::make_shared<bool>(false), timedOut = std::make_shared<bool>(false);
    constexpr qsizetype limit = 4 * 1024 * 1024;
    reply->setReadBufferSize(limit + 1);
    auto *deadline = new QTimer(operation); deadline->setSingleShot(true); deadline->start(15000);
    connect(deadline, &QTimer::timeout, operation, [reply, timedOut] { *timedOut = true; reply->abort(); });
    connect(reply, &QIODevice::readyRead, operation, [reply, bytes, tooLarge] {
        bytes->append(reply->read(limit + 1 - bytes->size()));
        if (bytes->size() > limit) { *tooLarge = true; reply->abort(); }
    });
    connect(reply, &QNetworkReply::finished, operation, [this, operation, reply, deadline, epoch, bytes, tooLarge, timedOut, done] {
        deadline->stop(); operation->m_reply = nullptr; m_active.removeAll(operation);
        if (!*tooLarge) bytes->append(reply->read(limit + 1 - bytes->size()));
        const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        const auto error = reply->error(); reply->deleteLater();
        if (operation->m_cancelled || epoch != m_generation) done(Error{ErrorCode::Cancelled, QStringLiteral("Request cancelled.")});
        else if (*tooLarge || bytes->size() > limit) done(Error{ErrorCode::InvalidResponse, QStringLiteral("Bilibili response is too large.")});
        else if (*timedOut || error == QNetworkReply::TimeoutError) done(Error{ErrorCode::Timeout, QStringLiteral("Bilibili request timed out."), true});
        else if (status == 401) done(Error{ErrorCode::AuthenticationRequired, QStringLiteral("Bilibili sign-in is required.")});
        else if (status == 403 || status == 412) done(Error{ErrorCode::VerificationRequired, QStringLiteral("Bilibili requires verification on its official website.")});
        else if (status == 429) done(Error{ErrorCode::RateLimited, QStringLiteral("Bilibili request limit reached."), true});
        else if (status < 200 || status >= 300 || error != QNetworkReply::NoError) done(Error{ErrorCode::Network, QStringLiteral("Bilibili connection failed. Retry when online."), true});
        else done(*bytes);
    });
    return operation;
}
}
