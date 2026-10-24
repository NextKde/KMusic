#include "PlaybackEngine.h"
#include <QCoreApplication>
#include <QTcpServer>
#include <QTcpSocket>
#include <QTest>
#include <QtEndian>
#define CHECK(c) do { if (!(c)) qFatal("Failed line %d: %s", __LINE__, #c); } while (false)
static QByteArray wave() {
    QByteArray out("RIFF");
    auto u32 = [&](quint32 v) { v = qToLittleEndian(v); out.append(reinterpret_cast<const char *>(&v), 4); };
    auto u16 = [&](quint16 v) { v = qToLittleEndian(v); out.append(reinterpret_cast<const char *>(&v), 2); };
    const int size = 16000 * 10;
    u32(36 + size); out.append("WAVEfmt "); u32(16); u16(1); u16(1); u32(8000); u32(16000); u16(2); u16(16);
    out.append("data"); u32(size); out.append(QByteArray(size, '\0')); return out;
}
int main(int argc, char **argv) {
    qputenv("KOS_MUSIC_FAKE_AUDIO", "1");
    QCoreApplication app(argc, argv);
    QTcpServer server; CHECK(server.listen(QHostAddress::LocalHost));
    QList<QByteArray> requests;
    const auto audio = wave();
    QObject::connect(&server, &QTcpServer::newConnection, &server, [&] {
        while (auto *socket = server.nextPendingConnection()) {
            QObject::connect(socket, &QTcpSocket::readyRead, socket, [&, socket] {
                const auto request = socket->readAll(); requests.append(request);
                socket->write("HTTP/1.1 200 OK\r\nContent-Type: audio/wav\r\nContent-Length: " + QByteArray::number(audio.size()) + "\r\nConnection: close\r\n\r\n" + audio);
                socket->disconnectFromHost();
            });
            QObject::connect(socket, &QTcpSocket::disconnected, socket, &QObject::deleteLater);
        }
    });
    PlaybackEngine engine; CHECK(engine.available());
    QUrl url(QString("http://127.0.0.1:%1/audio.wav").arg(server.serverPort()));
    CHECK(engine.load(url, true, 0, "KMusic-header-test", QUrl("https://www.bilibili.com/")));
    CHECK(QTest::qWaitFor([&] { return engine.positionMs() > 300 || engine.state() == "Error"; }, 10000));
    CHECK(engine.state() != "Error" && engine.durationMs() > 0);
    CHECK(!requests.isEmpty());
    CHECK(requests.first().contains("KMusic-header-test") && requests.first().contains("https://www.bilibili.com/"));
    engine.pause(); CHECK(QTest::qWaitFor([&] { return engine.state() == "Paused"; }, 3000));
    requests.clear();
    CHECK(engine.load(url, true));
    CHECK(QTest::qWaitFor([&] { return !requests.isEmpty(); }, 5000));
    CHECK(!requests.first().contains("KMusic-header-test") && !requests.first().contains("Referer:"));
    engine.stop();
    qInfo("PASS: GStreamer HTTP audio decode/progress/pause and per-load header isolation");
}
