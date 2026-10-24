#pragma once
#include "BilibiliApi.h"
#include "BilibiliDetail.h"
#include "../contracts/PlaybackResolver.h"
namespace MusicProviders {
class BilibiliPlaybackResolver final : public QObject, public PlaybackResolver {
public:
    explicit BilibiliPlaybackResolver(QObject *parent = nullptr) : QObject(parent), m_api(this), m_detail(this) {}
    Request *resolve(const MediaId &, const QString &, QObject *, Completion<PlaybackSource>) override;
    static Result<PlaybackSource> decode(const MediaId &, const QByteArray &);
private:
    BilibiliApi m_api;
    BilibiliDetail m_detail;
};
}
