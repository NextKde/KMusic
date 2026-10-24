#pragma once
#include "BilibiliSession.h"
namespace MusicProviders {
// Read-only account video updates, deliberately not a music-only recommendation feed.
class BilibiliFollowing final {
public:
    explicit BilibiliFollowing(BilibiliSession &session) : m_session(session) {}
    ~BilibiliFollowing();
    void setAccount(const SourceScope &);
    Request *page(const SourceScope &, const QString &cursor, QObject *, Completion<Page<MediaItem>>);
    static Result<Page<MediaItem>> decode(const SourceScope &, const QByteArray &, const QString &oldCursor = {});
private:
    BilibiliSession &m_session;
    SourceScope m_scope;
    quint64 m_epoch = 0;
    QList<QPointer<Request>> m_active;
};
}
