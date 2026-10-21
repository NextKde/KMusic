#pragma once

#include "MusicDatabase.h"
#include "OnlineMusicProvider.h"
#include "AccountController.h"
#include "PlaybackEngine.h"
#include "TrackListModel.h"
#include "Transcoder.h"

#include <QFutureWatcher>
#include <QHash>
#include <QSet>
#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QtQmlIntegration/qqmlintegration.h>

#include <optional>
#include <memory>

class MprisService;
class LxSourceService;
class LyricsService;
class AudioCache;

class MusicController : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(AccountController *account READ account CONSTANT)
    Q_PROPERTY(TrackListModel *libraryModel READ libraryModel CONSTANT)
    Q_PROPERTY(TrackListModel *queueModel READ queueModel CONSTANT)
    Q_PROPERTY(TrackListModel *playlistTracksModel READ playlistTracksModel CONSTANT)
    Q_PROPERTY(TrackListModel *onlineModel READ onlineModel CONSTANT)
    Q_PROPERTY(TrackListModel *albumTracksModel READ albumTracksModel CONSTANT)
    Q_PROPERTY(QVariantMap onlineAlbum READ onlineAlbum NOTIFY onlineAlbumChanged)
    Q_PROPERTY(bool albumLoading READ albumLoading NOTIFY onlineAlbumChanged)
    Q_PROPERTY(QString albumError READ albumError NOTIFY onlineAlbumChanged)
    Q_PROPERTY(QString albumMessage READ albumMessage NOTIFY onlineAlbumChanged)
    Q_PROPERTY(bool albumLoadingMore READ albumLoadingMore NOTIFY onlineAlbumChanged)
    Q_PROPERTY(QString albumLoadMoreError READ albumLoadMoreError NOTIFY onlineAlbumChanged)
    Q_PROPERTY(QString currentProviderId READ currentProviderId NOTIFY currentTrackChanged)
    Q_PROPERTY(QVariantList artistAlbums READ artistAlbums NOTIFY onlineAlbumChanged)
    Q_PROPERTY(bool artistAlbumsVisible READ artistAlbumsVisible NOTIFY onlineAlbumChanged)
    Q_PROPERTY(bool artistAlbumsLoading READ artistAlbumsLoading NOTIFY onlineAlbumChanged)
    Q_PROPERTY(QString artistAlbumsError READ artistAlbumsError NOTIFY onlineAlbumChanged)
    Q_PROPERTY(int artistAlbumsTotal READ artistAlbumsTotal NOTIFY onlineAlbumChanged)
    Q_PROPERTY(bool artistAlbumsMore READ artistAlbumsMore NOTIFY onlineAlbumChanged)
    Q_PROPERTY(bool artistParentAvailable READ artistParentAvailable NOTIFY onlineAlbumChanged)
    Q_PROPERTY(QVariantList onlineCollections READ onlineCollections NOTIFY onlineCollectionsChanged)
    Q_PROPERTY(QString onlineSearchKind READ onlineSearchKind WRITE setOnlineSearchKind NOTIFY onlineCollectionsChanged)
    Q_PROPERTY(QVariantList discoveryAlbums READ discoveryAlbums NOTIFY discoveryChanged)
    Q_PROPERTY(bool discoveryLoading READ discoveryLoading NOTIFY discoveryChanged)
    Q_PROPERTY(QString discoveryError READ discoveryError NOTIFY discoveryChanged)
    Q_PROPERTY(bool discoveryPlaying READ discoveryPlaying NOTIFY discoveryChanged)
    Q_PROPERTY(QVariantList albums READ albums NOTIFY libraryChanged)
    Q_PROPERTY(QVariantList artists READ artists NOTIFY libraryChanged)
    Q_PROPERTY(QVariantList playlists READ playlists NOTIFY playlistsChanged)
    Q_PROPERTY(QStringList libraryFolders READ libraryFolders NOTIFY libraryFoldersChanged)
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    Q_PROPERTY(QString scanStatus READ scanStatus NOTIFY scanningChanged)
    Q_PROPERTY(QStringList scanWarnings READ scanWarnings NOTIFY scanningChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(bool onlineSearching READ onlineSearching NOTIFY onlineSearchingChanged)
    Q_PROPERTY(QString onlineError READ onlineError NOTIFY onlineErrorChanged)
    Q_PROPERTY(QVariantList musicSources READ musicSources NOTIFY musicSourcesChanged)
    Q_PROPERTY(QStringList onlineQualities READ onlineQualities NOTIFY onlineQualitiesChanged)
    Q_PROPERTY(QString onlineQuality READ onlineQuality WRITE setOnlineQuality NOTIFY onlineQualityChanged)
    Q_PROPERTY(QString activeMusicSourceId READ activeMusicSourceId NOTIFY musicSourcesChanged)
    Q_PROPERTY(QString musicSourceState READ musicSourceState NOTIFY musicSourceStateChanged)
    Q_PROPERTY(QString musicSourceError READ musicSourceError NOTIFY musicSourceErrorChanged)
    Q_PROPERTY(QVariantList lyrics READ lyrics NOTIFY lyricsChanged)
    Q_PROPERTY(int currentLyricIndex READ currentLyricIndex NOTIFY currentLyricChanged)
    Q_PROPERTY(QString currentLyric READ currentLyric NOTIFY currentLyricChanged)
    Q_PROPERTY(QString nextLyric READ nextLyric NOTIFY currentLyricChanged)
    Q_PROPERTY(bool lyricsLoading READ lyricsLoading NOTIFY lyricsLoadingChanged)
    Q_PROPERTY(QString lyricsError READ lyricsError NOTIFY lyricsErrorChanged)

    Q_PROPERTY(QVariantMap onlineDetail READ onlineDetail NOTIFY onlineDetailChanged)
    Q_PROPERTY(QString providerStatus READ providerStatus NOTIFY playbackStatusChanged)
    Q_PROPERTY(QVariantMap playbackSession READ playbackSessionInfo NOTIFY playbackStatusChanged)
    Q_PROPERTY(bool engineAvailable READ engineAvailable CONSTANT)
    Q_PROPERTY(QString engineBackend READ engineBackend CONSTANT)
    Q_PROPERTY(bool mprisRegistered READ mprisRegistered NOTIFY mprisRegisteredChanged)
    Q_PROPERTY(QString playbackState READ playbackState NOTIFY playbackStateChanged)
    Q_PROPERTY(QString playbackStatusText READ playbackStatusText NOTIFY playbackStatusChanged)
    Q_PROPERTY(QStringList playbackAttempts READ playbackAttempts NOTIFY playbackStatusChanged)
    Q_PROPERTY(double cacheProgress READ cacheProgress NOTIFY playbackStatusChanged)
    Q_PROPERTY(bool lyricsEnabled READ lyricsEnabled WRITE setLyricsEnabled NOTIFY lyricsEnabledChanged)
    Q_PROPERTY(qlonglong currentTrackId READ currentTrackId NOTIFY currentTrackChanged)
    Q_PROPERTY(QString currentTitle READ currentTitle NOTIFY currentTrackChanged)
    Q_PROPERTY(QString currentArtist READ currentArtist NOTIFY currentTrackChanged)
    Q_PROPERTY(QString currentAlbum READ currentAlbum NOTIFY currentTrackChanged)
    Q_PROPERTY(QString currentArtworkUrl READ currentArtworkUrl NOTIFY currentTrackChanged)
    Q_PROPERTY(qlonglong positionMs READ positionMs NOTIFY positionChanged)
    Q_PROPERTY(qlonglong durationMs READ durationMs NOTIFY durationChanged)
    Q_PROPERTY(bool seekable READ seekable NOTIFY seekableChanged)
    Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool shuffle READ shuffle WRITE setShuffle NOTIFY shuffleChanged)
    Q_PROPERTY(QString repeatMode READ repeatMode WRITE setRepeatMode NOTIFY repeatModeChanged)
    Q_PROPERTY(QString playbackMode READ playbackMode WRITE setPlaybackMode NOTIFY playbackModeChanged)
    Q_PROPERTY(QString librarySearch READ librarySearch NOTIFY librarySearchChanged)
    Q_PROPERTY(bool canGoNext READ canGoNext NOTIFY queueChanged)
    Q_PROPERTY(bool canGoPrevious READ canGoPrevious NOTIFY queueChanged)
    Q_PROPERTY(int queueIndex READ queueIndex NOTIFY queueChanged)

    Q_PROPERTY(QVariantList availableTranscodeFormats READ availableTranscodeFormats CONSTANT)
    Q_PROPERTY(bool transcoding READ transcoding NOTIFY transcodeChanged)
    Q_PROPERTY(double transcodeProgress READ transcodeProgress NOTIFY transcodeChanged)
    Q_PROPERTY(QString transcodeStatus READ transcodeStatus NOTIFY transcodeChanged)
    Q_PROPERTY(QString transcodeError READ transcodeError NOTIFY transcodeChanged)

