#include "SubsonicProvider.h"
#include <QCryptographicHash>
#include <QJsonDocument>
#include <QJsonArray>
#include <QUrlQuery>
#include <QUuid>
#include <QDir>
#include <QFileInfo>
#include <QSaveFile>
#include <QSettings>
#include <QTimer>
#include <qt6keychain/keychain.h>

namespace {
QString digest(const QString &s) { return QString::fromLatin1(QCryptographicHash::hash(s.toUtf8(), QCryptographicHash::Sha256).toHex()); }
constexpr auto service = "NextKde.KMusic";
constexpr auto credential = "subsonic.server";
}
SubsonicProvider::SubsonicProvider(QObject *parent) : QObject(parent), m_network(this) {}
SubsonicProvider::~SubsonicProvider() {
    ++m_generation; ++m_playGeneration;
    for (auto *reply : m_network.findChildren<QNetworkReply *>()) {
        QObject::disconnect(reply, nullptr, this, nullptr);
        reply->abort();
    }
}
QString SubsonicProvider::scope() const { return digest(m_base.toString() + "\n" + m_user); }
void SubsonicProvider::initialize(const QString &directory) {
    m_cache = directory; QDir().mkpath(directory);
    QTimer::singleShot(0, this, &SubsonicProvider::restore);
}
void SubsonicProvider::resetRequests() {
    ++m_generation; ++m_viewGeneration; cancelPlayback();
    m_connected = false; m_busy = false; m_more = false;
    m_albums.clear(); m_songs.clear(); m_tracks.clear(); m_coverRequests.clear();
}
void SubsonicProvider::connectServer(const QString &address, const QString &user, const QString &password, bool remember) {
    QUrl base(address.trimmed());
    if (!base.isValid() || base.host().isEmpty() || !QStringList{"https", "http"}.contains(base.scheme())
        || !base.userInfo().isEmpty() || base.hasQuery() || base.hasFragment() || user.trimmed().isEmpty() || password.isEmpty()) {
        m_message = tr("Enter a valid HTTP(S) server address, username and password."); emit changed(); return;
    }
    resetRequests(); emit disconnected();
    QString path = base.path(); while (path.endsWith('/')) path.chop(1); base.setPath(path);
    m_base = base; m_user = user.trimmed(); m_password = password; m_remember = remember;
    QSettings().setValue("subsonic/restoreAllowed", false);
    m_busy = true; m_message = tr("Connecting…"); emit changed();
    request("ping", {}, [this](const QJsonObject &) {
        m_connected = true; m_busy = false; m_message.clear(); emit changed();
        if (m_remember) saveCredentials();
        browseAlbums();
    });
}
QUrl SubsonicProvider::endpoint(const QString &method, const QMap<QString, QString> &args) const {
    QUrl url = m_base; url.setPath(m_base.path() + "/rest/" + method + ".view");
    const QString salt = QUuid::createUuid().toString(QUuid::WithoutBraces);
    const auto token = QCryptographicHash::hash((m_password + salt).toUtf8(), QCryptographicHash::Md5).toHex();
    QUrlQuery query; query.addQueryItem("u", m_user); query.addQueryItem("t", QString::fromLatin1(token));
    query.addQueryItem("s", salt); query.addQueryItem("v", "1.16.1"); query.addQueryItem("c", "KMusic"); query.addQueryItem("f", "json");
    for (auto it = args.begin(); it != args.end(); ++it) query.addQueryItem(it.key(), it.value());
    url.setQuery(query); return url;
}
void SubsonicProvider::request(const QString &method, const QMap<QString, QString> &args, std::function<void(QJsonObject)> done) {
    const auto generation = m_generation, view = m_viewGeneration;
    QNetworkRequest req(endpoint(method, args)); req.setTransferTimeout(15000);
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::ManualRedirectPolicy);
    auto *reply = m_network.get(req);
    connect(reply, &QNetworkReply::readyRead, reply, [reply] { if (reply->bytesAvailable() > 8*1024*1024) reply->abort(); });
    connect(reply, &QNetworkReply::finished, this, [this, reply, generation, view, done] {
        reply->deleteLater();
        if (generation != m_generation || view != m_viewGeneration) return;
        const auto root = QJsonDocument::fromJson(reply->readAll()).object().value("subsonic-response").toObject();
        if (reply->error() != QNetworkReply::NoError || root.value("status").toString() != "ok") {
            m_busy = false;
            const int code = root.value("error").toObject().value("code").toInt();
            m_message = code == 40 || code == 41 ? tr("Authentication failed. Check your server credentials.")
                : tr("Server request failed. Check the address, connection and protocol support.");
            if (code == 40 || code == 41) { m_connected = false; cancelPlayback(); emit disconnected(); }
            emit changed(); return;
        }
        done(root);
    });
}
void SubsonicProvider::browseAlbums(bool append) {
    if (!m_connected || m_busy) return;
    ++m_viewGeneration; m_busy = true; m_message.clear(); m_offset = append ? m_albums.size() : 0;
    if (!append) { m_albums.clear(); m_songs.clear(); m_tracks.clear(); }
    emit changed();
    request("getAlbumList2", {{"type", "alphabeticalByName"}, {"size", "50"}, {"offset", QString::number(m_offset)}}, [this](const QJsonObject &root) {
        const auto rows = root.value("albumList2").toObject().value("album").toArray();
        for (const auto &value : rows) {
            const auto a = value.toObject(); const QString art = a.value("coverArt").toString();
            m_albums.append(QVariantMap{{"id", a.value("id").toString()}, {"title", a.value("name").toString()},
                {"artist", a.value("artist").toString()}, {"coverId", art}, {"artwork", QFileInfo::exists(coverPath(art)) ? QUrl::fromLocalFile(coverPath(art)).toString() : QString{}}});
            cover(art);
        }
        m_more = rows.size() == 50; m_busy = false; emit changed();
    });
}
void SubsonicProvider::openAlbum(const QString &id) {
    if (!m_connected || m_busy || id.isEmpty()) return;
    ++m_viewGeneration; m_busy = true; m_message.clear(); m_songs.clear(); m_tracks.clear(); m_more = false; emit changed();
    request("getAlbum", {{"id", id}}, [this](const QJsonObject &root) {
        loadSongs(root.value("album").toObject().value("song").toArray(), false); m_busy = false; emit changed();
    });
}
void SubsonicProvider::search(const QString &query, bool append) {
    if (!m_connected || m_busy) return;
    ++m_viewGeneration; m_busy = true; m_message.clear(); m_offset = append ? m_songs.size() : 0; m_query = query.trimmed();
    if (!append) { m_albums.clear(); m_songs.clear(); m_tracks.clear(); }
    emit changed();
    request("search3", {{"query", m_query}, {"artistCount", "0"}, {"albumCount", "0"}, {"songCount", "50"}, {"songOffset", QString::number(m_offset)}}, [this, append](const QJsonObject &root) {
        const auto rows = root.value("searchResult3").toObject().value("song").toArray();
        loadSongs(rows, append); m_more = rows.size() == 50; m_busy = false; emit changed();
    });
}
void SubsonicProvider::loadSongs(const QJsonArray &items, bool append) {
    if (!append) { m_tracks.clear(); m_songs.clear(); }
    for (const auto &value : items) {
        const auto s = value.toObject(); if (s.value("isDir").toBool() || s.value("isVideo").toBool()) continue;
        TrackRecord t; t.source = "subsonic"; t.providerId = s.value("id").toString(); if (t.providerId.isEmpty()) continue;
        t.sourceData = scope(); t.path = "subsonic:" + scope() + ":" + t.providerId;
        t.title = s.value("title").toString(); t.artist = s.value("artist").toString(); t.album = s.value("album").toString();
        t.durationMs = s.value("duration").toInteger() * 1000; t.format = s.value("suffix").toString();
        const QString art = s.value("coverArt").toString();
        if (QFileInfo::exists(coverPath(art))) t.artworkUrl = QUrl::fromLocalFile(coverPath(art)).toString();
        m_tracks.append(t);
        m_songs.append(QVariantMap{{"id", t.providerId}, {"title", t.title}, {"artist", t.artist}, {"album", t.album}, {"coverId", art}, {"artwork", t.artworkUrl}});
        cover(art);
    }
}
QString SubsonicProvider::coverPath(const QString &id) const { return QDir(m_cache).filePath(digest(scope()+id)+".cover"); }
void SubsonicProvider::cover(const QString &id) {
    if (id.isEmpty() || m_coverRequests.contains(id) || QFileInfo::exists(coverPath(id))) return;
    m_coverRequests.insert(id); const auto generation = m_generation; const auto path = coverPath(id);
    QNetworkRequest req(endpoint("getCoverArt", {{"id", id}, {"size", "400"}})); req.setTransferTimeout(15000);
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::ManualRedirectPolicy);
    auto *reply = m_network.get(req);
    connect(reply, &QNetworkReply::readyRead, reply, [reply] { if (reply->bytesAvailable() > 8*1024*1024) reply->abort(); });
    connect(reply, &QNetworkReply::finished, this, [this, reply, generation, id, path] {
        reply->deleteLater(); if (generation != m_generation) return; m_coverRequests.remove(id);
        const auto data = reply->readAll();
        if (reply->error() != QNetworkReply::NoError || !reply->header(QNetworkRequest::ContentTypeHeader).toString().startsWith("image/") || data.isEmpty() || data.size() > 8*1024*1024) return;
        QSaveFile file(path); if (!file.open(QIODevice::WriteOnly) || file.write(data) != data.size() || !file.commit()) return;
        const auto url = QUrl::fromLocalFile(path).toString();
        for (auto &list : {&m_albums, &m_songs}) for (auto &v : *list) { auto map = v.toMap(); if (map.value("coverId").toString() == id) { map["artwork"] = url; v = map; } }
        for (int i=0; i<m_tracks.size(); ++i) m_tracks[i].artworkUrl = m_songs[i].toMap().value("artwork").toString();
        emit changed();
    });
}
void SubsonicProvider::cancelPlayback() { ++m_playGeneration; if (m_playReply) m_playReply->abort(); m_playReply = nullptr; }
void SubsonicProvider::prepare(qint64 trackId, const QString &identity, const QString &remoteId) {
    cancelPlayback();
    if (!m_connected || identity != scope()) { emit failed(trackId, tr("Connect the original media server and account to play this song.")); return; }
    const auto generation = m_playGeneration;
    QNetworkRequest req(endpoint("stream", {{"id", remoteId}, {"format", "raw"}})); req.setTransferTimeout(60000);
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::ManualRedirectPolicy);
    auto *reply = m_network.get(req); m_playReply = reply;
    const auto path = QDir(m_cache).filePath(digest(scope()+remoteId)+".audio");
    auto file = std::make_shared<QSaveFile>(path);
    if (!file->open(QIODevice::WriteOnly)) { reply->abort(); reply->deleteLater(); emit failed(trackId, tr("Cannot create media playback cache.")); return; }
    connect(reply, &QNetworkReply::readyRead, this, [reply, file] {
        const auto bytes = reply->readAll();
        if (file->size() + bytes.size() > 512LL*1024*1024 || file->write(bytes) != bytes.size()) reply->abort();
    });
    connect(reply, &QNetworkReply::finished, this, [this, reply, file, path, generation, trackId] {
        reply->deleteLater(); if (generation != m_playGeneration) return;
        const auto type = reply->header(QNetworkRequest::ContentTypeHeader).toString();
        if (reply->error() != QNetworkReply::NoError || reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt() != 200
            || type.contains("json") || type.contains("xml") || type.contains("text/") || file->size() <= 0 || !file->commit()) {
            emit failed(trackId, tr("Could not load audio from the media server.")); return;
        }
        emit resolved(trackId, QUrl::fromLocalFile(path));
    });
}
void SubsonicProvider::saveCredentials() {
    const auto generation = m_generation;
    auto *job = new QKeychain::WritePasswordJob(service, this); job->setKey(credential); job->setInsecureFallback(false);
    job->setTextData(QString::fromUtf8(QJsonDocument(QJsonObject{{"server", server()}, {"user", m_user}, {"password", m_password}}).toJson(QJsonDocument::Compact)));
    connect(job, &QKeychain::Job::finished, this, [this, job, generation] {
        if (generation != m_generation) return;
        const bool ok = job->error() == QKeychain::NoError;
        QSettings().setValue("subsonic/restoreAllowed", ok);
        if (!ok) { m_message = tr("Connected for this session. System credential storage is unavailable."); emit changed(); }
    }); job->start();
}
void SubsonicProvider::restore() {
    if (!QSettings().value("subsonic/restoreAllowed", false).toBool()) return;
    const auto generation = m_generation;
    auto *job = new QKeychain::ReadPasswordJob(service, this); job->setKey(credential); job->setInsecureFallback(false);
    connect(job, &QKeychain::Job::finished, this, [this, job, generation] {
        if (generation != m_generation) return;
        if (job->error() != QKeychain::NoError) { m_message = tr("Could not restore server credentials. Please reconnect."); emit changed(); return; }
        const auto data = QJsonDocument::fromJson(job->textData().toUtf8()).object();
        connectServer(data.value("server").toString(), data.value("user").toString(), data.value("password").toString(), true);
    }); job->start();
}
void SubsonicProvider::disconnectServer() {
    resetRequests(); m_password.clear(); m_message.clear();
    QSettings().setValue("subsonic/restoreAllowed", false);
    auto *job = new QKeychain::DeletePasswordJob(service, this); job->setKey(credential); job->setInsecureFallback(false);
    connect(job, &QKeychain::Job::finished, this, [this, job] {
        if (job->error() != QKeychain::NoError && job->error() != QKeychain::EntryNotFound) { m_message = tr("Disconnected. Stored credentials could not be deleted; retry disconnect."); emit changed(); }
    }); job->start(); emit changed(); emit disconnected();
}
