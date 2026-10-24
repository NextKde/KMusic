#pragma once
#include "BilibiliAccountController.h"
#include "providers/bilibili/BilibiliLibrary.h"
#include <QVariantList>
class BilibiliLibraryController final : public QObject {
    Q_OBJECT
    QML_ANONYMOUS
    Q_PROPERTY(QVariantList folders READ folders NOTIFY changed)
    Q_PROPERTY(QVariantList items READ items NOTIFY changed)
    Q_PROPERTY(QVariantList history READ history NOTIFY changed)
    Q_PROPERTY(QString folderTitle READ folderTitle NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)
    Q_PROPERTY(bool more READ more NOTIFY changed)
    Q_PROPERTY(bool showingHistory READ showingHistory NOTIFY changed)
public:
    explicit BilibiliLibraryController(MusicProviders::BilibiliSession &, BilibiliAccountController &, QObject *parent = nullptr);
    QVariantList folders() const; QVariantList items() const; QVariantList history() const;
    QString folderTitle() const { return m_folderTitle; } QString error() const { return m_error; }
    bool busy() const { return m_busy; } bool more() const { return !m_next.isEmpty(); }
    bool showingHistory() const { return m_historyMode; }
    Q_INVOKABLE void retry();
    Q_INVOKABLE void reload(); Q_INVOKABLE void openFolder(int); Q_INVOKABLE void showHistory();
    Q_INVOKABLE void loadMore(); Q_INVOKABLE void play(int); Q_INVOKABLE void back();
signals:
    void changed(); void selected(const MusicProviders::MediaItem &);
private:
    void reset(); void fetch(bool); bool fail(const MusicProviders::Error &);
    BilibiliAccountController &m_account;
    MusicProviders::BilibiliLibrary m_provider;
    QPointer<MusicProviders::Request> m_request;
    QList<MusicProviders::Collection> m_folders;
    QList<MusicProviders::MediaItem> m_items, m_history;
    QString m_folderId, m_folderTitle, m_next, m_error;
    bool m_busy = false, m_historyMode = false;
    quint64 m_epoch = 0;
};
