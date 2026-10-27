#include "FavoriteLibrary.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QStandardPaths>
#include <QUuid>

namespace {

QString trackKey(const QString &source, const QString &id)
{
    return source + QLatin1Char(':') + id;
}

} // namespace

QVariantMap FavoriteLibrary::Track::toMap() const
{
    return {
        {QStringLiteral("id"), id},
        {QStringLiteral("source"), source},
        {QStringLiteral("title"), title},
        {QStringLiteral("artist"), artist},
        {QStringLiteral("album"), album},
        {QStringLiteral("artworkUrl"), artworkUrl},
        {QStringLiteral("url"), url},
        {QStringLiteral("durationMs"), durationMs},
        {QStringLiteral("addedAt"), addedAt},
    };
}

FavoriteLibrary::Track FavoriteLibrary::Track::fromMap(const QVariantMap &map)
{
    Track track;
    track.id = map.value(QStringLiteral("id")).toString();
    track.source = map.value(QStringLiteral("source")).toString();
    track.title = map.value(QStringLiteral("title")).toString();
    track.artist = map.value(QStringLiteral("artist")).toString();
    track.album = map.value(QStringLiteral("album")).toString();
    track.artworkUrl = map.value(QStringLiteral("artworkUrl")).toString();
    track.url = map.value(QStringLiteral("url")).toString();
    track.durationMs = map.value(QStringLiteral("durationMs")).toLongLong();
    track.addedAt = map.value(QStringLiteral("addedAt")).toLongLong();
    return track;
}

QVariantMap FavoriteLibrary::Folder::toMap(bool withTracks) const
{
    QVariantMap map{
        {QStringLiteral("id"), id},
        {QStringLiteral("name"), name},
        {QStringLiteral("source"), source},
        {QStringLiteral("count"), tracks.size()},
    };
    if (withTracks) {
        QVariantList list;
        for (const Track &track : tracks)
            list.append(track.toMap());
        map.insert(QStringLiteral("tracks"), list);
    }
    return map;
}

FavoriteLibrary::FavoriteLibrary(QObject *parent)
    : QObject(parent)
{
    load();
}

QString FavoriteLibrary::storagePath() const
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    return QDir(dir).filePath(QStringLiteral("favorites.json"));
}

void FavoriteLibrary::load()
{
    m_folders.clear();
    QFile file(storagePath());
    if (file.exists() && file.open(QIODevice::ReadOnly)) {
        const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
        if (document.isObject()) {
            const QJsonArray folders = document.object().value(QStringLiteral("folders")).toArray();
            for (const QJsonValue &value : folders) {
                const QJsonObject object = value.toObject();
                Folder folder;
                folder.id = object.value(QStringLiteral("id")).toString();
                folder.name = object.value(QStringLiteral("name")).toString();
                folder.source = object.value(QStringLiteral("source")).toString();
                if (folder.id.isEmpty())
                    folder.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
                if (folder.source.isEmpty())
                    folder.source = QStringLiteral("netease");
                const QJsonArray tracks = object.value(QStringLiteral("tracks")).toArray();
                for (const QJsonValue &trackValue : tracks) {
                    Track track = Track::fromMap(trackValue.toObject().toVariantMap());
                    if (!track.id.isEmpty())
                        folder.tracks.append(track);
                }
                m_folders.append(folder);
            }
        }
    }
    m_loaded = true;
}

bool FavoriteLibrary::save()
{
    const QString path = storagePath();
    QDir().mkpath(QFileInfo(path).absolutePath());

    QJsonArray folders;
    for (const Folder &folder : m_folders)
        folders.append(QJsonObject::fromVariantMap(folder.toMap(true)));

    QJsonObject root{
        {QStringLiteral("version"), 1},
        {QStringLiteral("updatedAt"), QDateTime::currentMSecsSinceEpoch()},
        {QStringLiteral("folders"), folders},
    };

    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly)) {
        emit errorOccurred(tr("无法写入收藏配置：%1").arg(path));
        return false;
    }
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    if (!file.commit()) {
        emit errorOccurred(tr("收藏配置保存失败：%1").arg(path));
        return false;
    }
    return true;
}

void FavoriteLibrary::touch()
{
    ++m_revision;
    emit changed();
}

FavoriteLibrary::Folder *FavoriteLibrary::findFolder(const QString &folderId)
{
    for (Folder &folder : m_folders) {
        if (folder.id == folderId)
            return &folder;
    }
    return nullptr;
}

const FavoriteLibrary::Folder *FavoriteLibrary::findFolder(const QString &folderId) const
{
    for (const Folder &folder : m_folders) {
        if (folder.id == folderId)
            return &folder;
    }
    return nullptr;
}

QVariantList FavoriteLibrary::folders(const QString &source) const
{
    QVariantList list;
    for (const Folder &folder : m_folders) {
        if (folder.source == source)
            list.append(folder.toMap(false));
    }
    return list;
}

QVariantList FavoriteLibrary::tracks(const QString &folderId) const
{
    QVariantList list;
    if (const Folder *folder = findFolder(folderId)) {
        for (const Track &track : folder->tracks)
            list.append(track.toMap());
    }
    return list;
}

QString FavoriteLibrary::folderName(const QString &folderId) const
{
    const Folder *folder = findFolder(folderId);
    return folder ? folder->name : QString();
}

QString FavoriteLibrary::defaultFolderId(const QString &source)
{
    for (const Folder &folder : m_folders) {
        if (folder.source == source)
            return folder.id;
    }
    Folder folder;
    folder.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    folder.name = tr("默认收藏");
    folder.source = source;
    m_folders.append(folder);
    save();
    return folder.id;
}