public:
    AccountController *account() { return &m_account; }
    explicit MusicController(QObject *parent = nullptr);
    ~MusicController() override;

    TrackListModel *libraryModel();
    TrackListModel *queueModel();
    TrackListModel *playlistTracksModel();
    TrackListModel *onlineModel();
    QVariantList onlineCollections() const { return m_onlineCollections; }
    QString onlineSearchKind() const { return m_onlineSearchKind; }
    void setOnlineSearchKind(const QString &kind);
    Q_INVOKABLE void openOnlineCollection(int row);
    QVariantList artistAlbums() const { return m_artistAlbums; }
    bool artistAlbumsVisible() const { return m_artistAlbumsVisible; }
    bool artistAlbumsLoading() const { return m_artistAlbumsLoading; }
    QString artistAlbumsError() const { return m_artistAlbumsError; }
    int artistAlbumsTotal() const { return m_artistAlbumsTotal; }
    bool artistAlbumsMore() const { return m_artistAlbumsMore; }
    bool artistParentAvailable() const { return !m_artistId.isEmpty() && m_onlineAlbum.value("kind").toString() != "artist"; }
    Q_INVOKABLE void showArtistAlbums();
    Q_INVOKABLE void showArtistPopularSongs();
    Q_INVOKABLE void loadMoreArtistAlbums();
    Q_INVOKABLE void openArtistAlbum(int row);
    Q_INVOKABLE void restoreArtistDetails();
    TrackListModel *albumTracksModel() { return &m_albumTracksModel; }
    QVariantMap onlineAlbum() const { return m_onlineAlbum; }
    bool albumLoading() const { return m_albumLoading; }
    QString albumError() const { return m_albumError; }
    bool albumLoadingMore() const { return m_albumLoadingMore; }
    QString albumLoadMoreError() const { return m_albumLoadMoreError; }
    Q_INVOKABLE void loadMorePlaylistTracks();
    QString albumMessage() const { return m_albumMessage; }
    QString currentProviderId() const;
    Q_INVOKABLE void openDiscoveryAlbum(int row);
    Q_INVOKABLE void retryOnlineAlbum();
    Q_INVOKABLE void playOnlineAlbum();
    Q_INVOKABLE void playOnlineAlbumRow(int row);
    Q_INVOKABLE void enqueueOnlineAlbum();
    Q_INVOKABLE void enqueueAlbumRow(int row);
    QVariantList discoveryAlbums() const { return m_discoveryAlbums; }
    bool discoveryLoading() const { return m_discoveryLoading; }
    QString discoveryError() const { return m_discoveryError; }
    bool discoveryPlaying() const { return !m_pendingDiscoveryAlbum.isEmpty(); }
    Q_INVOKABLE void reloadDiscovery();
    Q_INVOKABLE void playDiscoveryAlbum(int row);
    QVariantList albums() const;
    QVariantList artists() const;
    QVariantList playlists() const;
    QStringList libraryFolders() const;
    bool ready() const;
    bool scanning() const;
    QString scanStatus() const;
    QStringList scanWarnings() const;
    QString errorMessage() const;
    QStringList onlineQualities() const;
    QString onlineQuality() const;
    bool onlineSearching() const;
    QString onlineError() const;
    QVariantList musicSources() const;
    QString activeMusicSourceId() const;
    QString musicSourceState() const;
    QString musicSourceError() const;
    QVariantList lyrics() const;
    int currentLyricIndex() const;
    QString currentLyric() const;
    QString nextLyric() const;
    bool lyricsLoading() const;
    QString lyricsError() const;

    QVariantMap onlineDetail() const { return m_onlineDetail; }
    Q_INVOKABLE void requestOnlineDetail(int row);
    QString providerStatus() const;
    QVariantMap playbackSessionInfo() const;
    bool engineAvailable() const;
    QString engineBackend() const;
    bool mprisRegistered() const;
    QString playbackState() const;
    QString playbackStatusText() const;
    double cacheProgress() const;
    QStringList playbackAttempts() const { return m_playbackAttempts; }
    bool lyricsEnabled() const;
    void setLyricsEnabled(bool enabled);
    Q_INVOKABLE void reloadLyrics();
    qint64 lyricRequestCount() const { return m_lyricRequestCount; }
    qlonglong currentTrackId() const;
    QString currentTitle() const;
    QString currentArtist() const;
    QString currentAlbum() const;
    QString currentArtworkUrl() const;
    qlonglong positionMs() const;
    qlonglong durationMs() const;
    bool seekable() const;
    double volume() const;
    bool shuffle() const;
    QString repeatMode() const;
    QString playbackMode() const;
    QString librarySearch() const;
    bool canGoNext() const;
    bool canGoPrevious() const;
    int queueIndex() const;

    QVariantList availableTranscodeFormats() const;
    bool transcoding() const;
    double transcodeProgress() const;
    QString transcodeStatus() const;
    QString transcodeError() const;

    QVariantMap mprisMetadata() const;
    QString mprisLoopStatus() const;

    Q_INVOKABLE void addLibraryFolder(const QString &pathOrUrl);
    Q_INVOKABLE void removeLibraryFolder(const QString &pathOrUrl);
    Q_INVOKABLE void rescanLibrary();
    Q_INVOKABLE void setLibraryView(const QString &mode, const QString &filterValue = {});
    Q_INVOKABLE void setSearch(const QString &search);
    Q_INVOKABLE void searchOnline(const QString &query);
    Q_INVOKABLE void playOnlineRow(int row);
    Q_INVOKABLE void enqueueOnlineRow(int row);
    Q_INVOKABLE void playOnlineNext(int row);
    Q_INVOKABLE void importMusicSource(const QString &pathOrUrl);
    Q_INVOKABLE void activateMusicSource(const QString &sourceId);
    Q_INVOKABLE void removeMusicSource(const QString &sourceId);

    Q_INVOKABLE void playTrack(qlonglong trackId);
    void setOnlineQuality(const QString &quality);
    Q_INVOKABLE void playQueueRow(int row);
    Q_INVOKABLE void playPlaylistRow(int row);
    Q_INVOKABLE void playAlbum(const QString &album);
    Q_INVOKABLE void playArtist(const QString &artist);
    Q_INVOKABLE void enqueueTrack(qlonglong trackId);
    Q_INVOKABLE void playTrackNext(qlonglong trackId);
    Q_INVOKABLE void moveQueueRowNext(int row);
    Q_INVOKABLE bool isTrackQueued(qlonglong trackId) const;
    Q_INVOKABLE QVariantMap trackDeletionInfo(qlonglong trackId) const;
    Q_INVOKABLE bool deleteTrack(qlonglong trackId, const QString &expectedPath);
    Q_INVOKABLE void removeQueueRow(int row);
    Q_INVOKABLE void clearQueue();
    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void togglePlayPause();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void seek(qlonglong positionMs);
    Q_INVOKABLE void seekFraction(double fraction);
    void setVolume(double volume);
    void setShuffle(bool shuffle);
    void setRepeatMode(const QString &mode);
    void setPlaybackMode(const QString &mode);

    Q_INVOKABLE void createPlaylist(const QString &name);
    Q_INVOKABLE void renamePlaylist(qlonglong playlistId, const QString &name);
    Q_INVOKABLE void removePlaylist(qlonglong playlistId);
    Q_INVOKABLE void selectPlaylist(qlonglong playlistId);
    Q_INVOKABLE void addTrackToPlaylist(qlonglong playlistId, qlonglong trackId);
    Q_INVOKABLE void removeTrackFromPlaylist(qlonglong playlistId, qlonglong trackId);
    Q_INVOKABLE void playPlaylist(qlonglong playlistId);

    Q_INVOKABLE void transcodeTrack(qlonglong trackId, const QString &outputUrl,
                                    const QString &formatId, bool overwrite = true);
    Q_INVOKABLE void cancelTranscode();
    Q_INVOKABLE void openUri(const QString &uriOrPath);
    Q_INVOKABLE void requestRaise();
    Q_INVOKABLE void clearError();

