#include "BilibiliPlaybackResolver.h"
#include "BilibiliResponse.h"
#include "../contracts/Operation.h"
#include <QJsonArray>
namespace MusicProviders {
Request *BilibiliPlaybackResolver::resolve(const MediaId &id, const QString &, QObject *context, Completion<PlaybackSource> done) {
    auto op = Operation<PlaybackSource>::create(context, std::move(done));
    op->child = m_detail.detail(id, op->handle, [this, op, id](Result<MediaDetail> result) {
        if (op->finished) return;
        if (auto error = std::get_if<Error>(&result)) { op->finish(*error); return; }
        auto resolvedId = id;
        if (resolvedId.part.isEmpty()) resolvedId.part = std::get<MediaDetail>(result).parts.first().id.part;
        op->child = m_api.signedGet("/x/player/wbi/playurl", {{"bvid", id.item}, {"cid", resolvedId.part},
            {"fnval", "16"}, {"fnver", "0"}, {"fourk", "0"}}, op->handle,
            [op, resolvedId](Result<QByteArray> response) {
                if (auto error = std::get_if<Error>(&response)) op->finish(*error);
                else op->finish(decode(resolvedId, std::get<QByteArray>(response)));
            });
    });
    return op->handle;
}
Result<PlaybackSource> BilibiliPlaybackResolver::decode(const MediaId &id, const QByteArray &body) {
    auto parsed = biliData(body);
    if (auto error = std::get_if<Error>(&parsed)) return *error;
    const auto data = std::get<QJsonObject>(parsed);
    if (data.value("is_preview").toInt() == 1)
        return Error{ErrorCode::Unavailable, QStringLiteral("Bilibili offers only a preview for this video.")};
    QJsonObject chosen;
    for (auto value : data.value("dash").toObject().value("audio").toArray()) {
        const auto audio = value.toObject();
        // AAC ordinary audio only; do not request premium Dolby/FLAC entitlements.
        if (!audio.value("codecs").toString().startsWith("mp4a")) continue;
        if (chosen.isEmpty() || audio.value("bandwidth").toInt() > chosen.value("bandwidth").toInt()) chosen = audio;
    }
    auto urlOf = [](const QJsonObject &o) { return QUrl(o.value("baseUrl").toString(o.value("base_url").toString())); };
    const QUrl url = urlOf(chosen);
    if (url.scheme() != "https" || url.host().isEmpty() || !url.userInfo().isEmpty())
        return Error{ErrorCode::Unavailable, QStringLiteral("No supported Bilibili audio stream is available.")};
    PlaybackSource source;
    source.id = id; source.url = url; source.quality = QStringLiteral("AAC");
    source.userAgent = BilibiliApi::identity().userAgent; source.referer = QUrl("https://www.bilibili.com/");
    const auto backups = chosen.value("backupUrl").toArray(chosen.value("backup_url").toArray());
    for (auto value : backups) {
        QUrl backup(value.toString());
        if (backup.scheme() == "https" && !backup.host().isEmpty() && backup.userInfo().isEmpty()) source.backups.append(backup);
    }
    bool ok = false;
    const qint64 deadline = QUrlQuery(url).queryItemValue("deadline").toLongLong(&ok);
    if (ok) source.expiresAt = QDateTime::fromSecsSinceEpoch(deadline);
    return source;
}
}
