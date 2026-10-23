#include "OnlineMusicProvider.h"
#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QStandardPaths>
#include <QTimer>
#include <QSet>
#include <algorithm>
#include <utility>

namespace {
QString joinedArtists(const QJsonArray &values) {
    QStringList names;
    for (const auto &value : values) names.append(value.toObject().value("name").toString());
    return names.join(QStringLiteral(" / "));
}
QString failureText(const QJsonObject &data) {
    const QString category = data.value("category").toString();
    const QString message = data.value("message").toString(QStringLiteral("NetEase request failed"));
    if (category == "auth") return QObject::tr("NetEase login required or expired: %1").arg(message);
    if (category == "unavailable") return QObject::tr("Not available from NetEase: %1").arg(message);
    if (category == "network") return QObject::tr("NetEase network error: %1").arg(message);
    return message;
}
}
OnlineMusicProvider::OnlineMusicProvider(QObject *parent) : QObject(parent) {
    connect(&m_process, &QProcess::readyReadStandardOutput, this, &OnlineMusicProvider::readOutput);
    connect(&m_process, &QProcess::readyReadStandardError, this, [this] { m_process.readAllStandardError(); });
    connect(&m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        failPending(error == QProcess::FailedToStart
            ? tr("NetEase helper could not start. Install Node.js 22.19 or newer.")
            : tr("NetEase connection interrupted. Retry the request."));
    });
    connect(&m_process, &QProcess::finished, this, [this](int, QProcess::ExitStatus) { failPending(tr("NetEase helper exited; retry the request.")); });
}
OnlineMusicProvider::~OnlineMusicProvider() {
    // Shutdown must not deliver pending requests into partially destroyed owners.
    QObject::disconnect(&m_process, nullptr, this, nullptr);
    m_pending.clear();
    if (m_process.state() != QProcess::NotRunning) {
        m_process.kill();
        m_process.waitForFinished(500);
    }
}
bool OnlineMusicProvider::searching() const { return m_searching; }
QString OnlineMusicProvider::errorMessage() const { return m_errorMessage; }
void OnlineMusicProvider::setSearching(bool searching) { if (m_searching == searching) return; m_searching = searching; emit searchingChanged(); }
void OnlineMusicProvider::setError(const QString &message) { if (m_errorMessage == message) return; m_errorMessage = message; emit errorMessageChanged(); }
void OnlineMusicProvider::failPending(const QString &message) {
    auto pending = std::exchange(m_pending, {});
    for (const auto &callback : pending) callback({{"ok", false}, {"category", "network"}, {"message", message}});
    m_buffer.clear();
}
void OnlineMusicProvider::request(const QString &action, const QJsonObject &params, Callback callback) {
    if (m_pending.size() >= 16) { callback({{"ok", false}, {"message", tr("Too many pending requests; wait and retry.")}}); return; }
    if (m_process.state() == QProcess::NotRunning) {
        QString providerDir = qEnvironmentVariable("KMUSIC_PROVIDER_DIR");
        if (providerDir.isEmpty()) providerDir = QDir(QCoreApplication::applicationDirPath()).filePath("providers");
        if (!QFileInfo::exists(QDir(providerDir).filePath("runtime/helper.js")))
            providerDir = QDir(QCoreApplication::applicationDirPath()).filePath("../share/kmusic/providers");
        const QString helper = QDir(providerDir).filePath("runtime/helper.js");
        if (!QFileInfo::exists(helper)) { callback({{"ok", false}, {"message", tr("NetEase helper is missing from the installation.")}}); return; }
        const QString node = QStandardPaths::findExecutable(QStringLiteral("node"));
        if (node.isEmpty()) { callback({{"ok", false}, {"message", tr("Install Node.js 22.19 or newer for the NetEase provider.")}}); return; }
        m_process.setProgram(node);
        m_process.setArguments({helper});
        m_process.start();
        // The child may restart after a transport/process failure. Restore its
        // private session before queued requests; id0 has no public callback.
        m_process.write(QJsonDocument(QJsonObject{{"id", 0}, {"action", "sessionRestore"},
            {"params", QJsonObject{{"cookie", m_sessionCookie}}}}).toJson(QJsonDocument::Compact) + '\n');
    }
    const qint64 id = ++m_sequence;
    m_pending.insert(id, std::move(callback));
    const QJsonObject message{{"id", id}, {"action", action}, {"params", params}};
    m_process.write(QJsonDocument(message).toJson(QJsonDocument::Compact) + '\n');
    QTimer::singleShot(35000, this, [this, id] {
        if (!m_pending.contains(id)) return;
        const auto done = m_pending.take(id);
        done({{"ok", false}, {"category", "network"}, {"message", tr("NetEase request timed out; retry.")}});
    });
}
void OnlineMusicProvider::readOutput() {
    m_buffer += m_process.readAllStandardOutput();
    if (m_buffer.size() > 8 * 1024 * 1024) { m_process.kill(); failPending(tr("NetEase response exceeded the size limit.")); return; }
    int end;
    while ((end = m_buffer.indexOf('\n')) >= 0) {
        const auto line = m_buffer.left(end); m_buffer.remove(0, end + 1);
        const auto data = QJsonDocument::fromJson(line).object();
        const auto id = data.value("id").toVariant().toLongLong();
        if (!m_pending.contains(id)) continue;
        const auto accountBody = data.value("body").toObject();
        if (data.value("ok").toBool() && !accountBody.value("sessionCookie").toString().isEmpty())
            m_sessionCookie = accountBody.value("sessionCookie").toString();
        if (data.value("sessionExpired").toBool()) emit sessionExpired();
        const auto done = m_pending.take(id); done(data);
    }
}
void OnlineMusicProvider::search(const QString &query, int limit) {
    const quint64 generation = ++m_generation;
    const QString cleaned = query.trimmed();
    if (cleaned.isEmpty()) { setSearching(false); setError({}); emit resultsReady({}); return; }
    setSearching(true); setError({}); emit resultsReady({});
    request("search", {{"keywords", cleaned}, {"limit", std::clamp(limit, 1, 100)}, {"type", 1}}, [this, generation, cleaned](const QJsonObject &response) {
        if (generation != m_generation) return;
        setSearching(false);
        if (!response.value("ok").toBool()) { setError(failureText(response)); return; }
        QString error;
        const auto tracks = parseNeteaseSearch(QJsonDocument(response.value("body").toObject()).toJson(), &error, cleaned);
        setError(error); emit resultsReady(tracks);
    });
}
void OnlineMusicProvider::searchCollections(const QString &query, const QString &kind) {
    const auto generation = ++m_generation;
    const QString cleaned = query.trimmed();
    emit collectionsReady({}); setError({});
    if (cleaned.isEmpty()) { setSearching(false); return; }
    setSearching(true);
    request("search", {{"keywords", cleaned}, {"type", kind == "playlist" ? 1000 : kind == "artist" ? 100 : 10}, {"limit", 30}},
        [this, generation, kind](const QJsonObject &response) {
        if (generation != m_generation) return;
        setSearching(false);
        if (!response.value("ok").toBool()) { setError(failureText(response)); return; }
        const auto result = response.value("body").toObject().value("result").toObject();
        QVariantList rows;
        for (const auto &value : result.value(kind == "playlist" ? "playlists" : kind == "artist" ? "artists" : "albums").toArray()) {
            const auto entry = value.toObject();
            const auto artist = entry.value("artist").toObject();
            const QString owner = kind == "playlist" ? entry.value("creator").toObject().value("nickname").toString()
                : kind == "artist" ? entry.value("alias").toVariant().toStringList().join(" / ") : joinedArtists(entry.value("artists").toArray());
            rows.append(QVariantMap{{"providerId", QString::number(entry.value("id").toVariant().toLongLong())},
                {"kind", kind}, {"title", entry.value("name").toString()},
                {"artist", owner.isEmpty() ? artist.value("name").toString() : owner},
                {"artwork", entry.value(kind == "playlist" ? "coverImgUrl" : "picUrl").toString()},
                {"totalCount", entry.value(kind == "playlist" ? "trackCount" : kind == "artist" ? "musicSize" : "size").toInt()}, {"source", "NetEase"}});
        }
        emit collectionsReady(rows);
    });
}
void OnlineMusicProvider::loadArtistAlbums(const QString &id, int offset) {
    const auto generation = ++m_artistAlbumGeneration;
    request("artistAlbums", {{"id", id}, {"offset", offset}, {"limit", 30}}, [this, id, offset, generation](const QJsonObject &response) {
        if (generation != m_artistAlbumGeneration) return;
        if (!response.value("ok").toBool()) { emit artistAlbumsReady(id, {}, 0, false, offset, failureText(response)); return; }
        const auto body = response.value("body").toObject();
        const auto raw = body.value("hotAlbums").toArray();
        QVariantList rows;
        for (const auto &value : raw) {
            const auto album = value.toObject();
            const QString artist = joinedArtists(album.value("artists").toArray());
            rows.append(QVariantMap{{"kind", "album"}, {"providerId", QString::number(album.value("id").toVariant().toLongLong())},
                {"title", album.value("name").toString()}, {"artwork", album.value("picUrl").toString()},
                {"artist", artist.isEmpty() ? album.value("artist").toObject().value("name").toString() : artist},
                {"totalCount", album.value("size").toInt()}, {"source", "NetEase"}});
        }
        const int total = body.value("artist").toObject().value("albumSize").toInt();
        const bool more = body.contains("more") ? body.value("more").toBool() : offset + raw.size() < total;
        if (raw.isEmpty() && more) { emit artistAlbumsReady(id, {}, total, false, offset, tr("NetEase returned no albums for this batch. Retry.")); return; }
        emit artistAlbumsReady(id, rows, total, more, offset + raw.size(), {});
    });
}
void OnlineMusicProvider::loadArtistTracks(const QString &id) {
    const auto generation = ++m_albumGeneration;
    request("artistTracks", {{"id", id}}, [this, id, generation](const QJsonObject &response) {
        if (generation != m_albumGeneration) return;
        if (!response.value("ok").toBool()) { emit albumTracksReady(id, {}, failureText(response), {}); return; }
        const auto body = response.value("body").toObject();
        QString error;
        const auto tracks = parseNeteaseSearch(QJsonDocument(QJsonObject{{"code", 200},
            {"result", QJsonObject{{"songs", body.value("songs")}}}}).toJson(), &error);
        emit albumTracksReady(id, tracks, error, body.value("collection").toObject().toVariantMap());
    });
}
void OnlineMusicProvider::loadPlaylistTracks(const QString &id, int offset) {
    const auto generation = ++m_albumGeneration;
    request("playlistTracks", {{"id", id}, {"offset", offset}}, [this, id, generation](const QJsonObject &response) {
        if (generation != m_albumGeneration) return;
        if (!response.value("ok").toBool()) { emit albumTracksReady(id, {}, failureText(response), {}); return; }
        const auto body = response.value("body").toObject();
        QString error;
        auto tracks = parseNeteaseSearch(QJsonDocument(QJsonObject{{"code", 200},
            {"result", QJsonObject{{"songs", body.value("songs")}}}}).toJson(), &error);
        emit albumTracksReady(id, tracks, error, body.value("collection").toObject().toVariantMap());
    });
}
void OnlineMusicProvider::cancelResolve() { ++m_resolveGeneration; }
void OnlineMusicProvider::resolve(qint64 trackId, const QString &songId, const QString &quality) {
    const auto generation = ++m_resolveGeneration;
    const QString level = quality == "flac" || quality == "flac24bit" ? "lossless" : quality == "320k" ? "exhigh" : "standard";
    request("resolve", {{"songId", songId}, {"level", level}}, [this, generation, trackId](const QJsonObject &response) {
        if (generation != m_resolveGeneration) {
            ++m_ignoredResolveReplies;
            if (response.value("ok").toBool()) ++m_ignoredResolveSuccesses;
            return;
        }
        if (!response.value("ok").toBool()) { emit resolveFailed(trackId, failureText(response)); return; }
        const auto body = response.value("body").toObject();
        const QUrl url(body.value("url").toString());
        if (!url.isValid() || (url.scheme() != "https" && url.scheme() != "http")) { emit resolveFailed(trackId, tr("NetEase returned an invalid playback address.")); return; }
        emit resolved(trackId, url, body.value("trial").toBool(), body.value("level").toString());
    });
}
QList<TrackRecord> OnlineMusicProvider::parseNeteaseSearch(const QByteArray &payload, QString *errorMessage, const QString &) {
    const auto body = QJsonDocument::fromJson(payload).object();
    if (body.value("code").toInt() != 200) { if (errorMessage) *errorMessage = body.value("message").toString(QObject::tr("NetEase search failed")); return {}; }
    QList<TrackRecord> tracks;
    for (const auto &value : body.value("result").toObject().value("songs").toArray()) {
        const auto song = value.toObject();
        const auto album = song.value(song.contains("al") ? "al" : "album").toObject();
        TrackRecord track;
        track.source = QStringLiteral("netease");
        track.providerId = QString::number(song.value("id").toVariant().toLongLong());
        track.path = QStringLiteral("netease://song/%1").arg(track.providerId);
        track.title = song.value("name").toString();
        track.artist = joinedArtists(song.value(song.contains("ar") ? "ar" : "artists").toArray());
        track.albumArtist = track.artist;
        track.album = album.value("name").toString();
        track.artworkUrl = album.value("picUrl").toString();
        track.durationMs = song.value(song.contains("dt") ? "dt" : "duration").toVariant().toLongLong();
        track.sourceData = QString::fromUtf8(QJsonDocument(QJsonObject{{"id", track.providerId}, {"albumId", album.value("id")}}).toJson(QJsonDocument::Compact));
        tracks.append(track);
    }
    return tracks;
}