signals:
    void readyChanged();
    void libraryChanged();
    void onlineCollectionsChanged();
    void onlineAlbumChanged();
    void discoveryChanged();
    void playlistsChanged();
    void libraryFoldersChanged();
    void scanningChanged();
    void errorMessageChanged();
    void onlineSearchingChanged();
    void onlineDetailChanged();
    void onlineErrorChanged();
    void musicSourcesChanged();
    void musicSourceStateChanged();
    void musicSourceErrorChanged();
    void onlineQualitiesChanged();
    void onlineQualityChanged();
    void lyricsChanged();
    void currentLyricChanged();
    void lyricsLoadingChanged();
    void lyricsErrorChanged();
    void mprisRegisteredChanged();
    void playbackStateChanged();
    void playbackStatusChanged();
    void lyricsEnabledChanged();
    void currentTrackChanged();
    void positionChanged();
    void durationChanged();
    void seekableChanged();
    void volumeChanged();
    void shuffleChanged();
    void repeatModeChanged();
    void playbackModeChanged();
    void librarySearchChanged();
    void queueChanged();
    void transcodeChanged();
    void seeked(qlonglong positionMs);
    void raiseRequested();
    void userMessage(const QString &message);
    void trackDeleted(qlonglong trackId, const QString &trashPath);

