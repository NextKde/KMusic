#include "PlaybackEngine.h"

#include <QAudioOutput>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QHostAddress>
#include <QMediaPlayer>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTcpServer>
#include <QTcpSocket>
#include <QTemporaryFile>
#include <QUuid>

#include <algorithm>

// 本地回环 HTTP 代理：QMediaPlayer 不支持自定义请求头，而在线音源（B 站、网易云）
// 必须带 Referer / User-Agent 才能取流。这里在进程内起一个只监听 127.0.0.1 的
// 转发服务，把请求头补齐后原样转发，并完整支持 Range 请求（拖动进度条需要）。
class LocalMediaProxy : public QObject {
public:
    explicit LocalMediaProxy(QObject *parent = nullptr) : QObject(parent)
    {
        m_server = new QTcpServer(this);
        m_nam = new QNetworkAccessManager(this);
        m_server->listen(QHostAddress::LocalHost, 0);
        connect(m_server, &QTcpServer::newConnection, this, &LocalMediaProxy::onNewConnection);
    }

    bool isValid() const { return m_server && m_server->isListening(); }

    QUrl open(const QUrl &target, const QByteArray &userAgent, const QUrl &referer)
    {
        if (!isValid())
            return {};
        const QString token = QUuid::createUuid().toString(QUuid::WithoutBraces);
        Target entry;
        entry.url = target;
        entry.userAgent = userAgent;
        entry.referer = referer;
        m_targets.insert(token, entry);

        QUrl local;
        local.setScheme(QStringLiteral("http"));
        local.setHost(QStringLiteral("127.0.0.1"));
        local.setPort(m_server->serverPort());
        local.setPath(QStringLiteral("/") + token);
        return local;
    }

    void reset() { m_targets.clear(); }

private:
    struct Target {
        QUrl url;
        QByteArray userAgent;
        QUrl referer;
    };

    void onNewConnection()
    {
        while (QTcpSocket *socket = m_server->nextPendingConnection()) {
            connect(socket, &QTcpSocket::readyRead, this, [this, socket] { onReadyRead(socket); });
            connect(socket, &QTcpSocket::disconnected, socket, &QObject::deleteLater);
        }
    }

    void onReadyRead(QTcpSocket *socket)
    {
        QByteArray &buffer = m_buffers[socket];
        buffer += socket->readAll();
        const int headerEnd = buffer.indexOf("\r\n\r\n");
        if (headerEnd < 0 || buffer.size() > 64 * 1024)
            return;
        const QByteArray head = buffer.left(headerEnd);
        m_buffers.remove(socket);

        const QList<QByteArray> lines = head.split('\n');
        const QList<QByteArray> requestLine = lines.value(0).trimmed().split(' ');
        if (requestLine.size() < 2) {
            respondError(socket, 400);
            return;
        }
        const QString token = QString::fromUtf8(requestLine.at(1).mid(1));
        if (!m_targets.contains(token)) {
            respondError(socket, 404);
            return;
        }
        const Target target = m_targets.value(token);

        QByteArray range;
        for (int i = 1; i < lines.size(); ++i) {
            const QByteArray line = lines.at(i).trimmed();
            const int colon = line.indexOf(':');
            if (colon <= 0)
                continue;
            if (line.left(colon).toLower() == "range")
                range = line.mid(colon + 1).trimmed();
        }

        QNetworkRequest request(target.url);
        if (!target.userAgent.isEmpty())
            request.setRawHeader("User-Agent", target.userAgent);
        if (target.referer.isValid() && !target.referer.isEmpty())
            request.setRawHeader("Referer", target.referer.toEncoded());
        if (!range.isEmpty())
            request.setRawHeader("Range", range);
        request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                             QNetworkRequest::NoLessSafeRedirectPolicy);

        QNetworkReply *reply = m_nam->get(request);
        auto headersWritten = std::make_shared<bool>(false);

