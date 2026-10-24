#pragma once
#include "BilibiliApi.h"
#include "BilibiliFollowing.h"
namespace MusicProviders {
class BilibiliDiscovery final {
public:
    explicit BilibiliDiscovery(BilibiliSession &session) : m_following(session) {}
    void setAccount(const SourceScope &scope) { m_following.setAccount(scope); }
    Request *page(const SourceScope &, const QString &section, const QString &cursor, QObject *, Completion<Page<MediaItem>>);
    static Result<Page<MediaItem>> decode(const QString &section, const QByteArray &, const QString &cursor = {});
private:
    BilibiliApi m_public; // Public discovery never uses account cookies.
    BilibiliFollowing m_following;
};
}
