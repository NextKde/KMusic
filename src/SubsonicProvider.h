#pragma once
#include "MusicTypes.h"
#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonObject>
#include <QVariantList>
#include <QPointer>
#include <QSet>
#include <memory>
#include <functional>

class SubsonicProvider : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool connected READ connected NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)
    Q_PROPERTY(QString message READ message NOTIFY changed)
    Q_PROPERTY(QString server READ server NOTIFY changed)
    Q_PROPERTY(QString username READ username NOTIFY changed)
    Q_PROPERTY(QVariantList albums READ albums NOTIFY changed)
    Q_PROPERTY(QVariantList songs READ songs NOTIFY changed)
    Q_PROPERTY(bool more READ more NOTIFY changed)
public:
    explicit SubsonicProvider(QObject *parent = nullptr);
    ~SubsonicProvider() override;
    bool connected() const { return m_connected; }
    bool busy() const { return m_busy; }
    QString message() const { return m_message; }
    QString server() const { return m_base.toString(); }
    QString username() const { return m_user; }
    QString scope() const;
    QVariantList albums() const { return m_albums; }
    QVariantList songs() const { return m_songs; }
    bool more() const { return m_more; }
    void initialize(const QString &cacheDirectory);
    Q_INVOKABLE void connectServer(const QString &address, const QString &user, const QString &password, bool remember);
    Q_INVOKABLE void disconnectServer();
    Q_INVOKABLE void browseAlbums(bool append = false);
    Q_INVOKABLE void openAlbum(const QString &id);
    Q_INVOKABLE void search(const QString &query, bool append = false);
    QList<TrackRecord> tracks() const { return m_tracks; }
    void prepare(qint64 trackId, const QString &scope, const QString &remoteId);
    void cancelPlayback();
signals:
    void changed();
    void resolved(qint64 trackId, const QUrl &url);
    void failed(qint64 trackId, const QString &message);
    void disconnected();
private:
    QUrl endpoint(const QString &method, const QMap<QString, QString> &args = {}) const;
    void request(const QString &method, const QMap<QString, QString> &args, std::function<void(QJsonObject)> done);
    void loadSongs(const QJsonArray &items, bool append);
    void cover(const QString &id);
    QString coverPath(const QString &id) const;
    void saveCredentials();
    void restore();
    void resetRequests();
    QNetworkAccessManager m_network;
    QUrl m_base;
    QString m_user, m_password, m_message, m_cache, m_query;
    bool m_connected = false, m_busy = false, m_more = false, m_remember = false;
    int m_offset = 0;
    quint64 m_generation = 0, m_viewGeneration = 0, m_playGeneration = 0;
    QVariantList m_albums, m_songs;
    QList<TrackRecord> m_tracks;
    QSet<QString> m_coverRequests;
    QPointer<QNetworkReply> m_playReply;
};
