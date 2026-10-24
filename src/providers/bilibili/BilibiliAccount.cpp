#include "BilibiliAccount.h"
#include "BilibiliResponse.h"
#include "../contracts/Operation.h"
#include <QJsonDocument>
#include <QTimer>
namespace MusicProviders {
Result<LoginChallenge> BilibiliAccount::decodeChallenge(const QByteArray &body, QString *privateKey) {
    const auto result = biliData(body);
    if (auto error = std::get_if<Error>(&result)) return *error;
    const auto data = std::get<QJsonObject>(result);
    const auto key = data.value("qrcode_key").toString(); const QUrl url(data.value("url").toString());
    const bool expectedQrPage = (url.host() == "passport.bilibili.com" && url.path() == "/h5-app/passport/login/scan")
        || (url.host() == "account.bilibili.com" && url.path() == "/h5/account-h5/auth/scan-web");
    if (key.isEmpty() || key.size() > 256 || url.scheme() != "https" || !expectedQrPage
        || QUrlQuery(url).queryItemValue("qrcode_key") != key || !url.userInfo().isEmpty())
        return Error{ErrorCode::InvalidResponse, QStringLiteral("Bilibili did not return a valid sign-in code.")};
    if (privateKey) *privateKey = key;
    return LoginChallenge{url};
}
Result<LoginState> BilibiliAccount::decodePoll(const QByteArray &body) {
    const auto result = biliData(body);
    if (auto error = std::get_if<Error>(&result)) return *error;
    const auto data = std::get<QJsonObject>(result);
    if (!data.value("code").isDouble()) return Error{ErrorCode::InvalidResponse, QStringLiteral("Invalid Bilibili sign-in status.")};
    switch (data.value("code").toInt()) {
    case 86101: return LoginState::WaitingForScan;
    case 86090: return LoginState::AwaitingApproval;
    case 86038: return LoginState::Expired;
    case 0: return LoginState::SignedIn;
    default: return Error{ErrorCode::Unavailable, QStringLiteral("Bilibili did not confirm sign-in. Generate a new code.")};
    }
}
Result<Account> BilibiliAccount::decodeAccount(const QByteArray &body) {
    const auto result = biliData(body);
    if (auto error = std::get_if<Error>(&result)) return *error;
    const auto data = std::get<QJsonObject>(result);
    if (!data.value("isLogin").isBool()) return Error{ErrorCode::InvalidResponse, QStringLiteral("Invalid Bilibili account response.")};
    if (!data.value("isLogin").toBool()) return Error{ErrorCode::AuthenticationRequired, QStringLiteral("Bilibili session expired. Sign in again.")};
    const auto uid = data.value("mid").toVariant().toLongLong();
    if (uid <= 0 || data.value("uname").toString().isEmpty()) return Error{ErrorCode::InvalidResponse, QStringLiteral("Bilibili account identity is missing.")};
    QUrl avatar(data.value("face").toString());
    if (avatar.scheme() != "https" || !avatar.userInfo().isEmpty()) avatar = QUrl{};
    return Account{{"bilibili", {}, QString::number(uid)}, data.value("uname").toString(), avatar};
}
void BilibiliAccount::cancelLogin() { ++m_loginEpoch; m_key.clear(); m_challengeAge.invalidate(); }
void BilibiliAccount::signOut() { cancelLogin(); m_session.clear(); }
Request *BilibiliAccount::beginLogin(QObject *context, Completion<LoginChallenge> done) {
    cancelLogin(); const auto epoch = m_loginEpoch;
    return m_session.get(BilibiliSession::Origin::Passport, "/x/passport-login/web/qrcode/generate", {}, context,
        [this, epoch, done](Result<QByteArray> result) {
            if (epoch != m_loginEpoch) { done(Error{ErrorCode::Cancelled, QStringLiteral("Sign-in cancelled.")}); return; }
            if (auto error = std::get_if<Error>(&result)) { done(*error); return; }
            auto decoded = decodeChallenge(std::get<QByteArray>(result), &m_key);
            if (std::holds_alternative<LoginChallenge>(decoded)) m_challengeAge.start();
            done(std::move(decoded));
        });
}
Request *BilibiliAccount::refreshSession(QObject *context, Completion<Account> done) {
    return m_session.get(BilibiliSession::Origin::Api, "/x/web-interface/nav", {}, context,
        [done](Result<QByteArray> result) {
            if (auto error = std::get_if<Error>(&result)) done(*error);
            else done(decodeAccount(std::get<QByteArray>(result)));
        });
}
Request *BilibiliAccount::pollLogin(QObject *context, Completion<LoginProgress> done) {
    auto op = Operation<LoginProgress>::create(context, std::move(done));
    const auto epoch = m_loginEpoch;
    if (m_key.isEmpty() || !m_challengeAge.isValid() || m_challengeAge.elapsed() >= 180000) {
        QTimer::singleShot(0, op->handle, [op] { op->finish(LoginProgress{LoginState::Expired, {}}); }); return op->handle;
    }
    op->child = m_session.get(BilibiliSession::Origin::Passport, "/x/passport-login/web/qrcode/poll", {{"qrcode_key", m_key}}, op->handle,
        [this, op, epoch](Result<QByteArray> result) {
            if (epoch != m_loginEpoch) { op->finish(Error{ErrorCode::Cancelled, QStringLiteral("Sign-in cancelled.")}); return; }
            if (auto error = std::get_if<Error>(&result)) { op->finish(*error); return; }
            const auto status = decodePoll(std::get<QByteArray>(result));
            if (auto error = std::get_if<Error>(&status)) { op->finish(*error); return; }
            const auto state = std::get<LoginState>(status);
            if (state != LoginState::SignedIn) { op->finish(LoginProgress{state, {}}); return; }
            // Never navigate to response.url/crossDomain. Cookies stay in this jar;
            // success is not accepted until the API verifies the actual identity.
            m_key.clear(); m_challengeAge.invalidate();
            op->child = refreshSession(op->handle, [op](Result<Account> account) {
                if (auto error = std::get_if<Error>(&account)) op->finish(*error);
                else op->finish(LoginProgress{LoginState::SignedIn, std::get<Account>(account)});
            });
        });
    return op->handle;
}
}
