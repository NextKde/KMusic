#pragma once
#include "ProviderTypes.h"
#include "Request.h"

namespace MusicProviders {
enum class LibraryKind { Favorites, History, Playlists };
struct Collection {
    SourceScope scope;
    QString id;
    QString title;
    QUrl artwork;
};
using LibraryEntry = std::variant<MediaItem, Collection>;
class LibraryProvider {
public:
    virtual ~LibraryProvider() = default;
    virtual Request *list(const SourceScope &, LibraryKind, const PageRequest &,
                          QObject *context, Completion<Page<LibraryEntry>>) = 0;
};
}