        connect(reply, &QNetworkReply::readyRead, socket, [reply, socket, headersWritten] {
            if (!*headersWritten) {
                *headersWritten = true;
                const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
                QByteArray head;
                head += "HTTP/1.1 " + QByteArray::number(status > 0 ? status : 200)
                    + (status == 206 ? " Partial Content" : " OK") + "\r\n";
                QByteArray contentType = reply->header(QNetworkRequest::ContentTypeHeader)
                                             .toString().toUtf8();
                if (contentType.isEmpty())
                    contentType = "application/octet-stream";
                head += "Content-Type: " + contentType + "\r\n";
                const QVariant length = reply->header(QNetworkRequest::ContentLengthHeader);
                if (length.isValid())
                    head += "Content-Length: " + QByteArray::number(length.toLongLong()) + "\r\n";
                const QByteArray contentRange = reply->rawHeader("Content-Range");
                if (!contentRange.isEmpty())
                    head += "Content-Range: " + contentRange + "\r\n";
                head += "Accept-Ranges: bytes\r\nConnection: close\r\n\r\n";
                socket->write(head);
            }
            socket->write(reply->readAll());
        });

        connect(reply, &QNetworkReply::finished, socket, [reply, socket, headersWritten] {
            if (!*headersWritten) {
                const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
                respondError(socket, status > 0 ? status : 502);
            }
            socket->disconnectFromHost();
            reply->deleteLater();
        });
    }

    static void respondError(QTcpSocket *socket, int status)
    {
        const QByteArray body = "upstream error";
        QByteArray head = "HTTP/1.1 " + QByteArray::number(status) + " Error\r\n";
        head += "Content-Type: text/plain\r\nContent-Length: "
            + QByteArray::number(body.size()) + "\r\nConnection: close\r\n\r\n";
        socket->write(head + body);
        socket->disconnectFromHost();
    }

    QTcpServer *m_server = nullptr;
    QNetworkAccessManager *m_nam = nullptr;
    QHash<QString, Target> m_targets;
    QHash<QTcpSocket *, QByteArray> m_buffers;
};

PlaybackEngine::PlaybackEngine(QObject *parent)
    : QObject(parent)
{
    m_output = new QAudioOutput(this);
    m_player = new QMediaPlayer(this);
    m_player->setAudioOutput(m_output);
    m_output->setVolume(1.0f);
    m_proxy = new LocalMediaProxy(this);
    m_nam = new QNetworkAccessManager(this);
    m_backendName = QStringLiteral("Qt Multimedia (AVFoundation)");

    connect(m_player, &QMediaPlayer::positionChanged, this, [this](qint64 position) {
        if (m_pendingPositionMs >= 0)
            return;
        if (position != m_positionMs) {
            m_positionMs = position;
            emit positionChanged();
        }
    });
    connect(m_player, &QMediaPlayer::durationChanged, this, [this](qint64 duration) {
        setDuration(duration);
        updateSeekable();
    });
    connect(m_player, &QMediaPlayer::seekableChanged, this, [this](bool) { updateSeekable(); });
    connect(m_player, &QMediaPlayer::bufferProgressChanged, this, [this](float progress) {
        const int percent = std::clamp(int(progress * 100.0f), 0, 100);
        if (percent != m_bufferingPercent) {
            m_bufferingPercent = percent;
            emit bufferingChanged();
        }
    });
    connect(m_player, &QMediaPlayer::mediaStatusChanged, this, [this](QMediaPlayer::MediaStatus status) {
        onMediaStatusChanged(int(status));
    });
    connect(m_player, &QMediaPlayer::playbackStateChanged, this, [this](QMediaPlayer::PlaybackState state) {
        onPlaybackStateChanged(int(state));
    });
    connect(m_player, &QMediaPlayer::errorOccurred, this,
            [this](QMediaPlayer::Error error, const QString &message) {
        onPlayerError(int(error), message);
    });

    m_positionTimer.setInterval(250);
    connect(&m_positionTimer, &QTimer::timeout, this, &PlaybackEngine::updatePosition);

    m_downloadTimer.setInterval(500);
    connect(&m_downloadTimer, &QTimer::timeout, this, &PlaybackEngine::updateDownloadProgress);

    m_loadingTimeout.setInterval(30000);
    m_loadingTimeout.setSingleShot(true);
    connect(&m_loadingTimeout, &QTimer::timeout, this, [this] {
        m_requestedPlaying = false;
        m_player->stop();
        setErrorMessage(tr("Playback timed out. Check the network or audio output, then retry."));
        setState(QStringLiteral("Error"));
    });
}

PlaybackEngine::~PlaybackEngine()
{
    if (m_player)
        m_player->stop();
    stopDownload(false);
    finishDownload();
}

