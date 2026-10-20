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
    explicit OnlineMusicProvider(QObject *parent = nullptr);
    ~OnlineMusicProvider() override;
    bool searching() const;
    QString errorMessage() const;
    void search(const QString &query, int limit = 30);
    void resolve(qint64 trackId, const QString &songId, const QString &quality);
    void cancelResolve();
    void loadLyrics(qint64 trackId, const QString &songId);
    void loadDetail(const QString &songId);
    static QList<TrackRecord> parseNeteaseSearch(const QByteArray &payload,
        QString *errorMessage = nullptr, const QString &query = {});
signals:
    void searchingChanged();
    void resultsReady(const QList<TrackRecord> &tracks);
    void errorMessageChanged();
    void resolved(qint64 trackId, const QUrl &url, bool trial, const QString &level);
    void resolveFailed(qint64 trackId, const QString &message);
    void lyricsResolved(qint64 trackId, const QString &text, const QString &error);
    void detailReady(const QVariantMap &detail);
private:
    using Callback = std::function<void(const QJsonObject &)>;
    void request(const QString &action, const QJsonObject &params, Callback callback);
    void readOutput();
    void failPending(const QString &message);
    void setSearching(bool searching);
    void setError(const QString &message);
    QProcess m_process;
    QByteArray m_buffer;
    QHash<qint64, Callback> m_pending;
    QString m_errorMessage;
    qint64 m_sequence = 0;
    quint64 m_generation = 0;
    quint64 m_resolveGeneration = 0;
    quint64 m_lyricGeneration = 0;
    bool m_searching = false;
};
