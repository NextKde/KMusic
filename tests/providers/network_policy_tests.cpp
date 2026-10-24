#include "NetworkAccessManager.h"
#include "HttpTransport.h"
#include "MusicNetworkAccessManagerFactory.h"
#include <QCoreApplication>
#include <QQmlEngine>
#include <QTcpServer>
#include <QTcpSocket>
#include <QNetworkReply>
#include <QSslConfiguration>
#include <QTest>
#include <QSignalSpy>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
using namespace MusicProviders;
#define CHECK(c) do { if (!(c)) qFatal("Failed line %d: %s", __LINE__, #c); } while (false)
static bool policy(const QNetworkRequest &r) {
    return r.attribute(QNetworkRequest::Http2AllowedAttribute).isValid()
        && !r.attribute(QNetworkRequest::Http2AllowedAttribute).toBool()
        && !r.attribute(QNetworkRequest::Http2DirectAttribute).toBool();
}
int main(int argc, char **argv) {
    QCoreApplication app(argc, argv);
    MusicNetworkAccessManagerFactory factory;
    QQmlEngine engine; engine.setNetworkAccessManagerFactory(&factory);
    auto *qml = engine.networkAccessManager();
    NetworkAccessManager native;
    if (app.arguments().contains("--live")) {
        auto fetch = [&](QNetworkAccessManager &manager, const QUrl &url, const char *label, QByteArray *body = nullptr) {
            QNetworkRequest request(url); request.setTransferTimeout(15000);
            request.setRawHeader("User-Agent", "Mozilla/5.0 KMusic"); request.setRawHeader("Referer", "https://www.bilibili.com/");
            auto *reply = manager.get(request); QSignalSpy done(reply, &QNetworkReply::finished);
            const bool received = done.wait(20000);
            const bool h2 = reply->attribute(QNetworkRequest::Http2WasUsedAttribute).toBool();
            const bool ok = received && reply->error() == QNetworkReply::NoError && !h2 && policy(reply->request());
            if (body && ok) *body = reply->readAll();
            qInfo("LIVE %s completed=%d httpStatus=%d http2Used=%d policyApplied=%d success=%d", label, received,
                reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt(), h2, policy(reply->request()), ok);
            delete reply; return ok;
        };
        QByteArray bytes;
        bool ok = fetch(native, QUrl("https://api.bilibili.com/x/centralization/interface/new/music"), "native API", &bytes);
        const auto list = QJsonDocument::fromJson(bytes).object().value("data").toObject().value("list").toArray();
        const QUrl cover(list.isEmpty() ? QString{} : list.first().toObject().value("cover").toString());
        if (cover.scheme() == "https") ok &= fetch(*qml, cover, "QML cover"); else { qInfo("LIVE no HTTPS cover returned"); ok = false; }
        return ok ? 0 : 1;
    }
    QTcpServer server; CHECK(server.listen(QHostAddress::LocalHost));
    int requests = 0; QByteArray received;
    QObject::connect(&server, &QTcpServer::newConnection, &server, [&] {
        while (auto *socket = server.nextPendingConnection()) {
            QObject::connect(socket, &QTcpSocket::disconnected, socket, &QObject::deleteLater);
            QObject::connect(socket, &QTcpSocket::readyRead, socket, [socket, &requests, &received] {
                auto bytes = socket->property("buffer").toByteArray() + socket->readAll(); socket->setProperty("buffer", bytes);
                if (!bytes.contains("\r\n\r\n") || socket->property("sent").toBool()) return;
                socket->setProperty("sent", true); ++requests; received = bytes;
                if (bytes.startsWith("GET /redirect ")) socket->write("HTTP/1.1 302 Found\r\nLocation: /final\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
                else socket->write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok");
                socket->disconnectFromHost();
            });
        }
    });
    QNetworkRequest request(QUrl(QString("http://127.0.0.1:%1/fixture").arg(server.serverPort())));
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, true); request.setAttribute(QNetworkRequest::Http2DirectAttribute, true);
    request.setRawHeader("Cookie", "fixture=synthetic"); request.setRawHeader("Referer", "https://example.test/");
    for (auto *manager : {static_cast<QNetworkAccessManager *>(&native), qml}) {
        auto *reply = manager->get(request); CHECK(policy(reply->request()));
        CHECK(reply->request().sslConfiguration() == request.sslConfiguration());
        QSignalSpy done(reply, &QNetworkReply::finished); CHECK(done.wait(3000)); CHECK(reply->error() == QNetworkReply::NoError);
        CHECK(received.contains("Cookie: fixture=synthetic") && received.contains("Referer: https://example.test/"));
        CHECK(!reply->attribute(QNetworkRequest::Http2WasUsedAttribute).toBool()); delete reply;
    }
    CHECK(request.attribute(QNetworkRequest::Http2AllowedAttribute).toBool()); // Caller's request is unchanged.
    request.setUrl(QUrl(QString("http://127.0.0.1:%1/redirect").arg(server.serverPort())));
    auto *redirect = native.get(request); QSignalSpy redirectDone(redirect, &QNetworkReply::finished);
    CHECK(redirectDone.wait(3000)); CHECK(redirect->url().path() == "/final" && policy(redirect->request())); delete redirect;
    auto *cancelled = qml->get(request); QSignalSpy cancelledDone(cancelled, &QNetworkReply::finished); cancelled->abort();
    CHECK(QTest::qWaitFor([&] { return cancelledDone.count() == 1; }, 1000));
    CHECK(cancelled->error() == QNetworkReply::OperationCanceledError && policy(cancelled->request())); delete cancelled;
    QObject context; bool callback = false;
    HttpTransport transport(QUrl(QString("http://127.0.0.1:%1").arg(server.serverPort())));
    auto *handle = transport.get("/fixture", {}, &context, [&](auto) { callback = true; });
    auto *reply = transport.findChild<QNetworkReply *>(); CHECK(reply && policy(reply->request())); delete handle;
    QCoreApplication::processEvents(); CHECK(!callback);
    CHECK(requests >= 4);
    qInfo("PASS: native/QML HTTP1 policy, preserved headers/TLS, redirect, cancellation and caller destruction");
}
