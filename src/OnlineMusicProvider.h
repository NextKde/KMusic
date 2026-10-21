#pragma once
#include "MusicTypes.h"
#include <QObject>
#include <QProcess>
#include <QJsonObject>
#include <QHash>
#include <QUrl>
#include <functional>

// Native adapter to the attributed SPlayer Next NetEase helper. The QML layer
// sees metadata and states; credentials and transient URLs stay in adapters.
class OnlineMusicProvider final : public QObject {
    Q_OBJECT
public:
    using Callback = std::function<void(const QJsonObject &)>;
    void accountRequest(const QString &action, const QJsonObject &params, Callback callback) {
        if (action == "sessionRestore") m_sessionCookie = params.value("cookie").toString();
        else if (action == "logout") m_sessionCookie.clear();
        request(action, params, std::move(callback));
    }
    explicit OnlineMusicProvider(QObject *parent = nullptr);
    ~OnlineMusicProvider() override;
    bool searching() const;
    QString errorMessage() const;
    void search(const QString &query, int limit = 30);
    void resolve(qint64 trackId, const QString &songId, const QString &quality);
    void cancelResolve();
    void loadLyrics(qint64 trackId, const QString &songId);
    void loadDetail(const QString &songId);
    void loadNewAlbums();
    void loadAlbumTracks(const QString &albumId);
    static QList<TrackRecord> parseNeteaseSearch(const QByteArray &payload,
        QString *errorMessage = nullptr, const QString &query = {});
signals:
    void sessionExpired();
    void searchingChanged();
    void resultsReady(const QList<TrackRecord> &tracks);
    void errorMessageChanged();
    void resolved(qint64 trackId, const QUrl &url, bool trial, const QString &level);
    void resolveFailed(qint64 trackId, const QString &message);
    void lyricsResolved(qint64 trackId, const QString &text, const QString &error);
    void detailReady(const QVariantMap &detail);
    void newAlbumsReady(const QVariantList &albums, const QString &error);
    void albumTracksReady(const QString &albumId, const QList<TrackRecord> &tracks, const QString &error, const QVariantMap &album);
private:
    void request(const QString &action, const QJsonObject &params, Callback callback);
    void readOutput();
    void failPending(const QString &message);
    void setSearching(bool searching);
    void setError(const QString &message);
    QProcess m_process;
    QByteArray m_buffer;
    QHash<qint64, Callback> m_pending;
    QString m_errorMessage;
    QString m_sessionCookie; // private memory only, used to rehydrate a restarted helper
    qint64 m_sequence = 0;
    quint64 m_generation = 0;
    quint64 m_resolveGeneration = 0;
    quint64 m_lyricGeneration = 0;
    quint64 m_discoveryGeneration = 0;
    quint64 m_albumGeneration = 0;
    bool m_searching = false;
};
