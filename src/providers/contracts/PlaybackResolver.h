#pragma once
#include "ProviderTypes.h"
#include "Request.h"
#include <QDateTime>

namespace MusicProviders {
// Ephemeral native-only descriptor. Never persist or expose to QML.
// Account cookies deliberately absent: resolving and CDN playback are separate.
struct PlaybackSource {
    MediaId id;
    QUrl url;
    QList<QUrl> backups;
    QString quality;
    QByteArray userAgent;
    QUrl referer;
    QDateTime expiresAt; // Invalid means unknown, not permanent.
};
class PlaybackResolver {
public:
    virtual ~PlaybackResolver() = default;
    virtual Request *resolve(const MediaId &, const QString &quality,
                             QObject *context, Completion<PlaybackSource>) = 0;
};
}
