#pragma once
#include "BilibiliApi.h"
#include "../contracts/DetailProvider.h"

namespace MusicProviders {
class BilibiliDetail final : public QObject, public DetailProvider {
public:
    explicit BilibiliDetail(QObject *parent = nullptr, BilibiliSession *session = nullptr);
    Request *detail(const MediaId &, QObject *context, Completion<MediaDetail>) override;
    static Result<MediaDetail> decode(const MediaId &, const QByteArray &);
private:
    BilibiliApi m_transport;
};
}