void OnlineMusicProvider::loadLyrics(qint64 trackId, const QString &songId) {
    const quint64 generation = ++m_lyricGeneration;
    request("lyric", {{"id", songId}}, [this, trackId, generation](const QJsonObject &response) {
        if (generation != m_lyricGeneration) return;
        if (!response.value("ok").toBool()) { emit lyricsResolved(trackId, {}, failureText(response)); return; }
        const auto body = response.value("body").toObject();
        const QString lrc = body.value("lrc").toObject().value("lyric").toString();
        emit lyricsResolved(trackId, lrc, lrc.isEmpty() ? tr("Lyrics unavailable from NetEase") : QString{});
    });
}
void OnlineMusicProvider::loadDetail(const QString &songId) {
    request("detail", {{"ids", songId}}, [this](const QJsonObject &response) {
        if (!response.value("ok").toBool()) { emit detailReady({{"error", failureText(response)}}); return; }
        const auto songs = response.value("body").toObject().value("songs").toArray();
        if (songs.isEmpty()) { emit detailReady({{"error", tr("Song details unavailable")}}); return; }
        const auto song = songs.first().toObject();
        const auto album = song.value("al").toObject();
        emit detailReady({{"id", song.value("id").toVariant()}, {"title", song.value("name").toString()},
            {"artist", joinedArtists(song.value("ar").toArray())}, {"album", album.value("name").toString()},
            {"artwork", album.value("picUrl").toString()}, {"durationMs", song.value("dt").toVariant()},
            {"source", "NetEase"}});
    });
}

