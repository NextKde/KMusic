#pragma once
#include "../contracts/ProviderTypes.h"
#include <QJsonObject>
namespace MusicProviders {
Result<QJsonObject> biliData(const QByteArray &body);
}
