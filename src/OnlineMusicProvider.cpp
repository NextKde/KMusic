#include "OnlineMusicProvider.h"
#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QStandardPaths>
#include <QTimer>
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
    connect(&m_process, &QProcess::errorOccurred, this, [this] { failPending(tr("NetEase helper could not start. Install Node.js 22.19 or newer.")); });
    connect(&m_process, &QProcess::finished, this, [this](int, QProcess::ExitStatus) { failPending(tr("NetEase helper exited; retry the request.")); });
}
OnlineMusicProvider::~OnlineMusicProvider() { m_process.kill(); m_process.waitForFinished(500); }
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
        if (!QFileInfo::exists(QDir(providerDir).filePath("helper.ts")))
            providerDir = QDir(QCoreApplication::applicationDirPath()).filePath("../share/kmusic/providers");
        const QString helper = QDir(providerDir).filePath("helper.ts");
        if (!QFileInfo::exists(helper)) { callback({{"ok", false}, {"message", tr("NetEase helper is missing from the installation.")}}); return; }
        const QString node = QStandardPaths::findExecutable(QStringLiteral("node"));
        if (node.isEmpty()) { callback({{"ok", false}, {"message", tr("Install Node.js 22.19 or newer for the NetEase provider.")}}); return; }
        m_process.setProgram(node);
        m_process.setArguments({QStringLiteral("--experimental-strip-types"), helper});
        m_process.start();
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
void OnlineMusicProvider::cancelResolve() { ++m_resolveGeneration; }
void OnlineMusicProvider::resolve(qint64 trackId, const QString &songId, const QString &quality) {
    const auto generation = ++m_resolveGeneration;
    const QString level = quality == "flac" || quality == "flac24bit" ? "lossless" : quality == "320k" ? "exhigh" : "standard";
    request("resolve", {{"songId", songId}, {"level", level}}, [this, generation, trackId](const QJsonObject &response) {
        if (generation != m_resolveGeneration) return;
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
    request("lyric", {{"id", songId}}, [this, trackId](const QJsonObject &response) {
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
            {"source", "NetEase / SPlayer Next adapter"}});
    });
}
