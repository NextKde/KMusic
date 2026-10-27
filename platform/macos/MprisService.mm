#include "MprisService.h"

#include "MusicController.h"

#include <QFileInfo>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QStringList>
#include <QUrl>

#import <AppKit/AppKit.h>
#import <MediaPlayer/MediaPlayer.h>

namespace {

constexpr int kMaxCachedArtwork = 24;

QString joinArtist(const QVariant &value)
{
    if (value.canConvert<QStringList>())
        return value.toStringList().join(QStringLiteral(", "));
    return value.toString();
}

} // namespace

MprisService::MprisService(MusicController *controller, QObject *parent)
    : QObject(parent)
    , m_controller(controller)
{
    m_nam = new QNetworkAccessManager(this);

    @autoreleasepool {
        MPRemoteCommandCenter *center = [MPRemoteCommandCenter sharedCommandCenter];
        NSMutableArray *targets = [[NSMutableArray alloc] init];

        // 每个 handler 都把系统指令转成 MusicController 的调用，语义与原 MPRIS 一致。
        void (^bind)(MPRemoteCommand *, void (^)(MPRemoteCommandEvent *)) =
            ^(MPRemoteCommand *command, void (^handler)(MPRemoteCommandEvent *)) {
                id token = [command addTargetWithHandler:
                    ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
                        handler(event);
                        return MPRemoteCommandHandlerStatusSuccess;
                    }];
                [targets addObject:token];
            };

        bind(center.playCommand, ^(MPRemoteCommandEvent *) {
            if (m_controller) m_controller->play();
        });
        bind(center.pauseCommand, ^(MPRemoteCommandEvent *) {
            if (m_controller) m_controller->pause();
        });
        bind(center.togglePlayPauseCommand, ^(MPRemoteCommandEvent *) {
            if (m_controller) m_controller->togglePlayPause();
        });
        bind(center.stopCommand, ^(MPRemoteCommandEvent *) {
            if (m_controller) m_controller->stop();
        });
        bind(center.nextTrackCommand, ^(MPRemoteCommandEvent *) {
            if (m_controller) m_controller->next();
        });
        bind(center.previousTrackCommand, ^(MPRemoteCommandEvent *) {
            if (m_controller) m_controller->previous();
        });
        bind(center.changePlaybackPositionCommand, ^(MPRemoteCommandEvent *event) {
            auto *positionEvent = (MPChangePlaybackPositionCommandEvent *)event;
            if (m_controller)
                m_controller->seek(qint64(positionEvent.positionTime * 1000.0));
        });

        m_targets = targets;
        m_registered = (center != nil);
    }

    // 播放中每秒校准一次进度，避免系统按速率线性推算带来的漂移。
    m_progressTimer.setInterval(1000);
    connect(&m_progressTimer, &QTimer::timeout, this, [this] {
        if (m_controller && m_controller->playbackState() == QLatin1String("Playing"))
            updateNowPlaying();
        else
            m_progressTimer.stop();
    });

    connect(controller, &MusicController::currentTrackChanged, this, [this] {
        updateNowPlaying();
        updateCommandAvailability();
    });
    connect(controller, &MusicController::playbackStatusChanged, this, [this] { updateNowPlaying(); });
    connect(controller, &MusicController::playbackStateChanged, this, [this] { updateNowPlaying(); });
    connect(controller, &MusicController::seeked, this, [this](qint64) { updateNowPlaying(); });
    connect(controller, &MusicController::queueChanged, this, [this] { updateCommandAvailability(); });
    connect(controller, &MusicController::seekableChanged, this, [this] { updateCommandAvailability(); });

    updateCommandAvailability();
    updateNowPlaying();
}

MprisService::~MprisService()
{
    m_progressTimer.stop();
    @autoreleasepool {
        MPRemoteCommandCenter *center = [MPRemoteCommandCenter sharedCommandCenter];
        NSArray *commands = @[center.playCommand, center.pauseCommand, center.togglePlayPauseCommand,
                              center.stopCommand, center.nextTrackCommand, center.previousTrackCommand,
                              center.changePlaybackPositionCommand];
        NSArray *targets = (NSArray *)m_targets;
        for (MPRemoteCommand *command in commands) {
            for (id token in targets)
                [command removeTarget:token];
        }
        [targets release];
        m_targets = nullptr;

        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
        if (@available(macOS 10.12.2, *))
            [MPNowPlayingInfoCenter defaultCenter].playbackState = MPNowPlayingPlaybackStateStopped;
    }
}

bool MprisService::registered() const
{
    return m_registered;
}

QString MprisService::artworkFilePath() const
{
    if (!m_controller)
        return {};
    const QString artUrl = m_controller->mprisMetadata().value(QStringLiteral("mpris:artUrl")).toString();
    if (artUrl.isEmpty())
        return {};
    const QUrl url(artUrl);
    if (!url.isLocalFile())
        return {};
    const QString path = url.toLocalFile();
    return QFileInfo::exists(path) ? path : QString();
}

