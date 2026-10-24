#include "BilibiliApi.h"
#include "WbiSigner.h"
#include "../contracts/Operation.h"
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <QFileInfo>
namespace MusicProviders {
HttpIdentity BilibiliApi::identity() {
    return {QByteArrayLiteral("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"), QUrl("https://www.bilibili.com/")};
}
BilibiliApi::BilibiliApi(QObject *parent) : QObject(parent), m_http(QUrl("https://api.bilibili.com"), identity(), this) {}
Request *BilibiliApi::get(const QString &path, const QUrlQuery &query, QObject *context, Completion<QByteArray> done) {
    return m_http.get(path, query, context, std::move(done));
}
Request *BilibiliApi::signedGet(const QString &path, const QMap<QString, QString> &params, QObject *context, Completion<QByteArray> done) {
    auto op = Operation<QByteArray>::create(context, std::move(done));
    op->child = get("/x/web-interface/nav", {}, op->handle, [this, op, path, params](Result<QByteArray> result) {
        if (op->finished) return;
        if (auto error = std::get_if<Error>(&result)) { op->finish(*error); return; }
        const auto root = QJsonDocument::fromJson(std::get<QByteArray>(result)).object();
        // Anonymous nav returns -101 but still supplies public signing keys.
        const auto keys = root.value("data").toObject().value("wbi_img").toObject();
        auto query = WbiSigner::sign(params,
            QFileInfo(QUrl(keys.value("img_url").toString()).path()).completeBaseName(),
            QFileInfo(QUrl(keys.value("sub_url").toString()).path()).completeBaseName(),
            QDateTime::currentSecsSinceEpoch());
        if (auto error = std::get_if<Error>(&query)) { op->finish(*error); return; }
        op->child = get(path, std::get<QUrlQuery>(query), op->handle, [op](Result<QByteArray> response) { op->finish(std::move(response)); });
    });
    return op->handle;
}
}
