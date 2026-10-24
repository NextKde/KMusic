#pragma once
#include "BilibiliApi.h"
#include "../contracts/SearchProvider.h"
namespace MusicProviders {
class BilibiliSearch final : public QObject, public SearchProvider {
public:
    explicit BilibiliSearch(QObject *parent = nullptr, BilibiliSession *session = nullptr) : QObject(parent), m_api(this, session) {}
    Request *search(const SourceScope &, const QString &, const PageRequest &, QObject *, Completion<Page<MediaItem>>) override;
    static Result<Page<MediaItem>> decode(const SourceScope &, const QByteArray &);
private:
    BilibiliApi m_api;
};
}
