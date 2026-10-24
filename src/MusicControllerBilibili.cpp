#include "MusicController.h"
void MusicController::setupBilibili() {
    connect(&m_bilibili, &BilibiliController::trackSelected, this, [this](const TrackRecord &track) {
        QString error;
        const auto id = m_database.addExternalTrack(track, &error);
        if (id < 0) { setError(error); return; }
        refreshLibrary();
        setQueue({id}, 0);
        startCurrentTrack();
    });
    connect(&m_bilibili, &BilibiliController::resolved, this,
        [this](qint64 id, const MusicProviders::PlaybackSource &source) {
            if (id != currentTrackId() || id != m_resolvingTrackId) return;
            m_streamMetadataTrackId = id; m_streamAvailability = "full";
            m_streamAvailabilityConfirmed = true; m_streamDurationMs = 0;
            m_streamQuality = source.quality; m_providerStatus = QStringLiteral("Bilibili · AAC");
            // Resolution is complete; the engine now owns the bounded buffering deadline.
            m_trackTimeout.stop();
            loadPreparedTrack(source.url, source.userAgent, source.referer);
            persistPlaybackPosition(); emit durationChanged(); emit playbackStatusChanged();
        });
    connect(&m_bilibili, &BilibiliController::failed, this, [this](qint64 id, const QString &error) {
        if (id != currentTrackId() || id != m_resolvingTrackId) return;
        m_providerStatus = error; schedulePlaybackFailure(error); emit playbackStatusChanged();
    });
}