void OnlineMusicProvider::loadPersonalSection(const QString &section, const QString &uid, int offset) {
    const auto epoch = m_personalEpoch;
    const auto sessionEpoch = m_sessionEpoch;
    const auto generation = ++m_personalGenerations[section];
    request("personal", {{"section", section}, {"uid", uid}, {"offset", offset}},
        [this, section, offset, epoch, sessionEpoch, generation](const QJsonObject &response) {
            if (epoch != m_personalEpoch || sessionEpoch != m_sessionEpoch
                || generation != m_personalGenerations.value(section)) return;
            if (!response.value("ok").toBool()) { emit personalSectionReady(section, offset, {}, {}, {}, failureText(response)); return; }
            const auto body = response.value("body").toObject();
            auto page = body.value("page").toObject().toVariantMap();
            if (page.value("more").toBool() && page.value("nextOffset").toInt() <= offset) {
                emit personalSectionReady(section, offset, {}, {}, {}, tr("NetEase returned a non-advancing page. Retry.")); return;
            }
            QVariantList items;
            QList<TrackRecord> tracks;
            if (section == "likedSongs" || section == "recentSongs") {
                const auto addSong = [&items, &tracks](const TrackRecord &track, const QString &entryId, qint64 playedAt) {
                    if (track.providerId == "0" || track.title.isEmpty()) return;
                    tracks.append(track);
                    items.append(QVariantMap{{"providerId", track.providerId}, {"title", track.title},
                        {"artist", track.artist}, {"artwork", track.artworkUrl}, {"kind", "song"},
                        {"source", "NetEase"}, {"album", track.album}, {"durationMs", track.durationMs},
                        {"entryId", entryId.isEmpty() ? track.providerId : entryId}, {"playedAt", playedAt}});
                };
                if (section == "recentSongs") {
                    for (const auto &value : body.value("records").toArray()) {
                        const auto record = value.toObject();
                        const QJsonObject adapted{{"code", 200}, {"result", QJsonObject{{"songs", QJsonArray{record.value("song")}}}}};
                        const auto parsed = parseNeteaseSearch(QJsonDocument(adapted).toJson());
                        if (!parsed.isEmpty()) addSong(parsed.first(), record.value("entryId").toString(), record.value("playedAt").toVariant().toLongLong());
                    }
                } else {
                    const QJsonObject adapted{{"code", 200}, {"result", QJsonObject{{"songs", body.value("songs")}}}};
                    const auto parsed = parseNeteaseSearch(QJsonDocument(adapted).toJson());
                    for (const auto &track : parsed) addSong(track, {}, 0);
                }
            } else items = body.value("items").toArray().toVariantList();
            emit personalSectionReady(section, offset, items, tracks, page, {});
        });
}

