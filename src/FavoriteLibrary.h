#pragma once

#include <QList>
#include <QObject>
#include <QVariantList>
#include <QVariantMap>

// 收藏音乐库：按音源（网易云 / Bilibili）分组管理自定义收藏目录。
// 每个目录可以自由创建、重命名、删除，目录内保存曲目快照（不依赖在线接口）。
// 数据落地为 JSON，支持导入导出，便于备份与迁移。
class FavoriteLibrary : public QObject {
    Q_OBJECT

public:
    explicit FavoriteLibrary(QObject *parent = nullptr);

    Q_PROPERTY(int revision READ revision NOTIFY changed)
    Q_PROPERTY(QString storagePath READ storagePath CONSTANT)

    int revision() const { return m_revision; }
    QString storagePath() const;

    Q_INVOKABLE QVariantList folders(const QString &source) const;
    Q_INVOKABLE QVariantList tracks(const QString &folderId) const;
    Q_INVOKABLE QString folderName(const QString &folderId) const;
    Q_INVOKABLE QString createFolder(const QString &source, const QString &name);
    Q_INVOKABLE bool renameFolder(const QString &folderId, const QString &name);
    Q_INVOKABLE bool removeFolder(const QString &folderId);
    Q_INVOKABLE bool isFavorite(const QString &source, const QString &trackId) const;
    Q_INVOKABLE bool toggleFavorite(const QVariantMap &track);
    Q_INVOKABLE bool addToFolder(const QString &folderId, const QVariantMap &track);
    Q_INVOKABLE bool removeFromFolder(const QString &folderId, const QString &trackId);
    Q_INVOKABLE QString folderContaining(const QString &source, const QString &trackId) const;
    Q_INVOKABLE int totalTracks(const QString &source) const;
    Q_INVOKABLE bool exportTo(const QUrl &url);
    Q_INVOKABLE bool importFrom(const QUrl &url, bool merge = true);

signals:
    void changed();
    void errorOccurred(const QString &message);

private:
    struct Track {
        QString id;
        QString source;
        QString title;
        QString artist;
        QString album;
        QString artworkUrl;
        QString url;
        qint64 durationMs = 0;
        qint64 addedAt = 0;
        QVariantMap toMap() const;
        static Track fromMap(const QVariantMap &map);
    };

    struct Folder {
        QString id;
        QString name;
        QString source;
        QList<Track> tracks;
        QVariantMap toMap(bool withTracks) const;
    };

    void load();
    bool save();
    Folder *findFolder(const QString &folderId);
    const Folder *findFolder(const QString &folderId) const;
    QString defaultFolderId(const QString &source);
    void touch();

    QList<Folder> m_folders;
    int m_revision = 0;
    bool m_loaded = false;
};
