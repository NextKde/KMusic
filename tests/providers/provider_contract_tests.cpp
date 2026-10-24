#include "HttpTransport.h"
#include "bilibili/BilibiliDetail.h"
#include "contracts/AccountProvider.h"
#include "contracts/LibraryProvider.h"
#include "contracts/PlaybackResolver.h"
#include "contracts/SearchProvider.h"
#include <QCoreApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QTest>

using namespace MusicProviders;
#define CHECK(condition) do { if (!(condition)) qFatal("Failed line %d: %s", __LINE__, #condition); } while (false)

static QByteArray fixture()
{
    return QJsonDocument(QJsonObject{{"code", 0}, {"data", QJsonObject{
        {"bvid", "BV1234567890"}, {"title", "Video"}, {"duration", 12},
        {"owner", QJsonObject{{"name", "Uploader"}}}, {"pic", "https://example.com/cover.jpg"},
        {"pages", QJsonArray{QJsonObject{{"cid", 123}, {"part", "Part 1"}, {"duration", 12}},
                            QJsonObject{{"cid", 456}, {"part", "Part 2"}, {"duration", 8}}}}
    }}}).toJson();
}
int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    const MediaId id{{"bilibili", {}, "account-a"}, "BV1234567890", {}};
    auto decoded = BilibiliDetail::decode(id, fixture());
    CHECK(std::holds_alternative<MediaDetail>(decoded));
    const auto detail = std::get<MediaDetail>(decoded);
    CHECK(detail.parts.size() == 2 && detail.parts[1].id.part == "456");
    CHECK(detail.parts[0].id.scope == id.scope && detail.item.durationMs == 12000);
    CHECK(detail.item.creator == "Uploader");
    auto missing = id;
    missing.part = "999";
    CHECK(std::get<Error>(BilibiliDetail::decode(missing, fixture())).code == ErrorCode::Unavailable);
    missing.scope.provider = "netease";
    CHECK(std::get<Error>(BilibiliDetail::decode(missing, fixture())).code == ErrorCode::InvalidRequest);
    CHECK(std::get<Error>(BilibiliDetail::decode(id, "<html>challenge</html>")).code == ErrorCode::InvalidResponse);
    CHECK(std::get<Error>(BilibiliDetail::decode(id, "{\"code\":-352}")).code == ErrorCode::VerificationRequired);
    CHECK(std::get<Error>(BilibiliDetail::decode(id, "{\"code\":-101}")).code == ErrorCode::AuthenticationRequired);
    CHECK(std::get<Error>(BilibiliDetail::decode(id, "{\"code\":0,\"data\":{}}")).code == ErrorCode::InvalidResponse);

    QTcpServer server;
    CHECK(server.listen(QHostAddress::LocalHost));
    QByteArray response = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}";
    bool hold = false;
    int requests = 0;
    QByteArray headers;
    QObject::connect(&server, &QTcpServer::newConnection, &server, [&] {
        while (auto *socket = server.nextPendingConnection()) {
            QObject::connect(socket, &QTcpSocket::readyRead, socket, [&, socket] {
                headers = socket->readAll();
                ++requests;
                if (!hold) { socket->write(response); socket->disconnectFromHost(); }
            });
            QObject::connect(socket, &QTcpSocket::disconnected, socket, &QObject::deleteLater);
        }
    });
    HttpTransport transport(QUrl(QString("http://127.0.0.1:%1").arg(server.serverPort())),
        {"test-agent", QUrl("https://www.bilibili.com/")});
    QObject context;
    int completions = 0;
    Result<QByteArray> result = QByteArray{};
    auto done = [&](Result<QByteArray> value) { result = value; ++completions; };
    transport.get("/view", {}, &context, done);
    CHECK(QTest::qWaitFor([&] { return completions == 1; }, 3000));
    CHECK(std::get<QByteArray>(result) == "{}");
    CHECK(headers.contains("User-Agent: test-agent") && headers.contains("Referer: https://www.bilibili.com/"));

    response = "HTTP/1.1 412 Precondition Failed\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
    transport.get("/blocked", {}, &context, done);
    CHECK(QTest::qWaitFor([&] { return completions == 2; }, 3000));
    CHECK(std::get<Error>(result).code == ErrorCode::VerificationRequired);

    response = "HTTP/1.1 302 Found\r\nLocation: /redirected\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
    const int before = requests;
    transport.get("/redirect", {}, &context, done);
    CHECK(QTest::qWaitFor([&] { return completions == 3; }, 3000));
    CHECK(std::get<Error>(result).code == ErrorCode::Network && requests == before + 1);

    hold = true;
    auto *request = transport.get("/cancel", {}, &context, done);
    request->cancel();
    CHECK(QTest::qWaitFor([&] { return completions == 4; }, 3000));
    CHECK(std::get<Error>(result).code == ErrorCode::Cancelled);
    request->cancel();
    QTest::qWait(30);
    CHECK(completions == 4);

    auto *shortContext = new QObject;
    transport.get("/destroy", {}, shortContext, done);
    delete shortContext;
    QTest::qWait(30);
    CHECK(completions == 4);
    transport.get("//invalid", {}, &context, done)->cancel();
    CHECK(QTest::qWaitFor([&] { return completions == 5; }, 3000));
    CHECK(std::get<Error>(result).code == ErrorCode::Cancelled);
    hold = false;
    for (const auto &[status, expected] : QList<std::pair<int, ErrorCode>>{
             {401, ErrorCode::AuthenticationRequired}, {429, ErrorCode::RateLimited},
             {503, ErrorCode::Network}}) {
        response = "HTTP/1.1 " + QByteArray::number(status)
            + " Failure\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
        const int previous = completions;
        transport.get("/failure", {}, &context, done);
        CHECK(QTest::qWaitFor([&] { return completions == previous + 1; }, 3000));
        CHECK(std::get<Error>(result).code == expected);
        CHECK(std::get<Error>(result).retryable == (status != 401));
    }
    const QByteArray large(4 * 1024 * 1024 + 1, 'x');
    response = "HTTP/1.1 200 OK\r\nContent-Length: " + QByteArray::number(large.size())
        + "\r\nConnection: close\r\n\r\n" + large;
    const int previous = completions;
    transport.get("/oversized", {}, &context, done);
    CHECK(QTest::qWaitFor([&] { return completions == previous + 1; }, 3000));
    CHECK(std::get<Error>(result).code == ErrorCode::InvalidResponse);
    qInfo("PASS: detail identity/parts/errors; HTTP headers/status/redirect/cancel/lifetime contracts");
}