void MprisService::requestArtwork(const QString &url)
{
    if (url.isEmpty() || m_artworkCache.contains(url) || m_pendingArtwork.contains(url))
        return;
    m_pendingArtwork.insert(url);

    QNetworkRequest request{QUrl(url)};
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);
    QNetworkReply *reply = m_nam->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply, url] {
        m_pendingArtwork.remove(url);
        const QByteArray data = reply->readAll();
        reply->deleteLater();
        if (data.isEmpty())
            return;
        QImage image;
        if (!image.loadFromData(data))
            return;
        if (m_artworkCache.size() >= kMaxCachedArtwork)
            m_artworkCache.clear();
        m_artworkCache.insert(url, image);
        updateNowPlaying();
    });
}

void MprisService::updateCommandAvailability()
{
    if (!m_controller || !m_registered)
        return;
    MPRemoteCommandCenter *center = [MPRemoteCommandCenter sharedCommandCenter];
    const bool canPlay = m_controller->engineAvailable() && m_controller->currentTrackId() >= 0;
    center.playCommand.enabled = canPlay;
    center.pauseCommand.enabled = canPlay;
    center.togglePlayPauseCommand.enabled = canPlay;
    center.stopCommand.enabled = canPlay;
    center.nextTrackCommand.enabled = m_controller->canGoNext();
    center.previousTrackCommand.enabled = m_controller->canGoPrevious();
    center.changePlaybackPositionCommand.enabled = m_controller->seekable();
}

void MprisService::updateNowPlaying()
{
    if (!m_controller || !m_registered)
        return;

    const QVariantMap metadata = m_controller->mprisMetadata();
    const QString artUrl = metadata.value(QStringLiteral("mpris:artUrl")).toString();
    const bool playing = m_controller->playbackState() == QLatin1String("Playing");

    @autoreleasepool {
        NSMutableDictionary *info = [[NSMutableDictionary alloc] init];

        const QString title = metadata.value(QStringLiteral("xesam:title")).toString();
        const QString artist = joinArtist(metadata.value(QStringLiteral("xesam:artist")));
        const QString album = metadata.value(QStringLiteral("xesam:album")).toString();
        if (!title.isEmpty())
            [info setObject:title.toNSString() forKey:MPMediaItemPropertyTitle];
        if (!artist.isEmpty())
            [info setObject:artist.toNSString() forKey:MPMediaItemPropertyArtist];
        if (!album.isEmpty())
            [info setObject:album.toNSString() forKey:MPMediaItemPropertyAlbumTitle];

        // mpris:length 单位是微秒
        const qint64 lengthUs = metadata.value(QStringLiteral("mpris:length")).toLongLong();
        const double duration = lengthUs > 0 ? double(lengthUs) / 1000000.0
                                             : double(m_controller->durationMs()) / 1000.0;
        if (duration > 0)
            [info setObject:@(duration) forKey:MPMediaItemPropertyPlaybackDuration];

        [info setObject:@(double(m_controller->positionMs()) / 1000.0)
                 forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [info setObject:@(playing ? 1.0 : 0.0) forKey:MPNowPlayingInfoPropertyPlaybackRate];

        // 封面：本地文件直接读；在线封面异步下载后缓存，命中缓存就直接用
        NSImage *image = nil;
        const QString localArtwork = artworkFilePath();
        if (!localArtwork.isEmpty()) {
            image = [[NSImage alloc] initWithContentsOfFile:localArtwork.toNSString()];
        } else if (!artUrl.isEmpty()) {
            if (m_artworkCache.contains(artUrl)) {
                const QImage cached = m_artworkCache.value(artUrl);
                CGImageRef cgImage = cached.toCGImage();
                if (cgImage) {
                    image = [[NSImage alloc] initWithCGImage:cgImage
                                                        size:NSMakeSize(cached.width(), cached.height())];
                    CGImageRelease(cgImage);
                }
            } else {
                requestArtwork(artUrl);
            }
        }
        if (image) {
            MPMediaItemArtwork *itemArtwork =
                [[MPMediaItemArtwork alloc] initWithBoundsSize:image.size
                                               requestHandler:^NSImage *(CGSize) {
                                                   return image;
                                               }];
            [info setObject:itemArtwork forKey:MPMediaItemPropertyArtwork];
            [itemArtwork release];
            [image release];
        }

        MPNowPlayingInfoCenter *nowPlaying = [MPNowPlayingInfoCenter defaultCenter];
        nowPlaying.nowPlayingInfo = info;
        if (@available(macOS 10.12.2, *)) {
            if (playing)
                nowPlaying.playbackState = MPNowPlayingPlaybackStatePlaying;
            else if (m_controller->playbackState() == QLatin1String("Paused"))
                nowPlaying.playbackState = MPNowPlayingPlaybackStatePaused;
            else
                nowPlaying.playbackState = MPNowPlayingPlaybackStateStopped;
        }
        [info release];
    }

    if (playing && !m_progressTimer.isActive())
        m_progressTimer.start();
    else if (!playing && m_progressTimer.isActive())
        m_progressTimer.stop();
}
