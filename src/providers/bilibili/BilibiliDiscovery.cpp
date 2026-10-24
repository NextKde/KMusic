#include "BilibiliDiscovery.h"
#include "BilibiliResponse.h"
#include "../contracts/Operation.h"
#include <QJsonArray>
#include <QRegularExpression>
#include <QTimer>
namespace MusicProviders {
Request *BilibiliDiscovery::page(const SourceScope &scope, const QString &section, const QString &cursor, QObject *context, Completion<Page<MediaItem>> done) {
    if (section == "following") return m_following.page(scope, cursor, context, std::move(done));
    bool ok = true; const int batch = cursor.isEmpty() ? 1 : cursor.toInt(&ok);
    if (scope != SourceScope{"bilibili", {}, {}} || !ok || batch < 1 || batch > 100
        || (section != "newSongs" && section != "recommendations" && section != "popular")
        || (section != "recommendations" && !cursor.isEmpty())) {
        auto op = Operation<Page<MediaItem>>::create(context, std::move(done));
        QTimer::singleShot(0, op->handle, [op] { op->finish(Error{ErrorCode::InvalidRequest, QStringLiteral("Invalid discovery request.")}); }); return op->handle;
    }
    auto complete = [section, cursor, done](Result<QByteArray> result) {
        if (auto error = std::get_if<Error>(&result)) done(*error); else done(decode(section, std::get<QByteArray>(result), cursor));
    };
    if (section == "recommendations") return m_public.signedGet("/x/web-interface/region/feed/rcmd",
        {{"from_region", "1003"}, {"display_id", QString::number(batch)}, {"request_cnt", "15"}, {"device", "web"}, {"plat", "30"}}, context, complete);
    return m_public.get(section == "newSongs" ? "/x/centralization/interface/new/music" : "/x/centralization/interface/music/comprehensive/web/rank", {}, context, complete);
}
Result<Page<MediaItem>> BilibiliDiscovery::decode(const QString &section, const QByteArray &bytes, const QString &cursor) {
    const auto result = biliData(bytes); if (auto error = std::get_if<Error>(&result)) return *error;
    const auto data = std::get<QJsonObject>(result); const QString key = section == "recommendations" ? "archives" : "list";
    if ((section != "newSongs" && section != "popular" && section != "recommendations") || !data.value(key).isArray())
        return Error{ErrorCode::InvalidResponse, QStringLiteral("Invalid Bilibili discovery response.")};
    Page<MediaItem> page; const auto raw = data.value(key).toArray();
    static const QRegularExpression bv("^BV[0-9A-Za-z]{10}$");
    for (const auto &value : raw) {
        const auto row = value.toObject();
        // Rank's related archive is the playable video, not its separate music id.
        const auto video = section == "popular" ? row.value("related_archive").toObject() : row;
        const auto id = video.value("bvid").toString(); if (!bv.match(id).hasMatch()) continue;
        const auto title = section == "newSongs" ? row.value("music_title").toString() : video.value("title").toString();
        if (title.isEmpty()) continue;
        QString cover = video.value("cover").toString(); if (cover.startsWith("//")) cover.prepend("https:");
        QUrl image(cover); if (image.scheme() != "https" && image.scheme() != "http") image = QUrl{};
        const auto cid = video.value("cid").toVariant().toLongLong();
        const auto creator = section == "recommendations" ? video.value("author").toObject().value("name").toString()
            : section == "popular" ? video.value("username").toString() : row.value("author").toString();
        page.items.append({{{"bilibili", {}, {}}, id, cid > 0 ? QString::number(cid) : QString{}}, title, creator, image, video.value("duration").toVariant().toLongLong() * 1000});
    }
    const int batch = cursor.isEmpty() ? 1 : cursor.toInt();
    if (section == "recommendations" && raw.size() >= 15 && batch < 100) page.nextCursor = QString::number(batch + 1);
    return page;
}
}
