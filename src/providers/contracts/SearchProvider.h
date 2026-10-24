#pragma once
#include "ProviderTypes.h"
#include "Request.h"

namespace MusicProviders {
class SearchProvider {
public:
    virtual ~SearchProvider() = default;
    virtual Request *search(const SourceScope &, const QString &query,
                            const PageRequest &, QObject *context,
                            Completion<Page<MediaItem>>) = 0;
};
}