void OnlineMusicProvider::loadDiscoverySection(const QString &section) {
    static const QHash<QString, QString> actions{{"playlists", "discoveryPlaylists"},
        {"newSongs", "discoveryNewSongs"}, {"charts", "discoveryCharts"},
        {"dailySongs", "discoveryDailySongs"}, {"dailyPlaylists", "discoveryDailyPlaylists"}};
    if (!actions.contains(section)) return;
    const auto epoch = m_discoveryFeedEpoch;
    const auto sessionEpoch = m_sessionEpoch;
    const bool daily = section == QLatin1String("dailySongs") || section == QLatin1String("dailyPlaylists");
    request(actions.value(section), {{"limit", 12}, {"type", 0}}, [this, section, epoch, sessionEpoch, daily](const QJsonObject &response) {
        if (epoch != m_discoveryFeedEpoch || (daily && sessionEpoch != m_sessionEpoch)) return;
        if (!response.value("ok").toBool()) { emit discoverySectionReady(section, {}, {}, failureText(response)); return; }
        const auto body = response.value("body").toObject();
        QVariantList items;
        QList<TrackRecord> tracks;
        QSet<QString> ids;
        if (section == "newSongs" || section == "dailySongs") {
            const auto songs = section == "dailySongs"
                ? body.value("data").toObject().value("dailySongs").toArray() : body.value("data").toArray();
            const QJsonObject adapted{{"code", 200}, {"result", QJsonObject{{"songs", songs}}}};
            const auto parsed = parseNeteaseSearch(QJsonDocument(adapted).toJson());
            for (const auto &track : parsed) {
                if (track.providerId == "0" || track.title.isEmpty() || ids.contains(track.providerId)) continue;
                ids.insert(track.providerId); tracks.append(track);
                items.append(QVariantMap{{"providerId", track.providerId}, {"kind", "song"},
                    {"title", track.title}, {"artist", track.artist}, {"artwork", track.artworkUrl},
                    {"durationMs", track.durationMs}, {"album", track.album}, {"source", "NetEase"}});
                if (items.size() >= 12) break;
            }
        } else {
            const auto entries = body.value(section == "charts" ? "list" : section == "dailyPlaylists" ? "recommend" : "result").toArray();
            for (const auto &value : entries) {
                const auto entry = value.toObject();
                const QString id = QString::number(entry.value("id").toVariant().toLongLong());
                const QString title = entry.value("name").toString();
                if (id == "0" || title.isEmpty() || ids.contains(id)) continue;
                ids.insert(id);
                const QString description = entry.value("description").toString(entry.value("copywriter").toString());
                QString artist = entry.value("creator").toObject().value("nickname").toString();
                if (artist.isEmpty()) artist = entry.value("updateFrequency").toString();
                items.append(QVariantMap{{"providerId", id}, {"kind", "playlist"}, {"title", title},
                    {"artist", artist}, {"description", description}, {"source", "NetEase"},
                    {"artwork", entry.value("coverImgUrl").toString(entry.value("picUrl").toString())},
                    {"totalCount", entry.value("trackCount").toInt()}});
                if (items.size() >= 12) break;
            }
        }
        emit discoverySectionReady(section, items, tracks,
            items.isEmpty() ? tr("No items returned by NetEase. Retry later.") : QString{});
    });
}

