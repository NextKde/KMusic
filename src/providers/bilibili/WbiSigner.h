#pragma once
#include "../contracts/ProviderTypes.h"
#include <QMap>
#include <QUrlQuery>
namespace MusicProviders {
class WbiSigner {
public:
    static Result<QUrlQuery> sign(QMap<QString, QString> parameters,
                                 const QString &imageKey, const QString &subKey, qint64 timestamp);
};
}
