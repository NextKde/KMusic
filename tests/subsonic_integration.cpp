#include "MusicController.h"
#include <QGuiApplication>
#include <QElapsedTimer>
#include <QThread>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QFile>
#include <QDirIterator>
#include <iostream>
#include <stdexcept>
static QJsonArray checks;
static void require(bool ok, const char *name) {
    checks.append(QJsonObject{{"check", name}, {"passed", ok}});
    if (!ok) throw std::runtime_error(name);
}
static bool waitFor(std::function<bool()> predicate, int timeout = 15000) {
    QElapsedTimer timer; timer.start();
    do { QCoreApplication::processEvents(QEventLoop::AllEvents, 20); if (predicate()) return true; QThread::msleep(20); } while (timer.elapsed() < timeout);
    return false;
}
int main(int argc, char **argv) {
    QGuiApplication app(argc, argv); app.setOrganizationName("NextKdeTests"); app.setApplicationName("SubsonicIntegration");
    int result = 0;
    try {
        MusicController music;
        require(waitFor([&] { return music.ready(); }), "controller ready"); music.setVolume(0);
        auto *server = music.mediaServer();
        const auto address = qEnvironmentVariable("SUBSONIC_TEST_URL");
        const auto password = qEnvironmentVariable("SUBSONIC_TEST_PASSWORD");
        const auto user = qEnvironmentVariable("SUBSONIC_TEST_USER");
        require(!address.isEmpty() && !password.isEmpty(), "isolated server configured");
        if (qEnvironmentVariableIsSet("SUBSONIC_RESUME")) {
            require(music.queueModel()->count() == 1 && music.positionMs() >= 4500, "queue and position restored after restart");
            require(music.playbackState() != "Playing", "restart does not autoplay by default");
            server->connectServer(address, user, password, false);
            require(waitFor([&] { return server->connected() && !server->busy(); }), "reconnect original server after restart");
            music.play();
            require(waitFor([&] { return music.playbackState() == "Playing" && music.positionMs() >= 4500; }), "resume restored server identity and seek");
            music.pause();
            std::cout << QJsonDocument(QJsonObject{{"checks", checks}, {"passed", true}}).toJson().toStdString();
            return 0;
        }
        server->connectServer(address, user, "wrong-password", false);
        require(waitFor([&] { return !server->busy(); }), "bad login completes");
        require(!server->connected() && !server->message().isEmpty(), "bad login rejected");
        server->connectServer(address, user, password, false);
        require(waitFor([&] { return server->connected() && !server->busy(); }, 30000), "valid login and albums loaded");
        require(!server->albums().isEmpty(), "real album entries");
        if (qEnvironmentVariableIsSet("SUBSONIC_MOCK")) {
            require(server->albums().size() == 50 && server->more(), "first album page");
            server->browseAlbums(true);
            require(waitFor([&] { return !server->busy(); }), "second album page loaded");
            require(server->albums().size() == 51 && !server->more(), "album pagination appends");
        }
        const auto albumId = server->albums().first().toMap().value("id").toString();
        server->openAlbum(albumId);
        require(waitFor([&] { return !server->busy(); }), "album detail completes");
        require(!server->songs().isEmpty(), "album songs loaded");
        const auto title = server->songs().first().toMap().value("title").toString();
        require(waitFor([&] { return !server->songs().first().toMap().value("artwork").toString().isEmpty(); }), "authenticated artwork cached without URL credentials");
        server->search(title);
        require(waitFor([&] { return !server->busy(); }), "search completes");
        require(!server->songs().isEmpty(), "server scoped search returns song");
        music.playMediaSong(0, true);
        require(music.queueModel()->count() == 1, "enqueue server track");
        music.play();
        require(waitFor([&] { return music.playbackState() == "Playing" && music.positionMs() > 300; }, 30000), "real server audio decoded and playing");
        require(music.queueModel()->visibleTracks().first().source == "subsonic", "server identity retained");
        require(music.libraryModel()->count() == 0, "server track excluded from local library");
        music.pause();
        require(waitFor([&] { return music.playbackState() == "Paused"; }), "pause server playback");
        music.seek(5000);
        require(waitFor([&] { return music.positionMs() >= 4500; }), "seek server audio");
        music.play();
        require(waitFor([&] { return music.playbackState() == "Playing"; }), "resume server audio");
        music.pause();
        server->search("__no_match_fixture__");
        require(waitFor([&] { return !server->busy(); }) && server->songs().isEmpty(), "empty search handled");
        server->disconnectServer();
        require(!server->connected() && server->songs().isEmpty(), "disconnect clears account view");
        music.play();
        require(waitFor([&] { return music.playbackState() == "Error" || !music.errorMessage().isEmpty(); }), "disconnected server does not fall back to other provider");
        server->connectServer(address, user, password, false);
        require(waitFor([&] { return server->connected() && !server->busy(); }), "reconnect after disconnect");
        music.play();
        require(waitFor([&] { return music.playbackState() == "Playing"; }), "reconnect playback");
        music.pause(); music.seek(5000);
        require(waitFor([&] { return music.positionMs() >= 4500; }), "position prepared for restart");
        // Database and preferences must contain identities, never server passwords or signed URLs.
        QDirIterator it(qEnvironmentVariable("KOS_MUSIC_DATA_DIR"), QDir::Files, QDirIterator::Subdirectories);
        while (it.hasNext()) { QFile file(it.next()); if (file.open(QIODevice::ReadOnly)) { const auto data = file.readAll(); require(!data.contains(password.toUtf8()) && !data.contains("&t=") && !data.contains("?u="), "no credentials persisted in music database"); } }
    } catch (const std::exception &e) { std::cerr << e.what() << '\n'; result = 1; }
    std::cout << QJsonDocument(QJsonObject{{"checks", checks}, {"passed", result == 0}}).toJson().toStdString();
    return result;
}
