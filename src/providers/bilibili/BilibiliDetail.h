#pragma once
#include "../HttpTransport.h"
#include "../contracts/DetailProvider.h"

namespace MusicProviders {
class BilibiliDetail final : public QObject, public DetailProvider {
public:
    explicit BilibiliDetail(QObject *parent = nullptr);
    Request *detail(const MediaId &, QObject *context, Completion<MediaDetail>) override;
    static Result<MediaDetail> decode(const MediaId &, const QByteArray &);
private:
    HttpTransport m_transport;
};
}