bool PlaybackEngine::available() const { return m_player != nullptr; }
QString PlaybackEngine::backendName() const { return m_backendName; }
QString PlaybackEngine::state() const { return m_state; }
QString PlaybackEngine::errorMessage() const { return m_errorMessage; }
QUrl PlaybackEngine::source() const { return m_source; }
qint64 PlaybackEngine::positionMs() const { return m_positionMs; }
qint64 PlaybackEngine::durationMs() const { return m_durationMs; }
bool PlaybackEngine::seekable() const { return m_seekable; }
double PlaybackEngine::volume() const { return m_volume; }
int PlaybackEngine::bufferingPercent() const { return m_bufferingPercent; }
double PlaybackEngine::downloadProgress() const { return m_downloadProgress; }

void PlaybackEngine::setDownloadDirectory(const QString &directory)
{
    QTemporaryFile probe(QDir(directory).filePath(QStringLiteral(".write-test-XXXXXX")));
    if (m_source.isEmpty() && QDir().mkpath(directory) && probe.open())
        m_downloadTemplate = QDir(directory).filePath(QStringLiteral("stream-XXXXXX"));
}

bool PlaybackEngine::load(const QUrl &source, bool autoPlay, qint64 startPositionMs,
                          const QByteArray &userAgent, const QUrl &referer)
{
    if (!m_player)
        return false;
    m_generation.fetch_add(1, std::memory_order_acq_rel);
    m_requestedPlaying = false;
    m_loadingTimeout.stop();
    m_player->stop();
    m_player->setSource(QUrl());
    m_proxy->reset();
    stopDownload(false);
    finishDownload();

    if (source.isEmpty() || !source.isValid()) {
        setErrorMessage(QStringLiteral("Invalid audio URL"));
        setState(QStringLiteral("Error"));
        return false;
    }
    if (source.isLocalFile() && !QFileInfo::exists(source.toLocalFile())) {
        setErrorMessage(QStringLiteral("Audio file no longer exists: %1").arg(source.toLocalFile()));
        setState(QStringLiteral("Error"));
        return false;
    }

    const bool remote = source.scheme() == QLatin1String("http")
        || source.scheme() == QLatin1String("https");
    m_bufferingPercent = remote ? 0 : 100;
    emit bufferingChanged();

    m_source = source;
    m_positionMs = std::max<qint64>(0, startPositionMs);
    m_pendingPositionMs = m_positionMs > 0 ? m_positionMs : -1;
    m_pausedPositionMs = -1;
    m_durationMs = 0;
    m_seekable = false;
    m_requestedPlaying = autoPlay;
    setErrorMessage({});
    setState(QStringLiteral("Loading"));
    emit sourceChanged();
    emit positionChanged();
    emit durationChanged();
    emit seekableChanged();

    QUrl playUrl = source;
    if (remote && (!userAgent.isEmpty() || (referer.isValid() && !referer.isEmpty()))) {
        const QUrl proxied = m_proxy->open(source, userAgent, referer);
        if (!proxied.isEmpty())
            playUrl = proxied;
    }
    if (remote && !m_downloadTemplate.isEmpty())
        startDownload(source, userAgent, referer);

    m_player->setSource(playUrl);
    return true;
}

void PlaybackEngine::play()
{
    if (!m_player || m_source.isEmpty())
        return;
    m_generation.fetch_add(1, std::memory_order_acq_rel);
    m_requestedPlaying = true;
    setState(QStringLiteral("Loading"));
    if (m_pendingPositionMs >= 0)
        return;
    // 部分后端在暂停恢复时会回到 0，这里显式把暂停时的位置补回去
    if (m_pausedPositionMs > 0 && m_player->position() + 1000 < m_pausedPositionMs)
        m_player->setPosition(m_pausedPositionMs);
    m_player->play();
}

void PlaybackEngine::pause()
{
    if (!m_player || m_source.isEmpty())
        return;
    m_generation.fetch_add(1, std::memory_order_acq_rel);
    m_requestedPlaying = false;
    updatePosition();
    m_pausedPositionMs = m_player->position();
    m_player->pause();
    setState(QStringLiteral("Paused"));
}

