#pragma once
#include "MusicTypes.h"
#include "BilibiliLibraryController.h"
#include "BilibiliDiscoveryController.h"
#include "providers/bilibili/BilibiliSearch.h"
#include "providers/bilibili/BilibiliPlaybackResolver.h"
#include <QVariantList>
#include <QtQmlIntegration/qqmlintegration.h>
class BilibiliController : public QObject {
    Q_OBJECT
    QML_ANONYMOUS
    Q_PROPERTY(BilibiliAccountController *account READ account CONSTANT)
    Q_PROPERTY(BilibiliLibraryController *library READ library CONSTANT)
    Q_PROPERTY(BilibiliDiscoveryController *discovery READ discovery CONSTANT)
    Q_PROPERTY(QVariantList results READ results NOTIFY changed)
    Q_PROPERTY(QVariantList parts READ parts NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY changed)
    Q_PROPERTY(bool hasMore READ hasMore NOTIFY changed)
public:
    explicit BilibiliController(QObject *parent = nullptr);
    BilibiliAccountController *account() { return &m_account; }
    BilibiliLibraryController *library() { return &m_library; }
    BilibiliDiscoveryController *discovery() { return &m_discovery; }
    QVariantList results() const;
    QVariantList parts() const;
    bool busy() const { return m_busy; }
    QString error() const { return m_error; }
    bool hasMore() const { return !m_next.isEmpty(); }
    Q_INVOKABLE void search(const QString &query);
    Q_INVOKABLE void loadMore();
    Q_INVOKABLE void openParts(int row);
    Q_INVOKABLE void play(int row);
    Q_INVOKABLE void playPart(int row);
    Q_INVOKABLE void cancelBrowse();
    void prepare(qint64 trackId, const QString &providerId);
    void cancelPlayback();
signals:
    void changed();
    void trackSelected(const TrackRecord &track);
    void resolved(qint64 trackId, const MusicProviders::PlaybackSource &source);
    void failed(qint64 trackId, const QString &message);
private:
    void fetch(bool more);
    void select(const MusicProviders::MediaItem &);
    MusicProviders::BilibiliSession m_session;
    BilibiliAccountController m_account;
    BilibiliLibraryController m_library;
    BilibiliDiscoveryController m_discovery;
    MusicProviders::BilibiliSearch m_search;
    MusicProviders::BilibiliDetail m_detail;
    MusicProviders::BilibiliPlaybackResolver m_resolver;
    QPointer<MusicProviders::Request> m_searchRequest, m_detailRequest, m_playRequest;
    QList<MusicProviders::MediaItem> m_results, m_parts;
    QString m_query, m_next, m_error;
    bool m_busy = false;
};
