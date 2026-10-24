#include "BilibiliLibrary.h"
#include "BilibiliResponse.h"
#include "../contracts/Operation.h"
#include <QJsonArray>
#include <QJsonDocument>
#include <QRegularExpression>
#include <QTimer>
namespace MusicProviders {
namespace {
bool validScope(const SourceScope &s) { return s.provider == "bilibili" && s.instance.isEmpty() && s.account.toULongLong() > 0; }
bool validBv(const QString &s) { static const QRegularExpression re("^BV[0-9A-Za-z]{10}$"); return re.match(s).hasMatch(); }
QUrl artwork(QString s) { if (s.startsWith("//")) s.prepend("https:"); QUrl u(s); return (u.scheme() == "https" || u.scheme() == "http") && u.userInfo().isEmpty() ? u : QUrl{}; }
Error invalid() { return {ErrorCode::InvalidResponse, QStringLiteral("Bilibili library response is incomplete.")}; }
}
Request *BilibiliLibrary::fetch(const SourceScope &scope, const QString &path, const QUrlQuery &query,
                               QObject *context, Completion<QByteArray> done) {
    if (!validScope(scope) || scope != m_scope || !m_session.hasSession()) {
        auto op = Operation<QByteArray>::create(context, done); QTimer::singleShot(0, op->handle, [op] { op->finish(Error{ErrorCode::AuthenticationRequired, QStringLiteral("Sign in to Bilibili first.")}); }); return op->handle;
    }
    return m_session.get(BilibiliSession::Origin::Api, path, query, context, [this, scope, done](Result<QByteArray> result) {
        if (scope != m_scope) done(Error{ErrorCode::Cancelled, QStringLiteral("Account changed.")}); else done(std::move(result));
    });
}
Request *BilibiliLibrary::list(const SourceScope &scope, LibraryKind kind, const PageRequest &page,
                              QObject *context, Completion<Page<LibraryEntry>> done) {
    if (kind != LibraryKind::History) {
        return fetch(scope, "/x/v3/fav/folder/created/list-all", {{"up_mid", scope.account}}, context,
            [scope, done](Result<QByteArray> r) { if (auto e = std::get_if<Error>(&r)) done(*e); else done(decodeFolders(scope, std::get<QByteArray>(r))); });
    }
    QUrlQuery query{{"ps", QString::number(qBound(1, page.limit, 30))}, {"type", "archive"}};
    if (!page.cursor.isEmpty()) {
        const auto cursor = QJsonDocument::fromJson(QByteArray::fromBase64(page.cursor.toLatin1(), QByteArray::Base64UrlEncoding)).object();
        if (cursor.value("max").toVariant().toLongLong() <= 0 || cursor.value("view_at").toVariant().toLongLong() <= 0) {
            auto op = Operation<Page<LibraryEntry>>::create(context, done); QTimer::singleShot(0, op->handle, [op] { op->finish(Error{ErrorCode::InvalidRequest, QStringLiteral("Invalid history cursor.")}); }); return op->handle;
        }
        query.addQueryItem("business", cursor.value("business").toString());
        query.addQueryItem("max", QString::number(cursor.value("max").toVariant().toLongLong()));
        query.addQueryItem("view_at", QString::number(cursor.value("view_at").toVariant().toLongLong()));
    }
    return fetch(scope, "/x/web-interface/history/cursor", query, context, [scope, page, done](Result<QByteArray> r) {
        if (auto e = std::get_if<Error>(&r)) done(*e); else done(decodeHistory(scope, std::get<QByteArray>(r), page.cursor));
    });
}
Request *BilibiliLibrary::folder(const SourceScope &scope, const QString &id, const PageRequest &page,
                                QObject *context, Completion<Page<LibraryEntry>> done) {
    bool ok = false; const auto folderId = id.toLongLong(&ok); const int pn = page.cursor.isEmpty() ? 1 : page.cursor.toInt();
    if (!ok || folderId <= 0 || pn < 1) {
        auto op = Operation<Page<LibraryEntry>>::create(context, done); QTimer::singleShot(0, op->handle, [op] { op->finish(Error{ErrorCode::InvalidRequest, QStringLiteral("Invalid favorites folder.")}); }); return op->handle;
    }
    return fetch(scope, "/x/v3/fav/resource/list", {{"media_id", id}, {"pn", QString::number(pn)},
        {"ps", "20"}, {"order", "mtime"}, {"type", "0"}}, context, [scope, pn, done](Result<QByteArray> r) {
            if (auto e = std::get_if<Error>(&r)) done(*e); else done(decodeFolder(scope, std::get<QByteArray>(r), pn));
        });
}
Result<Page<LibraryEntry>> BilibiliLibrary::decodeFolders(const SourceScope &scope, const QByteArray &body) {
    if (!validScope(scope)) return Error{ErrorCode::InvalidRequest, QStringLiteral("Invalid account scope.")};
    const auto decoded = biliData(body); if (auto e = std::get_if<Error>(&decoded)) return *e;
    const auto data = std::get<QJsonObject>(decoded);
    if (!data.value("list").isArray() && data.value("count").toInt(-1) != 0) return invalid();
    Page<LibraryEntry> result;
    for (const auto &v : data.value("list").toArray()) {
        const auto row = v.toObject(); const auto id = row.value("id").toVariant().toLongLong();
        if (id <= 0 || row.value("title").toString().isEmpty()) return invalid();
        result.items.append(Collection{scope, QString::number(id), row.value("title").toString(), artwork(row.value("cover").toString())});
    }
    return result;
}
Result<Page<LibraryEntry>> BilibiliLibrary::decodeFolder(const SourceScope &scope, const QByteArray &body, int page) {
    if (!validScope(scope)) return Error{ErrorCode::InvalidRequest, QStringLiteral("Invalid account scope.")};
    const auto decoded = biliData(body); if (auto e = std::get_if<Error>(&decoded)) return *e;
    const auto data = std::get<QJsonObject>(decoded);
    if (!data.value("info").isObject() || !data.value("has_more").isBool()
        || (!data.value("medias").isArray() && data.value("info").toObject().value("media_count").toInt(-1) != 0)) return invalid();
    const auto raw = data.value("medias").toArray(); Page<LibraryEntry> result;
    if (data.value("has_more").toBool()) { if (raw.isEmpty()) return invalid(); result.nextCursor = QString::number(page + 1); }
    for (const auto &v : raw) {
        const auto row = v.toObject(); const auto bv = row.value("bvid").toString();
        if (!validBv(bv) || row.value("type").toInt() != 2) continue;
        result.items.append(MediaItem{{scope, bv, {}}, row.value("title").toString(), row.value("upper").toObject().value("name").toString(),
            artwork(row.value("cover").toString()), row.value("duration").toVariant().toLongLong() * 1000});
    }
    return result;
}
Result<Page<LibraryEntry>> BilibiliLibrary::decodeHistory(const SourceScope &scope, const QByteArray &body, const QString &oldCursor) {
    if (!validScope(scope)) return Error{ErrorCode::InvalidRequest, QStringLiteral("Invalid account scope.")};
    const auto decoded = biliData(body); if (auto e = std::get_if<Error>(&decoded)) return *e;
    const auto data = std::get<QJsonObject>(decoded);
    if (!data.value("list").isArray() || !data.value("cursor").isObject()) return invalid();
    const auto raw = data.value("list").toArray(); Page<LibraryEntry> result;
    for (const auto &v : raw) {
        const auto row = v.toObject(), history = row.value("history").toObject(); const auto bv = history.value("bvid").toString();
        if (!validBv(bv) || history.value("business").toString() != "archive") continue;
        const auto cid = history.value("cid").toVariant().toLongLong();
        result.items.append(MediaItem{{scope, bv, cid > 0 ? QString::number(cid) : QString{}}, row.value("title").toString(),
            row.value("author_name").toString(), artwork(row.value("cover").toString()), row.value("duration").toVariant().toLongLong() * 1000});
    }
    const auto cursor = data.value("cursor").toObject();
    if (!raw.isEmpty() && cursor.value("max").toVariant().toLongLong() > 0 && cursor.value("view_at").toVariant().toLongLong() > 0) {
        const QJsonObject token{{"max", cursor.value("max")}, {"view_at", cursor.value("view_at")}, {"business", cursor.value("business")}};
        result.nextCursor = QString::fromLatin1(QJsonDocument(token).toJson(QJsonDocument::Compact).toBase64(QByteArray::Base64UrlEncoding | QByteArray::OmitTrailingEquals));
        if (result.nextCursor == oldCursor) return invalid();
    }
    return result;
}
}
