#include "MusicController.h"
#include <QGuiApplication>
#include <QElapsedTimer>
#include <QThread>
#include <QDir>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <functional>
#include <iostream>
#include <stdexcept>

static QJsonArray checks;
static void require(bool ok, const char *name) {
    checks.append(QJsonObject{{"check", name}, {"passed", ok}});
    if (!ok) throw std::runtime_error(name);
}
static bool waitFor(const std::function<bool()> &predicate, int timeout = 15000) {
    QElapsedTimer timer; timer.start();
    do {
        QCoreApplication::processEvents(QEventLoop::AllEvents, 20);
        if (predicate()) return true;
        QThread::msleep(20);
    } while (timer.elapsed() < timeout);
    return false;
}
static void settle(int ms) {
    QElapsedTimer timer; timer.start();
    waitFor([&] { return timer.elapsed() >= ms; }, ms + 500);
}
int main(int argc, char **argv) {
    QGuiApplication app(argc, argv);
    app.setOrganizationName("NextKdeTests");
    app.setApplicationName("KMusicLocalIntegration");
    const auto args = app.arguments();
    if (args.size() != 3 || qEnvironmentVariable("KOS_MUSIC_DATA_DIR").isEmpty()) return 2;
    const QString mode = args[1], root = QFileInfo(args[2]).canonicalFilePath();
    try {
        require(!root.isEmpty(), "fixture directory exists");
        require(!qEnvironmentVariableIsSet("KOS_MUSIC_FAKE_AUDIO"), "real audio backend requested");
        MusicController music;
        require(waitFor([&] { return music.ready(); }), "controller initializes");
        music.setVolume(0); // Real decoding and clock; silent output for the user's desktop.
        require(music.engineAvailable(), "GStreamer available");
        if (mode == "seed") {
            require(music.libraryModel()->count() == 0, "isolated library starts empty");
            music.addLibraryFolder(root);
            require(waitFor([&] { return !music.scanning() && music.libraryModel()->count() == 2; }), "import two downloaded audio files");
            require(music.scanWarnings().isEmpty(), "import has no scan warnings");
            const auto tracks = music.libraryModel()->visibleTracks();
            for (const auto &track : tracks) {
                require(!track.title.isEmpty() && track.durationMs > 10000 && track.source == "local", "local metadata and duration populated");
            }
            require(!music.albums().isEmpty() && !music.artists().isEmpty(), "album and artist groups available");
            music.setSearch(tracks[0].title);
            require(music.libraryModel()->visibleIds().contains(tracks[0].id), "search finds imported title");
            music.setSearch("__kmusic_no_matching_song__");
            require(music.libraryModel()->count() == 0, "unmatched search returns empty");
            music.setSearch("");
            music.rescanLibrary();
            require(waitFor([&] { return !music.scanning(); }), "rescan completes");
            require(music.libraryModel()->count() == 2, "rescan does not duplicate songs");
            music.addLibraryFolder(root);
            require(waitFor([&] { return !music.scanning(); }), "reimport completes");
            require(music.libraryFolders().size() == 1 && music.libraryModel()->count() == 2, "reimport deduplicates root and tracks");
            music.addLibraryFolder(root + "/missing-folder");
            require(!music.errorMessage().isEmpty(), "invalid folder reports error"); music.clearError();
            music.createPlaylist("Local integration");
            require(music.playlists().size() == 1, "create device playlist");
            const auto pid = music.playlists()[0].toMap().value("id").toLongLong();
            music.addTrackToPlaylist(pid, tracks[0].id); music.addTrackToPlaylist(pid, tracks[0].id);
            music.selectPlaylist(pid);
            require(music.playlistTracksModel()->count() == 1, "playlist deduplicates repeated song");
            music.addTrackToPlaylist(pid, tracks[1].id);
            require(music.playlistTracksModel()->count() == 2, "add second playlist song");
            music.removeTrackFromPlaylist(pid, tracks[1].id);
            require(music.playlistTracksModel()->count() == 1 && QFileInfo::exists(tracks[1].path), "remove playlist entry preserves file");
            music.addTrackToPlaylist(pid, tracks[1].id);
            music.renamePlaylist(pid, "Saved local playlist");
            require(music.playlists()[0].toMap().value("name") == "Saved local playlist", "rename playlist");
            music.toggleTrackFavorite("library", tracks[0].id);
            require(music.favoritesModel()->count() == 1, "favorite local track");
            music.setShuffle(false); music.setRepeatMode("none");
            music.playTrack(tracks[0].id);
            require(waitFor([&] { return music.playbackState() == "Playing" && music.positionMs() > 500; }), "real decoding advances playback clock");
            require(music.queueModel()->count() == 2 && music.durationMs() > 10000, "library playback builds queue with duration");
            music.pause();
            require(waitFor([&] { return music.playbackState() == "Paused"; }), "pause playback");
            settle(300); const auto paused = music.positionMs(); settle(600);
            require(qAbs(music.positionMs() - paused) < 150, "paused clock remains stable");
            require(music.seekable(), "local track is seekable"); music.seek(5000);
            require(waitFor([&] { return qAbs(music.positionMs() - 5000) < 700; }), "seek while paused");
            music.play();
            require(waitFor([&] { return music.positionMs() > 5500 && music.playbackState() == "Playing"; }), "resume after seek");
            music.next();
            require(waitFor([&] { return music.currentTrackId() == tracks[1].id && music.positionMs() > 300; }), "next track decodes");
            music.previous();
            require(waitFor([&] { return music.currentTrackId() == tracks[0].id && music.positionMs() > 300; }), "previous track decodes");
            music.setRepeatMode("none"); music.seek(music.durationMs() - 1200);
            require(waitFor([&] { return music.currentTrackId() == tracks[1].id && music.positionMs() > 300; }), "end of stream advances queue");
            music.stop();
            require(waitFor([&] { return music.playbackState() == "Stopped"; }), "stop playback");
        } else if (mode == "persist") {
            require(waitFor([&] { return !music.scanning() && music.libraryModel()->count() == 2; }), "library persists across process restart");
            require(music.libraryFolders().size() == 1, "folder registration persists");
            require(music.playlists().size() == 1 && music.playlists()[0].toMap().value("name") == "Saved local playlist", "playlist name persists");
            const auto pid = music.playlists()[0].toMap().value("id").toLongLong();
            music.selectPlaylist(pid);
            require(music.playlistTracksModel()->count() == 2, "playlist entries persist");
            require(music.favoritesModel()->count() == 1, "favorite persists");
            require(music.recentModel()->count() > 0, "playback history persists");
            music.playPlaylist(pid);
            require(waitFor([&] { return music.queueModel()->count() == 2 && music.positionMs() > 300; }), "saved playlist plays after restart");
            music.stop();
            music.removePlaylist(pid);
            require(music.playlists().isEmpty() && music.libraryModel()->count() == 2, "delete playlist preserves library");
            music.removeLibraryFolder(root);
            require(music.libraryFolders().isEmpty() && music.libraryModel()->count() == 0, "remove root clears library index");
            require(QDir(root).entryList({"*.ogg"}, QDir::Files).size() == 2, "root removal preserves downloaded audio files");
        } else throw std::runtime_error("unknown phase");
        std::cout << QJsonDocument(QJsonObject{{"phase", mode}, {"passed", true}, {"checks", checks}}).toJson().constData();
        return 0;
    } catch (const std::exception &error) {
        std::cout << QJsonDocument(QJsonObject{{"phase", mode}, {"passed", false}, {"failure", error.what()}, {"checks", checks}}).toJson().constData();
        return 1;
    }
}
