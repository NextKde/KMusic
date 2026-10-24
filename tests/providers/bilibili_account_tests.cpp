#include "bilibili/BilibiliAccount.h"
#include "bilibili/BilibiliLibrary.h"
#include <QCoreApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTest>
using namespace MusicProviders;
#define CHECK(x) do { if (!(x)) qFatal("Failed line %d: %s", __LINE__, #x); } while(false)
static QByteArray body(const QJsonObject &data) { return QJsonDocument(QJsonObject{{"code", 0}, {"data", data}}).toJson(); }
int main(int argc, char **argv) {
    QCoreApplication app(argc, argv);
    QString key;
    CHECK(std::holds_alternative<LoginChallenge>(BilibiliAccount::decodeChallenge(body({{"qrcode_key", "fixture-key"},
        {"url", "https://passport.bilibili.com/h5-app/passport/login/scan?qrcode_key=fixture-key"}}), &key)));
    CHECK(key == "fixture-key");
    CHECK(std::holds_alternative<LoginChallenge>(BilibiliAccount::decodeChallenge(body({{"qrcode_key", "fixture-key"},
        {"url", "https://account.bilibili.com/h5/account-h5/auth/scan-web?qrcode_key=fixture-key"}}))));
    CHECK(std::holds_alternative<Error>(BilibiliAccount::decodeChallenge(body({{"qrcode_key", "fixture-key"},
        {"url", "https://account.bilibili.com/unexpected?qrcode_key=fixture-key"}}))));
    CHECK(std::holds_alternative<Error>(BilibiliAccount::decodeChallenge(body({{"qrcode_key", "x"}, {"url", "https://passport.bilibili.com/unexpected?qrcode_key=x"}}))));
    CHECK(std::holds_alternative<Error>(BilibiliAccount::decodeChallenge(body({{"qrcode_key", "x"}, {"url", "https://evil.example/h5-app/passport/login/scan?qrcode_key=x"}}))));
    for (auto pair : {std::pair{86101, LoginState::WaitingForScan}, {86090, LoginState::AwaitingApproval}, {86038, LoginState::Expired}, {0, LoginState::SignedIn}})
        CHECK(std::get<LoginState>(BilibiliAccount::decodePoll(body({{"code", pair.first}}))) == pair.second);
    CHECK(std::holds_alternative<Error>(BilibiliAccount::decodePoll(body({}))));
    CHECK(std::get<Error>(BilibiliAccount::decodeAccount("{\"code\":-101}")).code == ErrorCode::AuthenticationRequired);
    CHECK(std::get<Error>(BilibiliAccount::decodeAccount("{\"code\":-403}")).code == ErrorCode::VerificationRequired);
    CHECK(std::get<Error>(BilibiliAccount::decodeAccount(body({{"isLogin", false}}))).code == ErrorCode::AuthenticationRequired);
    CHECK(std::get<Error>(BilibiliAccount::decodeAccount(body({}))).code == ErrorCode::InvalidResponse);
    CHECK(std::get<Account>(BilibiliAccount::decodeAccount(body({{"isLogin", true}, {"mid", 123}, {"uname", "Fixture"}}))).scope.account == "123");
    BilibiliSession session;
    const auto epoch = session.generation();
    // Synthetic cookie fixture only. Never prints or uses a real account/session.
    const auto cookies = QJsonDocument(QJsonArray{QString::fromLatin1(QByteArray("SESSDATA=fixture; domain=.bilibili.com; path=/; secure").toBase64())}).toJson();
    CHECK(session.restore(cookies)); CHECK(session.hasSession()); CHECK(session.generation() > epoch);
    const auto serialized = session.credentials(); CHECK(!serialized.isEmpty());
    session.clear(); CHECK(!session.hasSession()); CHECK(session.credentials() == "[]");
    CHECK(session.restore(serialized)); session.clear();
    CHECK(!session.restore(QJsonDocument(QJsonArray{QString::fromLatin1(QByteArray("SESSDATA=fixture; domain=evil.example; path=/").toBase64())}).toJson()));
    CHECK(!session.restore("not-json")); CHECK(!session.hasSession());
    CHECK(!session.restore(QJsonDocument(QJsonArray{QString::fromLatin1(QByteArray("SESSDATA=fixture; domain=.bilibili.com; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT").toBase64())}).toJson()));
    CHECK(session.restore(serialized)); BilibiliAccount account(session); account.signOut(); CHECK(!session.hasSession());
    QObject context; bool expiredPoll = false;
    account.pollLogin(&context, [&](auto result) { expiredPoll = std::get<LoginProgress>(result).state == LoginState::Expired; });
    CHECK(QTest::qWaitFor([&] { return expiredPoll; }, 1000));
    bool destroyedCallback = false;
    auto *shortContext = new QObject;
    session.get(BilibiliSession::Origin::Api, "//invalid", {}, shortContext, [&](auto) { destroyedCallback = true; });
    delete shortContext; QCoreApplication::processEvents(); CHECK(!destroyedCallback);
    bool finished = false; Result<QByteArray> invalid = QByteArray{};
    auto *request = session.get(BilibiliSession::Origin::Api, "//bad", {}, &context, [&](auto result) { invalid = result; finished = true; });
    request->cancel(); CHECK(QTest::qWaitFor([&] { return finished; }, 1000)); CHECK(std::get<Error>(invalid).code == ErrorCode::Cancelled);
    const SourceScope scope{"bilibili", {}, "123"};
    const auto folders = BilibiliLibrary::decodeFolders(scope, body({{"count", 1}, {"list", QJsonArray{QJsonObject{{"id", 100}, {"title", "Favorites"}}}}}));
    CHECK(std::get<Page<LibraryEntry>>(folders).items.size() == 1);
    CHECK(std::get<Collection>(std::get<Page<LibraryEntry>>(folders).items.first()).scope == scope);
    CHECK(std::holds_alternative<Error>(BilibiliLibrary::decodeFolders(scope, body({}))));
    CHECK(std::get<Page<LibraryEntry>>(BilibiliLibrary::decodeFolders(scope, body({{"count", 0}, {"list", QJsonValue::Null}}))).items.isEmpty());
    auto media = QJsonObject{{"bvid", "BV1234567890"}, {"type", 2}, {"title", "Video"}, {"duration", 4}};
    const auto folder = BilibiliLibrary::decodeFolder(scope, body({{"info", QJsonObject{{"media_count", 3}}}, {"has_more", true}, {"medias", QJsonArray{media}}}), 1);
    CHECK(std::get<Page<LibraryEntry>>(folder).nextCursor == "2");
    CHECK(std::get<MediaItem>(std::get<Page<LibraryEntry>>(folder).items.first()).id.scope.account == "123");
    CHECK(std::holds_alternative<Error>(BilibiliLibrary::decodeFolder(scope, body({{"info", QJsonObject{}}, {"has_more", true}, {"medias", QJsonArray{}}}), 1)));
    auto entry = QJsonObject{{"title", "History"}, {"history", QJsonObject{{"business", "archive"}, {"bvid", "BV1234567890"}, {"cid", 123}}}, {"duration", 9}};
    const auto historyBody = body({{"list", QJsonArray{entry}}, {"cursor", QJsonObject{{"max", 42}, {"view_at", 1700000000}, {"business", "archive"}}}});
    const auto history = std::get<Page<LibraryEntry>>(BilibiliLibrary::decodeHistory(scope, historyBody));
    CHECK(history.items.size() == 1);
    const auto cursor = QJsonDocument::fromJson(QByteArray::fromBase64(history.nextCursor.toLatin1(), QByteArray::Base64UrlEncoding)).object();
    CHECK(cursor.value("business").toString() == "archive");
    CHECK(std::holds_alternative<Error>(BilibiliLibrary::decodeHistory(scope, historyBody, history.nextCursor)));
    // Cursor business survives mixed source records; non-video entries are not converted to fake videos.
    entry.insert("history", QJsonObject{{"business", "live"}, {"bvid", "BV1234567890"}});
    const auto mixed = std::get<Page<LibraryEntry>>(BilibiliLibrary::decodeHistory(scope, body({{"list", QJsonArray{entry}}, {"cursor", QJsonObject{{"max", 43}, {"view_at", 1700000001}, {"business", "live"}}}})));
    CHECK(mixed.items.isEmpty()); CHECK(!mixed.nextCursor.isEmpty());
    CHECK(QJsonDocument::fromJson(QByteArray::fromBase64(mixed.nextCursor.toLatin1(), QByteArray::Base64UrlEncoding)).object().value("business") == "live");
    CHECK(session.restore(serialized)); CHECK(session.hasSession());
    BilibiliLibrary library(session); library.setAccount(scope); bool denied = false;
    library.list({"bilibili", {}, "other-account"}, LibraryKind::Playlists, {}, &context, [&](auto result) { denied = std::get<Error>(result).code == ErrorCode::AuthenticationRequired; });
    CHECK(QTest::qWaitFor([&] { return denied; }, 1000));
    qInfo("Bilibili account/library fixtures passed; no real account authorization performed.");
    if (qEnvironmentVariableIsSet("KMUSIC_BILI_LIVE_ANONYMOUS")) {
        BilibiliSession anonymousSession;
        BilibiliAccount anonymous(anonymousSession);
        bool completed = false, generated = false, waiting = false, signedOut = false;
        int failureCode = -1;
        anonymous.beginLogin(&context, [&](auto result) {
            generated = std::holds_alternative<LoginChallenge>(result);
            if (auto error = std::get_if<Error>(&result)) failureCode = static_cast<int>(error->code);
            completed = true;
        });
        const bool response = QTest::qWaitFor([&] { return completed; }, 20000);
        qInfo("Live anonymous QR generation: received=%d available=%d errorCategory=%d (content redacted)", response, generated, failureCode);
        if (generated) {
            completed = false;
            anonymous.pollLogin(&context, [&](auto result) {
                if (auto progress = std::get_if<LoginProgress>(&result)) waiting = progress->state == LoginState::WaitingForScan;
                completed = true;
            });
            QTest::qWaitFor([&] { return completed; }, 20000);
            qInfo("Live anonymous poll: waitingForScan=%d", waiting);
        }
        anonymous.cancelLogin(); anonymousSession.clear();
        completed = false; bool cancelledChallenge = false;
        anonymous.pollLogin(&context, [&](auto result) {
            if (auto progress = std::get_if<LoginProgress>(&result)) cancelledChallenge = progress->state == LoginState::Expired;
            completed = true;
        });
        QTest::qWaitFor([&] { return completed; }, 1000);
        completed = false; failureCode = -1;
        anonymous.refreshSession(&context, [&](auto result) {
            if (auto error = std::get_if<Error>(&result)) { signedOut = error->code == ErrorCode::AuthenticationRequired; failureCode = static_cast<int>(error->code); }
            completed = true;
        });
        QTest::qWaitFor([&] { return completed; }, 20000);
        qInfo("Live cancellation=%d anonymousNavSignedOut=%d navErrorCategory=%d sessionPresent=%d; no user authorization performed", cancelledChallenge, signedOut, failureCode, anonymousSession.hasSession());
        return generated && waiting && cancelledChallenge && signedOut && !anonymousSession.hasSession() ? 0 : 1;
    }
}
