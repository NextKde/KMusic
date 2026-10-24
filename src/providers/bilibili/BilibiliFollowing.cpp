#include "BilibiliFollowing.h"
#include "BilibiliResponse.h"
#include "../contracts/Operation.h"
#include <QJsonArray>
#include <QRegularExpression>
#include <QTimer>
namespace MusicProviders {
BilibiliFollowing::~BilibiliFollowing() {
    // Destroy handles rather than completing callbacks into owners during teardown.
    ++m_epoch;
    const auto active = m_active; m_active.clear();
    for (auto request : active) delete request;
}
void BilibiliFollowing::setAccount(const SourceScope &scope) {
    m_scope = scope; ++m_epoch;
    const auto active = m_active; m_active.clear();
    for (auto request : active) if (request) request->cancel();
}
Request *BilibiliFollowing::page(const SourceScope &scope, const QString &cursor, QObject *context, Completion<Page<MediaItem>> done) {
    auto op = Operation<Page<MediaItem>>::create(context, std::move(done));
    const auto epoch = m_epoch;
    m_active.removeIf([](auto p) { return p.isNull(); }); m_active.append(op->handle);
    if (scope.provider != "bilibili" || !scope.instance.isEmpty() || scope.account.isEmpty()
        || scope != m_scope || !m_session.hasSession() || cursor.size() > 256) {
        QTimer::singleShot(0, op->handle, [op, this, epoch] {
            op->finish(Error{epoch == m_epoch ? ErrorCode::AuthenticationRequired : ErrorCode::Cancelled, QStringLiteral("Bilibili sign-in is required.")});
        }); return op->handle;
    }
    QUrlQuery query{{"type", "video"}, {"platform", "web"}};
    if (!cursor.isEmpty()) query.addQueryItem("offset", cursor);
    op->child = m_session.get(BilibiliSession::Origin::Api, "/x/polymer/web-dynamic/v1/feed/all", query, op->handle,
        [this, scope, cursor, epoch, op](Result<QByteArray> result) {
            m_active.removeAll(op->handle);
            if (epoch != m_epoch || scope != m_scope) { op->finish(Error{ErrorCode::Cancelled, QStringLiteral("Account changed.")}); return; }
            if (auto error = std::get_if<Error>(&result)) op->finish(*error);
            else op->finish(decode(scope, std::get<QByteArray>(result), cursor));
        });
    return op->handle;
}
Result<Page<MediaItem>> BilibiliFollowing::decode(const SourceScope &scope, const QByteArray &bytes, const QString &oldCursor) {
    const auto decoded = biliData(bytes);
    if (auto error = std::get_if<Error>(&decoded)) return *error;
    const auto data = std::get<QJsonObject>(decoded);
    if (scope.provider != "bilibili" || scope.account.isEmpty() || !scope.instance.isEmpty()
        || !data.value("items").isArray() || !data.value("has_more").isBool())
        return Error{ErrorCode::InvalidResponse, QStringLiteral("Invalid Bilibili following updates.")};
    Page<MediaItem> page;
    const auto raw = data.value("items").toArray();
    static const QRegularExpression bv("^BV[0-9A-Za-z]{10}$");
    for (const auto &value : raw) {
        const auto row = value.toObject(), modules = row.value("modules").toObject();
        const auto major = modules.value("module_dynamic").toObject().value("major").toObject();
        if (row.value("type") != "DYNAMIC_TYPE_AV" || major.value("type") != "MAJOR_TYPE_ARCHIVE" || row.value("visible") == false) continue;
        const auto video = major.value("archive").toObject(); const auto id = video.value("bvid").toString();
        if (!bv.match(id).hasMatch() || video.value("title").toString().isEmpty()) continue;
        QString cover = video.value("cover").toString(); if (cover.startsWith("//")) cover.prepend("https:");
        QUrl image(cover); if (image.scheme() != "https" && image.scheme() != "http") image = QUrl{};
        qint64 seconds = 0; for (const auto &part : video.value("duration_text").toString().split(':')) seconds = seconds * 60 + part.toInt();
        page.items.append({{scope, id, {}}, video.value("title").toString(), modules.value("module_author").toObject().value("name").toString(), image, seconds * 1000});
    }
    if (data.value("has_more").toBool()) {
        page.nextCursor = data.value("offset").toString();
        if (page.nextCursor.isEmpty() || page.nextCursor == oldCursor || page.nextCursor.size() > 256 || raw.isEmpty())
            return Error{ErrorCode::InvalidResponse, QStringLiteral("Bilibili following cursor did not advance.")};
    }
    return page;
}
}
