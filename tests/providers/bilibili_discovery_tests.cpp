#include "bilibili/BilibiliDiscovery.h"
#include "bilibili/BilibiliPlaybackResolver.h"
#include "BilibiliFeedState.h"
#include <QCoreApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTest>
using namespace MusicProviders;
#define CHECK(c) do { if (!(c)) qFatal("Failed line %d: %s", __LINE__, #c); } while (false)
static QByteArray body(QJsonObject data) { return QJsonDocument(QJsonObject{{"code", 0}, {"data", data}}).toJson(); }
int main(int argc, char **argv) {
    QCoreApplication app(argc, argv);
    BilibiliSession session; BilibiliDiscovery provider(session); QObject context;
    const SourceScope publicScope{"bilibili", {}, {}}, account{"bilibili", {}, "123"};
    if (app.arguments().contains("--live")) {
        bool all = true; MediaId first; Page<MediaItem> recommendations;
        for (const auto &section : {"newSongs", "popular", "recommendations"}) {
            bool completed = false;
            auto *request = provider.page(publicScope, section, {}, &context, [&](auto result) {
                if (auto page = std::get_if<Page<MediaItem>>(&result)) {
                    qInfo("LIVE discovery %s count=%lld more=%d", section, static_cast<long long>(page->items.size()), !page->nextCursor.isEmpty());
                    if (QString(section) == "recommendations") recommendations = *page;
                    if (QString(section) == "newSongs" && !page->items.isEmpty()) first = page->items.first().id;
                } else { all = false; qInfo("LIVE discovery %s errorCategory=%d", section, static_cast<int>(std::get<Error>(result).code)); }
                completed = true;
            });
            if (!QTest::qWaitFor([&] { return completed; }, 35000)) { all = false; qInfo("LIVE discovery timeout"); }
            delete request;
        }
        if (!recommendations.nextCursor.isEmpty()) {
            bool completed = false; BilibiliFeedState state;
            state.accept(state.epoch, recommendations, {}, true);
            auto *request = provider.page(publicScope, "recommendations", recommendations.nextCursor, &context, [&](auto result) {
                if (auto page = std::get_if<Page<MediaItem>>(&result)) {
                    const bool accepted = state.accept(state.epoch, *page, recommendations.nextCursor, true);
                    all &= accepted;
                    qInfo("LIVE recommendation next batch=%lld distinctLoaded=%lld more=%d accepted=%d", static_cast<long long>(page->items.size()), static_cast<long long>(state.items.size()), !state.next.isEmpty(), accepted);
                } else { all = false; qInfo("LIVE recommendation next batch failed errorCategory=%d", static_cast<int>(std::get<Error>(result).code)); }
                completed = true;
            });
            if (!QTest::qWaitFor([&] { return completed; }, 35000)) all = false;
            delete request;
        }
        qInfo("LIVE public feed requests successful=%d", all);
        if (!first.item.isEmpty()) {
            bool completed = false; BilibiliPlaybackResolver resolver;
            auto *request = resolver.resolve(first, "AAC", &context, [&](auto result) {
                const bool resolved = std::holds_alternative<PlaybackSource>(result);
                if (!resolved) all = false;
                qInfo("LIVE discovery first-new-song resolve=%d errorCategory=%d (stream URL omitted)", resolved, resolved ? -1 : static_cast<int>(std::get<Error>(result).code));
                completed = true;
            });
            if (!QTest::qWaitFor([&] { return completed; }, 65000)) { all = false; qInfo("LIVE first-new-song resolution timed out"); }
            delete request;
        }
        else { all = false; qInfo("LIVE no new-song candidate to resolve"); }
        return all ? 0 : 1;
    }
    auto fresh = QJsonObject{{"bvid", "BV1234567890"}, {"cid", ""}, {"music_title", "New song"}, {"author", "Composer"}, {"cover", "//example.test/cover"}};
    auto page = std::get<Page<MediaItem>>(BilibiliDiscovery::decode("newSongs", body({{"list", QJsonArray{fresh}}})));
    CHECK(page.items.size() == 1 && page.items.first().id.part.isEmpty() && page.items.first().title == "New song");
    CHECK(page.items.first().id.scope == publicScope && page.items.first().artwork.scheme() == "https");
    auto related = QJsonObject{{"bvid", "BV0987654321"}, {"cid", "321"}, {"title", "Actual video"}, {"username", "Uploader"}, {"duration", 90}};
    fresh.insert("related_archive", related);
    auto rank = std::get<Page<MediaItem>>(BilibiliDiscovery::decode("popular", body({{"list", QJsonArray{fresh}}})));
    CHECK(rank.items.first().id.item == "BV0987654321" && rank.items.first().id.part == "321" && rank.items.first().title == "Actual video");
    CHECK(std::get<Page<MediaItem>>(BilibiliDiscovery::decode("popular", body({{"list", QJsonArray{}}}))).items.isEmpty());
    CHECK(std::holds_alternative<Error>(BilibiliDiscovery::decode("popular", body({}))));
    CHECK(std::get<Error>(BilibiliDiscovery::decode("newSongs", "{\"code\":-412}")).code == ErrorCode::VerificationRequired);
    related.insert("author", QJsonObject{{"name", "Uploader"}}); QJsonArray many; for (int i = 0; i < 15; ++i) many.append(related);
    auto recommendation = std::get<Page<MediaItem>>(BilibiliDiscovery::decode("recommendations", body({{"archives", many}})));
    CHECK(recommendation.nextCursor == "2");
    auto archive = QJsonObject{{"bvid", "BV1234567890"}, {"title", "Following video"}, {"duration_text", "03:20"}};
    auto event = QJsonObject{{"type", "DYNAMIC_TYPE_AV"}, {"visible", true}, {"modules", QJsonObject{
        {"module_author", QJsonObject{{"name", "Followed creator"}}},
        {"module_dynamic", QJsonObject{{"major", QJsonObject{{"type", "MAJOR_TYPE_ARCHIVE"}, {"archive", archive}}}}}}}};
    auto followingBody = body({{"items", QJsonArray{event}}, {"has_more", true}, {"offset", "next-offset"}});
    auto following = std::get<Page<MediaItem>>(BilibiliFollowing::decode(account, followingBody));
    CHECK(following.items.first().id.scope == account && following.items.first().durationMs == 200000 && following.nextCursor == "next-offset");
    CHECK(std::holds_alternative<Error>(BilibiliFollowing::decode(account, followingBody, "next-offset")));
    CHECK(std::get<Page<MediaItem>>(BilibiliFollowing::decode(account, body({{"items", QJsonArray{}}, {"has_more", false}}))).items.isEmpty());
    CHECK(std::get<Error>(BilibiliFollowing::decode(account, "{\"code\":-101}")).code == ErrorCode::AuthenticationRequired);
    event.insert("type", "DYNAMIC_TYPE_DRAW");
    CHECK(std::get<Page<MediaItem>>(BilibiliFollowing::decode(account, body({{"items", QJsonArray{event}}, {"has_more", true}, {"offset", "other-offset"}}))).items.isEmpty());
    int calls = 0; ErrorCode cancelled = ErrorCode::InvalidRequest;
    auto *request = provider.page(publicScope, "unknown", {}, &context, [&](auto r) { ++calls; cancelled = std::get<Error>(r).code; });
    request->cancel(); QCoreApplication::processEvents(); CHECK(calls == 1 && cancelled == ErrorCode::Cancelled);
    BilibiliFollowing privateProvider(session); privateProvider.setAccount(account); calls = 0;
    privateProvider.page(account, {}, &context, [&](auto r) { ++calls; cancelled = std::get<Error>(r).code; });
    privateProvider.setAccount({"bilibili", {}, "456"}); QCoreApplication::processEvents(); CHECK(calls == 1 && cancelled == ErrorCode::Cancelled);
    const auto synthetic = QJsonDocument(QJsonArray{QString::fromLatin1(QByteArray("SESSDATA=fixture; domain=.bilibili.com; path=/; secure").toBase64())}).toJson();
    CHECK(session.restore(synthetic)); CHECK(session.hasSession());
    bool denied = false;
    privateProvider.page(account, {}, &context, [&](auto r) { denied = std::get<Error>(r).code == ErrorCode::AuthenticationRequired; });
    CHECK(QTest::qWaitFor([&] { return denied; }, 1000));
    bool destroyedCallback = false;
    {
        BilibiliFollowing temporary(session); temporary.setAccount(account);
        temporary.page({"bilibili", {}, "wrong-account"}, {}, &context, [&](auto) { destroyedCallback = true; });
    }
    QCoreApplication::processEvents(); CHECK(!destroyedCallback);
    BilibiliFeedState state; auto epoch = state.epoch;
    CHECK(state.accept(epoch, recommendation, {}, true)); CHECK(state.items.size() == 1 && state.next == "2");
    CHECK(state.accept(epoch, recommendation, "2", true) == false); // Server cursor did not advance.
    auto second = recommendation; second.nextCursor = "3";
    CHECK(state.accept(epoch, second, "2", true)); CHECK(state.items.size() == 1 && state.next.isEmpty());
    state.clear(); CHECK(state.items.isEmpty());
    CHECK(!state.accept(epoch, following, {}, false)); CHECK(state.items.isEmpty()); // Late old-account response.
    CHECK(state.accept(state.epoch, following, {}, false));
    auto third = following; third.nextCursor = "fourth";
    CHECK(state.accept(state.epoch, third, "next-offset", false));
    auto cycle = following; cycle.nextCursor = "next-offset";
    CHECK(!state.accept(state.epoch, cycle, "fourth", false)); CHECK(state.items.size() == 1);
    qInfo("PASS: discovery mapping, empty/errors, cancellation, account isolation, cursors and deduplication; no real account used");
}
