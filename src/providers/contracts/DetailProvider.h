#pragma once
#include "ProviderTypes.h"
#include "Request.h"

namespace MusicProviders {
struct MediaDetail { MediaItem item; QList<MediaItem> parts; };
class DetailProvider {
public:
    virtual ~DetailProvider() = default;
    virtual Request *detail(const MediaId &, QObject *context, Completion<MediaDetail>) = 0;
};
}