QString FavoriteLibrary::createFolder(const QString &source, const QString &name)
{
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty())
        return {};
    Folder folder;
    folder.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    folder.name = trimmed;
    folder.source = source;
    m_folders.append(folder);
    save();
    touch();
    return folder.id;
}

bool FavoriteLibrary::renameFolder(const QString &folderId, const QString &name)
{
    Folder *folder = findFolder(folderId);
    if (!folder || name.trimmed().isEmpty())
        return false;
    folder->name = name.trimmed();
    save();
    touch();
    return true;
}

bool FavoriteLibrary::removeFolder(const QString &folderId)
{
    for (int i = 0; i < m_folders.size(); ++i) {
        if (m_folders.at(i).id == folderId) {
            m_folders.removeAt(i);
            save();
            touch();
            return true;
        }
    }
    return false;
}

QString FavoriteLibrary::folderContaining(const QString &source, const QString &trackId) const
{
    for (const Folder &folder : m_folders) {
        if (folder.source != source)
            continue;
        for (const Track &track : folder.tracks) {
            if (track.id == trackId)
                return folder.id;
        }
    }
    return {};
}

bool FavoriteLibrary::isFavorite(const QString &source, const QString &trackId) const
{
    return !folderContaining(source, trackId).isEmpty();
}

bool FavoriteLibrary::addToFolder(const QString &folderId, const QVariantMap &trackMap)
{
    Folder *folder = findFolder(folderId);
    if (!folder)
        return false;
    Track track = Track::fromMap(trackMap);
    if (track.id.isEmpty())
        return false;
    if (track.source.isEmpty())
        track.source = folder->source;
    if (track.addedAt == 0)
        track.addedAt = QDateTime::currentMSecsSinceEpoch();
    for (const Track &existing : folder->tracks) {
        if (existing.id == track.id)
            return true; // 已在目录里
    }
    folder->tracks.append(track);
    save();
    touch();
    return true;
}

bool FavoriteLibrary::removeFromFolder(const QString &folderId, const QString &trackId)
{
    Folder *folder = findFolder(folderId);
    if (!folder)
        return false;
    for (int i = 0; i < folder->tracks.size(); ++i) {
        if (folder->tracks.at(i).id == trackId) {
            folder->tracks.removeAt(i);
            save();
            touch();
            return true;
        }
    }
    return false;
}

bool FavoriteLibrary::toggleFavorite(const QVariantMap &trackMap)
{
    Track track = Track::fromMap(trackMap);
    if (track.id.isEmpty())
        return false;
    if (track.source.isEmpty())
        return false;

    const QString existing = folderContaining(track.source, track.id);
    if (!existing.isEmpty())
        return removeFromFolder(existing, track.id);
    return addToFolder(defaultFolderId(track.source), trackMap);
}

int FavoriteLibrary::totalTracks(const QString &source) const
{
    int total = 0;
    for (const Folder &folder : m_folders) {
        if (folder.source == source)
            total += folder.tracks.size();
    }
    return total;
}

bool FavoriteLibrary::exportTo(const QUrl &url)
{
    const QString target = url.isLocalFile() ? url.toLocalFile() : url.toString();
    if (target.isEmpty())
        return false;
    save();
    QFile::remove(target);
    if (!QFile::copy(storagePath(), target)) {
        emit errorOccurred(tr("导出失败：%1").arg(target));
        return false;
    }
    return true;
}

bool FavoriteLibrary::importFrom(const QUrl &url, bool merge)
{
    const QString source = url.isLocalFile() ? url.toLocalFile() : url.toString();
    QFile file(source);
    if (!file.open(QIODevice::ReadOnly)) {
        emit errorOccurred(tr("无法读取文件：%1").arg(source));
        return false;
    }
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    if (!document.isObject()) {
        emit errorOccurred(tr("收藏配置格式不正确"));
        return false;
    }
    const QJsonArray folders = document.object().value(QStringLiteral("folders")).toArray();
    if (folders.isEmpty()) {
        emit errorOccurred(tr("收藏配置里没有目录"));
        return false;
    }

    if (!merge)
        m_folders.clear();

    for (const QJsonValue &value : folders) {
        const QJsonObject object = value.toObject();
        Folder folder;
        folder.id = object.value(QStringLiteral("id")).toString();
        folder.name = object.value(QStringLiteral("name")).toString();
        folder.source = object.value(QStringLiteral("source")).toString();
        if (folder.id.isEmpty())
            folder.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
        if (folder.source.isEmpty())
            folder.source = QStringLiteral("netease");
        if (folder.name.isEmpty())
            folder.name = tr("导入的收藏");

        const QJsonArray tracks = object.value(QStringLiteral("tracks")).toArray();
        for (const QJsonValue &trackValue : tracks) {
            Track track = Track::fromMap(trackValue.toObject().toVariantMap());
            if (!track.id.isEmpty())
                folder.tracks.append(track);
        }

        Folder *existing = findFolder(folder.id);
        if (existing && merge) {
            for (const Track &track : folder.tracks) {
                bool found = false;
                for (const Track &current : existing->tracks) {
                    if (current.id == track.id) {
                        found = true;
                        break;
                    }
                }
                if (!found)
                    existing->tracks.append(track);
            }
        } else {
            m_folders.append(folder);
        }
    }

    save();
    touch();
    return true;
}
