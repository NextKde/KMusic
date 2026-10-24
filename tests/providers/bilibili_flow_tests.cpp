#include "bilibili/WbiSigner.h"
#include "bilibili/BilibiliSearch.h"
#include "bilibili/BilibiliPlaybackResolver.h"
#include <QCoreApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QTest>
using namespace MusicProviders;
#define CHECK(c) do { if (!(c)) qFatal("Failed line %d: %s", __LINE__, #c); } while (false)
int main(int argc, char **argv) {
    QCoreApplication app(argc, argv);
    if (app.arguments().contains("--live")) {
        BilibiliSearch search; BilibiliPlaybackResolver resolver;
        bool done = false; int resultCode = 1;
        search.search({"bilibili", {}, {}}, "原创 音乐", {}, &app, [&](Result<Page<MediaItem>> result) {
            if (auto error = std::get_if<Error>(&result)) { qWarning() << "LIVE SEARCH FAILED:" << error->message; done = true; return; }
            const auto page = std::get<Page<MediaItem>>(result);
            qInfo() << "LIVE SEARCH ITEMS:" << page.items.size();
            if (page.items.isEmpty()) { done = true; return; }
            resolver.resolve(page.items.first().id, "AAC", &app, [&](Result<PlaybackSource> source) {
                if (auto error = std::get_if<Error>(&source)) qWarning() << "LIVE RESOLVE FAILED:" << error->message;
                else { qInfo() << "LIVE RESOLVE OK: AAC audio; signed URL intentionally omitted"; resultCode = 0; }
                done = true;
            });
        });
        CHECK(QTest::qWaitFor([&] { return done; }, 65000));
        return resultCode;
    }
    auto signedQuery = WbiSigner::sign({{"foo", "114"}, {"bar", "514"}, {"zab", "1919810"}},
        "7cd084941338484aae1ad9425b84077c", "4932caff0ff746eab6f01bf08b70ac45", 1702204169);
    CHECK(std::holds_alternative<QUrlQuery>(signedQuery));
    CHECK(std::get<QUrlQuery>(signedQuery).queryItemValue("w_rid") == "8f6f2b5b3d485fe1886cec6a0be8c5d4");
    CHECK(std::holds_alternative<Error>(WbiSigner::sign({}, "bad", "bad", 1)));
    const SourceScope scope{"bilibili", {}, {}};
    auto result = BilibiliSearch::decode(scope, R"({"code":0,"data":{"page":1,"numPages":3,"result":[{"bvid":"BV1234567890","title":"<em>Music</em> &amp; Piano","author":"Composer","pic":"//example.com/image.jpg","duration":"03:20"}]}})");
    CHECK(std::holds_alternative<Page<MediaItem>>(result));
    const auto page = std::get<Page<MediaItem>>(result);
    CHECK(page.items.size() == 1 && page.nextCursor == "2");
    CHECK(page.items.first().title == "Music & Piano" && page.items.first().durationMs == 200000);
    CHECK(page.items.first().id.scope == scope && page.items.first().artwork.scheme() == "https");
    CHECK(std::get<Error>(BilibiliSearch::decode(scope, R"({"code":0,"data":{"v_voucher":"secret"}})")).code == ErrorCode::VerificationRequired);
    MediaId id{scope, "BV1234567890", "123"};
    auto audio = BilibiliPlaybackResolver::decode(id, R"({"code":0,"data":{"dash":{"audio":[{"codecs":"mp4a.40.2","bandwidth":100,"baseUrl":"https://cdn.example/audio?deadline=1900000000","backupUrl":["https://backup.example/audio","file:///tmp/not-a-stream"]},{"codecs":"ec-3","bandwidth":1000,"baseUrl":"https://cdn.example/premium"}]}}})");
    CHECK(std::holds_alternative<PlaybackSource>(audio));
    const auto source = std::get<PlaybackSource>(audio);
    CHECK(source.id == id && source.backups.size() == 1 && source.expiresAt.isValid());
    CHECK(source.url.path() == "/audio" && !source.userAgent.isEmpty() && source.referer.host() == "www.bilibili.com");
    CHECK(std::holds_alternative<Error>(BilibiliPlaybackResolver::decode(id, R"({"code":0,"data":{"dash":{"audio":[]}}})")));
    CHECK(std::holds_alternative<Error>(BilibiliPlaybackResolver::decode(id, R"({"code":0,"data":{"is_preview":1}})")));
    auto relay = BilibiliPlaybackResolver::decode(id, R"({"code":0,"data":{"dash":{"audio":[{"codecs":"mp4a.40.2","baseUrl":"https://edge.example/audio?deadline=1800000000","backupUrl":["https://upos-cdn.bilivideo.com.evil.example/audio","https://upos-cdn.bilivideo.com/audio?deadline=1900000000"]}]}}})");
    CHECK(std::holds_alternative<PlaybackSource>(relay));
    const auto direct = std::get<PlaybackSource>(relay);
    CHECK(direct.url == QUrl("https://upos-cdn.bilivideo.com/audio?deadline=1900000000"));
    CHECK(direct.backups.first().host() == "edge.example" && direct.backups.size() == 2);
    CHECK(direct.expiresAt.toSecsSinceEpoch() == 1900000000);
    qInfo("PASS: WBI published vector, search mapping/pagination, challenge handling, audio selection and safe descriptors");
}