void PlaybackEngine::stop()
{
    if (!m_player)
        return;
    m_generation.fetch_add(1, std::memory_order_acq_rel);
    m_requestedPlaying = false;
    m_pendingPositionMs = -1;
    m_pausedPositionMs = -1;
    m_player->stop();
    m_player->setSource(QUrl());
    stopDownload(false);
    finishDownload();
    if (m_positionMs != 0) {
        m_positionMs = 0;
        emit positionChanged();
    }
    setState(QStringLiteral("Stopped"));
}

void PlaybackEngine::seek(qint64 positionMs)
{
    if (!m_player || !m_seekable)
        return;
    const qint64 bounded = std::clamp<qint64>(positionMs, 0, m_durationMs);
    m_player->setPosition(bounded);
    m_positionMs = bounded;
    m_pausedPositionMs = bounded;
    emit positionChanged();
    emit seeked(bounded);
}

void PlaybackEngine::setVolume(double volume)
{
    const double bounded = std::clamp(volume, 0.0, 1.5);
    if (qFuzzyCompare(m_volume, bounded))
        return;
    m_volume = bounded;
    if (m_output)
        m_output->setVolume(float(std::min(bounded, 1.0)));
    emit volumeChanged();
}

void PlaybackEngine::onMediaStatusChanged(int status)
{
    const auto mediaStatus = static_cast<QMediaPlayer::MediaStatus>(status);
    switch (mediaStatus) {
    case QMediaPlayer::LoadedMedia:
    case QMediaPlayer::BufferedMedia:
        updateSeekable();
        updatePosition();
        if (m_pendingPositionMs >= 0) {
            const qint64 position = m_pendingPositionMs;
            m_pendingPositionMs = -1;
            m_player->setPosition(position);
            m_positionMs = position;
            emit positionChanged();
            emit seeked(position);
        }
        if (m_requestedPlaying)
            m_player->play();
        else
            setState(QStringLiteral("Paused"));
        break;
    case QMediaPlayer::EndOfMedia:
        if (!m_requestedPlaying)
            break;
        m_requestedPlaying = false;
        ++m_naturalEosCount;
        if (m_durationMs > 0 && m_positionMs != m_durationMs) {
            m_positionMs = m_durationMs;
            emit positionChanged();
        }
        setState(QStringLiteral("Stopped"));
        emit endOfStream(generation());
        break;
    case QMediaPlayer::InvalidMedia:
        setErrorMessage(m_player->errorString().isEmpty()
                            ? QStringLiteral("Unsupported or unreachable audio source")
                            : m_player->errorString());
        m_requestedPlaying = false;
        setState(QStringLiteral("Error"));
        break;
    case QMediaPlayer::StalledMedia:
        if (m_requestedPlaying)
            setState(QStringLiteral("Loading"));
        break;
    default:
        break;
    }
}

void PlaybackEngine::onPlaybackStateChanged(int state)
{
    const auto playbackState = static_cast<QMediaPlayer::PlaybackState>(state);
    if (playbackState == QMediaPlayer::PlayingState) {
        setState(QStringLiteral("Playing"));
    } else if (playbackState == QMediaPlayer::PausedState) {
        setState(m_requestedPlaying ? QStringLiteral("Loading") : QStringLiteral("Paused"));
    } else if (playbackState == QMediaPlayer::StoppedState && !m_requestedPlaying) {
        if (m_state != QLatin1String("Error") && m_state != QLatin1String("Stopped")) {
            // 暂停状态下后端偶尔也会上报 Stopped；此时保持 Paused，
            // 否则 MusicController 会判定为“已停止”而整曲重新加载（表现为从头播放）
            if (m_pausedPositionMs > 0 || m_positionMs > 0)
                setState(QStringLiteral("Paused"));
            else
                setState(QStringLiteral("Stopped"));
        }
    }
    updateSeekable();
}

void PlaybackEngine::onPlayerError(int error, const QString &message)
{
    if (error == QMediaPlayer::NoError)
        return;
    setErrorMessage(message.isEmpty() ? QStringLiteral("Playback failed") : message);
    m_requestedPlaying = false;
    setState(QStringLiteral("Error"));
}

void PlaybackEngine::updatePosition()
{
    if (!m_player || m_source.isEmpty())
        return;
    if (m_pendingPositionMs < 0) {
        const qint64 position = m_player->position();
        if (position != m_positionMs) {
            m_positionMs = position;
            emit positionChanged();
        }
    }
    const qint64 duration = m_player->duration();
    if (duration > 0)
        setDuration(duration);
}

