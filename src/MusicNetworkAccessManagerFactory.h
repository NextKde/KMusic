#pragma once
#include "providers/NetworkAccessManager.h"
#include <QQmlNetworkAccessManagerFactory>
// Called by the QML engine on its network thread. Each engine gets its own
// manager/cookie jar; never share the native Bilibili account session here.
class MusicNetworkAccessManagerFactory final : public QQmlNetworkAccessManagerFactory {
public:
    QNetworkAccessManager *create(QObject *parent) override {
        return new MusicProviders::NetworkAccessManager(parent);
    }
};
