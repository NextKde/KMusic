#pragma once
#include "../HttpTransport.h"
#include <QMap>
namespace MusicProviders {
class BilibiliApi final : public QObject {
public:
    explicit BilibiliApi(QObject *parent = nullptr);
    Request *get(const QString &, const QUrlQuery &, QObject *, Completion<QByteArray>);
    Request *signedGet(const QString &, const QMap<QString, QString> &, QObject *, Completion<QByteArray>);
    static HttpIdentity identity();
private:
    HttpTransport m_http;
};
}