void PlaybackEngine::setState(const QString &state)
{
    if (m_state == state)
        return;
    m_state = state;
    if (state == QLatin1String("Error"))
        m_downloadFailed = true;
    if (m_state == QStringLiteral("Playing"))
        m_positionTimer.start();
    else
        m_positionTimer.stop();
    if (m_state == QStringLiteral("Loading"))
        m_loadingTimeout.start();
    else
        m_loadingTimeout.stop();
    if (m_state == QStringLiteral("Error") || m_state == QStringLiteral("Stopped"))
        m_downloadTimer.stop();
    emit stateChanged();
}

void PlaybackEngine::setErrorMessage(const QString &message)
{
    if (m_errorMessage == message)
        return;
    m_errorMessage = message;
    emit errorMessageChanged();
}

void PlaybackEngine::setDuration(qint64 durationMs)
{
    if (m_durationMs == durationMs)
        return;
    m_durationMs = durationMs;
    emit durationChanged();
}

void PlaybackEngine::updateSeekable()
{
    if (!m_player)
        return;
    const bool value = m_player->isSeekable();
    if (m_seekable == value)
        return;
    m_seekable = value;
    emit seekableChanged();
}

void PlaybackEngine::startDownload(const QUrl &source, const QByteArray &userAgent, const QUrl &referer)
{
    stopDownload(false);
    auto *file = new QTemporaryFile(m_downloadTemplate, this);
    file->setAutoRemove(false);
    if (!file->open()) {
        delete file;
        return;
    }
    m_downloadFile = file;
    m_downloadPath = file->fileName();
    m_downloading = true;
    m_downloadFailed = false;
    m_downloadProgress = 0;
    m_downloadTimer.start();

    QNetworkRequest request(source);
    if (!userAgent.isEmpty())
        request.setRawHeader("User-Agent", userAgent);
    if (referer.isValid() && !referer.isEmpty())
        request.setRawHeader("Referer", referer.toEncoded());
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);

    m_downloadReply = m_nam->get(request);
    connect(m_downloadReply, &QNetworkReply::downloadProgress, this,
            [this](qint64 received, qint64 total) {
        const double progress = total > 0 ? std::clamp(double(received) / double(total), 0.0, 1.0) : -1;
        if (progress != m_downloadProgress) {
            m_downloadProgress = progress;
            emit bufferingChanged();
        }
    });
    connect(m_downloadReply, &QNetworkReply::readyRead, this, [this] {
        if (m_downloadFile && m_downloadReply)
            m_downloadFile->write(m_downloadReply->readAll());
    });
    connect(m_downloadReply, &QNetworkReply::finished, this, [this] {
        const bool ok = m_downloadReply && m_downloadReply->error() == QNetworkReply::NoError;
        stopDownload(false);
        if (!ok) {
            m_downloadFailed = true;
            m_downloadProgress = -1;
            emit bufferingChanged();
            return;
        }
        m_downloading = false;
        m_downloadProgress = 1;
        m_completedDownload = m_downloadPath;
        emit bufferingChanged();
        finishDownload();
    });
}

void PlaybackEngine::updateDownloadProgress()
{
    // 进度由 QNetworkReply::downloadProgress 信号驱动，这里保留空实现以兼容原接口。
}

void PlaybackEngine::stopDownload(bool keepFile)
{
    if (m_downloadReply) {
        m_downloadReply->disconnect(this);
        m_downloadReply->abort();
        m_downloadReply->deleteLater();
        m_downloadReply = nullptr;
    }
    if (m_downloadFile) {
        m_downloadFile->close();
        if (!keepFile && !m_downloadFile->fileName().isEmpty())
            QFile::remove(m_downloadFile->fileName());
        m_downloadFile->deleteLater();
        m_downloadFile = nullptr;
    }
    m_downloading = false;
    m_downloadTimer.stop();
}

void PlaybackEngine::finishDownload()
{
    const QString path = std::exchange(m_completedDownload, {});
    if (path.isEmpty())
        return;
    if (!m_downloadFailed)
        emit downloadCompleted(path);
    QFile::remove(path);
}
