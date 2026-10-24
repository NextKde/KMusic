#include "BilibiliSearch.h"
#include "BilibiliResponse.h"
#include <QJsonArray>
#include <QRegularExpression>
namespace MusicProviders {
Request *BilibiliSearch::search(const SourceScope &scope, const QString &text, const PageRequest &page, QObject *context, Completion<Page<MediaItem>> done) {
    bool ok = true;
    const int number = page.cursor.isEmpty() ? 1 : page.cursor.toInt(&ok);
    if (scope.provider != "bilibili" || !scope.instance.isEmpty() || !scope.account.isEmpty()
        || text.trimmed().isEmpty() || text.size() > 200 || !ok || number < 1 || number > 1000) {
        return m_api.get({}, {}, context, [done](Result<QByteArray> result) { done(std::get<Error>(result)); });
    }
    return m_api.signedGet("/x/web-interface/wbi/search/type", {{"search_type", "video"},
        {"keyword", text.trimmed()}, {"page", QString::number(number)}, {"page_size", "20"}}, context,
        [scope, done](Result<QByteArray> result) {
            if (auto error = std::get_if<Error>(&result)) done(*error);
            else done(decode(scope, std::get<QByteArray>(result)));
        });
}
Result<Page<MediaItem>> BilibiliSearch::decode(const SourceScope &scope, const QByteArray &body) {
    auto result = biliData(body);
    if (auto error = std::get_if<Error>(&result)) return *error;
    const auto data = std::get<QJsonObject>(result);
    if (!data.value("result").isArray()) return Error{ErrorCode::InvalidResponse, QStringLiteral("Invalid Bilibili search results.")};
    Page<MediaItem> page;
    static const QRegularExpression bv("^BV[0-9A-Za-z]{10}$"), tags("<[^>]*>");
    for (auto value : data.value("result").toArray()) {
        const auto row = value.toObject();
        const QString bvid = row.value("bvid").toString();
        if (!bv.match(bvid).hasMatch()) continue;
        QString title = row.value("title").toString(); title.remove(tags);
        title.replace("&quot;", "\"").replace("&#39;", "'").replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&");
        QString cover = row.value("pic").toString(); if (cover.startsWith("//")) cover.prepend("https:");
        qint64 seconds = 0;
        for (const auto &part : row.value("duration").toString().split(':')) seconds = seconds * 60 + part.toInt();
        page.items.append({{scope, bvid, {}}, title, row.value("author").toString(), QUrl(cover), seconds * 1000});
    }
    const int current = data.value("page").toInt(1);
    if (current < data.value("numPages").toInt() && !page.items.isEmpty()) page.nextCursor = QString::number(current + 1);
    return page;
}
}