private slots:
    void scanFinished();

private:
    void initialize();
    void setError(const QString &message);
    void startNextScan();
    void refreshLibrary();
    void refreshGroups();
    void applyGroupSearch();
    void refreshPlaylists();
    void refreshQueueModel();
    void refreshPlaylistModel();
    void setQueue(const QList<qint64> &trackIds, int currentIndex);
    void persistQueue();
    void startCurrentTrack(qint64 startPositionMs = 0);
    void loadPreparedTrack(const QUrl &url);
    void tryNextSource();
    void resolveWithReadySource();
    void schedulePlaybackFailure(const QString &message);
    void finishFailedTrack(const QString &message);
    void advanceAfterFailure();
    void cancelRecovery();
    void persistPlaybackPosition();
    QString audioCacheKey(const TrackRecord &track) const;
    qint64 storeOnlineTrack(int row);
    QList<qint64> storeAlbumTracks();
    void advance(bool fromEndOfStream);
    QList<TrackRecord> tracksForIds(const QList<qint64> &ids) const;
    std::optional<TrackRecord> findTrack(qint64 id) const;
    static QString localPath(const QString &pathOrUrl);

    MusicDatabase m_database;
    PlaybackEngine m_engine;
    Transcoder m_transcoder;
    TrackListModel m_libraryModel;
    TrackListModel m_queueModel;
    TrackListModel m_playlistTracksModel;
    TrackListModel m_onlineModel;
    TrackListModel m_albumTracksModel;
    QList<TrackRecord> m_albumTracks;
    QVariantMap m_onlineAlbum;
    QVariantList m_onlineCollections;
    void resetArtistBrowse();
    QString m_artistId;
    QVariantMap m_artistProfile;
    QList<TrackRecord> m_artistHotTracks;
    QVariantList m_artistAlbums;
    bool m_artistAlbumsVisible = false, m_artistAlbumsLoading = false, m_artistAlbumsMore = true;
    QString m_artistAlbumsError;
    int m_artistAlbumOffset = 0, m_artistAlbumsTotal = 0;
    QString m_onlineSearchKind = "song";
    bool m_albumLoading = false;
    bool m_albumLoadingMore = false;
    QString m_albumLoadMoreError;
    QString m_albumError, m_albumMessage;
    OnlineMusicProvider m_onlineProvider;
    AccountController m_account;
    QString m_onlineQuality = QStringLiteral("128k");
    std::unique_ptr<LxSourceService> m_sourceService;
    std::unique_ptr<LyricsService> m_lyricsService;
    std::unique_ptr<AudioCache> m_audioCache;
    QTimer m_savePositionTimer;
    QTimer m_attemptTimeout;
    QTimer m_trackTimeout;
    QTimer m_skipTimer;
    QStringList m_sourceCandidates;
    QStringList m_playbackAttempts;
    QString m_attemptName;
    QString m_recoveryStatus;
    QString m_providerStatus;
    qint64 m_streamMetadataTrackId = -1;
    qint64 m_streamDurationMs = 0;
    QString m_streamAvailability = QStringLiteral("unknown");
    QString m_streamQuality;
    bool m_streamAvailabilityConfirmed = false;
    qint64 m_providerResolveRequests = 0;
    qint64 m_providerResolutions = 0;
    qint64 m_engineLoadRequests = 0;
    qint64 m_lyricRequestCount = 0;
    QVariantMap m_onlineDetail;
    QVariantList m_discoveryAlbums;
    bool m_discoveryLoading = false;
    QString m_discoveryError;
    QString m_pendingDiscoveryAlbum;
    QSet<qint64> m_failedTracks;
    QSet<QString> m_removedDuringScan;
    int m_attemptGeneration = 0;
    bool m_waitingForSource = false;
    bool m_failureQueued = false;
    bool m_automaticAdvance = false;
    QFutureWatcher<ScanResult> m_scanWatcher;
    MprisService *m_mpris = nullptr;
    QList<TrackRecord> m_tracks;
    QHash<qint64, int> m_trackIndex;
    QList<qint64> m_queueIds;
    QStringList m_pendingScanRoots;
    QVariantList m_albums;
    QVariantList m_artists;
    QVariantList m_allAlbums;
    QVariantList m_allArtists;
    QVariantList m_playlists;
    QStringList m_libraryFolders;
    QStringList m_scanWarnings;
    QString m_dataPath;
    QString m_artworkPath;
    QString m_scanStatus = QStringLiteral("Idle");
    QString m_errorMessage;
    QString m_repeatMode = QStringLiteral("none");
    QString m_librarySearch;
    QString m_activeScanRoot;
    qint64 m_selectedPlaylistId = -1;
    int m_queueIndex = -1;
    bool m_ready = false;
    bool m_scanning = false;
    bool m_shuffle = false;
    qint64 m_resolvingTrackId = -1;
    qint64 m_loadedTrackId = -1;
    qint64 m_resumePositionMs = 0;
    bool m_playWhenReady = true;
    bool m_lyricsEnabled = true;
    bool m_usingCachedAudio = false;
    bool m_preparationFailed = false;
    QString m_pendingCacheKey;
    QString m_engineCacheKey;
};
