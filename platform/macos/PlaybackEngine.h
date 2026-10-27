#pragma once

#include <QObject>
#include <QTimer>
#include <QUrl>
#include <atomic>

class QMediaPlayer;
class QAudioOutput;
class QNetworkAccessManager;
class QNetworkReply;
class QFile;
class LocalMediaProxy;

// macOS 版播放后端：使用 Qt Multimedia（AVFoundation / FFmpeg 后端）。
// 公共接口与原 GStreamer 实现保持一致，MusicController 与 QML 层无需改动。
class PlaybackEngine : public QObject {
    Q_OBJECT

public:
    explicit PlaybackEngine(QObject *parent = nullptr);
    ~PlaybackEngine() override;

    quint64 generation() const { return m_generation.load(std::memory_order_acquire); }
    int naturalEosCount() const { return m_naturalEosCount; }
    int ignoredEosCount() const { return m_ignoredEosCount; }
    bool available() const;
    QString backendName() const;
    QString state() const;
    QString errorMessage() const;
    QUrl source() const;
    qint64 positionMs() const;
    qint64 durationMs() const;
    bool seekable() const;
    double volume() const;
    int bufferingPercent() const;
    double downloadProgress() const;
    void setDownloadDirectory(const QString &directory);

    bool load(const QUrl &source, bool autoPlay = true, qint64 startPositionMs = 0,
              const QByteArray &userAgent = {}, const QUrl &referer = {});
    void play();
    void pause();
    void stop();
    void seek(qint64 positionMs);
    void setVolume(double volume);

signals:
    void availableChanged();
    void stateChanged();
    void errorMessageChanged();
    void sourceChanged();
    void positionChanged();
    void durationChanged();
    void seekableChanged();
    void volumeChanged();
    void endOfStream(quint64 generation);
    void seeked(qint64 positionMs);
    void bufferingChanged();
    void downloadCompleted(const QString &path);

private slots:
    void updatePosition();

private:
    void onMediaStatusChanged(int status);
    void onPlaybackStateChanged(int state);
    void onPlayerError(int error, const QString &message);
    void setState(const QString &state);
    void setErrorMessage(const QString &message);
    void setDuration(qint64 durationMs);
    void updateSeekable();
    void updateDownloadProgress();
    void startDownload(const QUrl &source, const QByteArray &userAgent, const QUrl &referer);
    void stopDownload(bool keepFile);
    void finishDownload();

    std::atomic<quint64> m_generation{0};
    int m_naturalEosCount = 0;
    int m_ignoredEosCount = 0;
    bool m_requestedPlaying = false;

    QMediaPlayer *m_player = nullptr;
    QAudioOutput *m_output = nullptr;
    LocalMediaProxy *m_proxy = nullptr;
    QNetworkAccessManager *m_nam = nullptr;

    QTimer m_positionTimer;
    QTimer m_downloadTimer;
    QTimer m_loadingTimeout;

    QString m_state = QStringLiteral("Stopped");
    QString m_errorMessage;
    QString m_backendName;
    QUrl m_source;
    qint64 m_positionMs = 0;
    qint64 m_durationMs = 0;
    qint64 m_pendingPositionMs = -1;
    qint64 m_pausedPositionMs = -1;
    bool m_seekable = false;
    double m_volume = 1.0;
    int m_bufferingPercent = 100;
    double m_downloadProgress = -1;
    bool m_downloading = false;
    bool m_downloadFailed = false;

    QString m_downloadTemplate;
    QString m_downloadPath;
    QString m_completedDownload;
    QNetworkReply *m_downloadReply = nullptr;
    QFile *m_downloadFile = nullptr;
};