void OnlineMusicProvider::loadNewAlbums() {
    const quint64 generation = ++m_discoveryGeneration;
    request("newAlbums", {{"limit", 8}}, [this, generation](const QJsonObject &response) {
        if (generation != m_discoveryGeneration) return;
        if (!response.value("ok").toBool()) { emit newAlbumsReady({}, failureText(response)); return; }
        QVariantList albums;
        for (const auto &value : response.value("body").toObject().value("albums").toArray()) {
            const auto album = value.toObject();
            const QString id = QString::number(album.value("id").toVariant().toLongLong());
            const QString title = album.value("name").toString();
            if (id == "0" || title.isEmpty()) continue;
            const QString artist = joinedArtists(album.value("artists").toArray());
            albums.append(QVariantMap{{"providerId", id}, {"title", title}, {"artist", artist},
                {"artwork", album.value("picUrl").toString()}, {"source", "NetEase"}});
            if (albums.size() >= 8) break;
        }
        emit newAlbumsReady(albums, albums.isEmpty() ? tr("No new albums returned by NetEase. Retry later.") : QString{});
    });
}
void OnlineMusicProvider::loadAlbumTracks(const QString &albumId) {
    const quint64 generation = ++m_albumGeneration;
    request("album", {{"id", albumId}}, [this, albumId, generation](const QJsonObject &response) {
        if (generation != m_albumGeneration) return;
        if (!response.value("ok").toBool()) { emit albumTracksReady(albumId, {}, failureText(response), {}); return; }
        const auto body = response.value("body").toObject();
        const QJsonObject adapted{{"code", body.value("code")}, {"result", QJsonObject{{"songs", body.value("songs")}}}};
        QString error;
        auto tracks = parseNeteaseSearch(QJsonDocument(adapted).toJson(), &error);
        // A catalogue response is not playback permission; resolution stays fresh.
        // Keep the response order and complete track list for album playback.
        const auto album = body.value("album").toObject();
        QString albumArtist = joinedArtists(album.value("artists").toArray());
        if (albumArtist.isEmpty()) albumArtist = album.value("artist").toObject().value("name").toString();
        for (auto &track : tracks) {
            // Album identity follows the album artist, not per-song guest credits.
            if (!albumArtist.isEmpty()) track.albumArtist = albumArtist;
            if (track.artworkUrl.isEmpty()) track.artworkUrl = album.value("picUrl").toString();
        }
        if (tracks.isEmpty() && error.isEmpty()) error = tr("No playable tracks listed for this album.");
        emit albumTracksReady(albumId, tracks, error,
            {{"kind", "album"}, {"partial", false}, {"totalCount", tracks.size()}, {"providerId", albumId}, {"title", album.value("name").toString()}, {"artist", albumArtist},
             {"artwork", album.value("picUrl").toString()}, {"publishTime", album.value("publishTime").toVariant()},
             {"description", album.value("description").toString()}, {"trackCount", tracks.size()}, {"source", "NetEase"}});
    });
}
