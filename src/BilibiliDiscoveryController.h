#pragma once
#include "BilibiliAccountController.h"
#include "BilibiliFeedState.h"
#include "providers/bilibili/BilibiliDiscovery.h"
#include <QMap>
#include <QVariantMap>
class BilibiliDiscoveryController final : public QObject {
    Q_OBJECT
    QML_ANONYMOUS
    Q_PROPERTY(QVariantMap sections READ sections NOTIFY changed)
public:
    explicit BilibiliDiscoveryController(MusicProviders::BilibiliSession &, BilibiliAccountController &, QObject *parent = nullptr);
    ~BilibiliDiscoveryController() override;
    QVariantMap sections() const;
    Q_INVOKABLE void ensureLoaded();
    Q_INVOKABLE void reload(const QString &section);
    Q_INVOKABLE void retry(const QString &section);
    Q_INVOKABLE void loadMore(const QString &section);
    Q_INVOKABLE void play(const QString &section, int row);
signals:
    void changed();
    void selected(const MusicProviders::MediaItem &);
private:
    void fetch(const QString &, bool more);
    void resetFollowing();
    BilibiliAccountController &m_account;
    MusicProviders::BilibiliDiscovery m_provider;
    QMap<QString, BilibiliFeedState> m_sections;
    QMap<QString, QPointer<MusicProviders::Request>> m_requests;
};
