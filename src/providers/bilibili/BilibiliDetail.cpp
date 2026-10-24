#include "BilibiliDetail.h"
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QTimer>

namespace MusicProviders {
namespace {
bool validId(const MediaId &id)
{
    static const QRegularExpression bv(QStringLiteral("^BV[0-9A-Za-z]{10}$"));
    return id.scope.provider == "bilibili" && id.scope.instance.isEmpty()
        && bv.match(id.item).hasMatch();
}
}
BilibiliDetail::BilibiliDetail(QObject *parent, BilibiliSession *session) : QObject(parent), m_transport(this, session) {}

Request *BilibiliDetail::detail(const MediaId &id, QObject *context, Completion<MediaDetail> done)
{
    if (!validId(id)) {
        // Use transport's queued InvalidRequest path to retain cancellation semantics.
        return m_transport.get({}, {}, context, [done](Result<QByteArray> result) {
            done(std::get<Error>(result));
        });
    }
    return m_transport.get(QStringLiteral("/x/web-interface/view"),
        QUrlQuery{{QStringLiteral("bvid"), id.item}}, context,
        [id, done](Result<QByteArray> result) {
            if (const auto *error = std::get_if<Error>(&result)) done(*error);
            else done(decode(id, std::get<QByteArray>(result)));
        });
}
Result<MediaDetail> BilibiliDetail::decode(const MediaId &id, const QByteArray &body)
{
    if (!validId(id)) return Error{ErrorCode::InvalidRequest, QStringLiteral("Invalid Bilibili video identity.")};
    const auto document = QJsonDocument::fromJson(body);
    const auto root = document.object();
    if (!document.isObject() || !root.value("code").isDouble())
        return Error{ErrorCode::InvalidResponse, QStringLiteral("Invalid video response.")};
    const int code = root.value("code").toInt();
    if (code != 0) {
        if (code == -101) return Error{ErrorCode::AuthenticationRequired, QStringLiteral("Please sign in to Bilibili.")};
        if (code == -352) return Error{ErrorCode::VerificationRequired, QStringLiteral("Bilibili verification is required.")};
        return Error{ErrorCode::Unavailable, QStringLiteral("This video is unavailable.")};
    }
    const auto data = root.value("data").toObject();
    MediaDetail detail;
    detail.item = {id, data.value("title").toString(),
        data.value("owner").toObject().value("name").toString(),
        QUrl(data.value("pic").toString()), qint64(data.value("duration").toDouble() * 1000)};
    detail.item.id.part.clear();
    if (data.value("bvid").toString() != id.item || detail.item.title.isEmpty())
        return Error{ErrorCode::InvalidResponse, QStringLiteral("Video identity or title is missing.")};
    for (const auto &value : data.value("pages").toArray()) {
        const auto page = value.toObject();
        const qint64 cid = qint64(page.value("cid").toDouble());
        if (cid <= 0) return Error{ErrorCode::InvalidResponse, QStringLiteral("Video part identity is missing.")};
        auto part = detail.item;
        part.id.part = QString::number(cid);
        part.title = page.value("part").toString();
        part.durationMs = qint64(page.value("duration").toDouble() * 1000);
        detail.parts.append(part);
    }
    if (detail.parts.isEmpty())
        return Error{ErrorCode::InvalidResponse, QStringLiteral("Video contains no playable parts.")};
    if (!id.part.isEmpty()) {
        bool found = false;
        for (const auto &part : detail.parts) found |= part.id.part == id.part;
        if (!found) return Error{ErrorCode::Unavailable, QStringLiteral("Requested video part is unavailable.")};
    }
    return detail;
}
}
