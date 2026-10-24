#pragma once

#include <QList>
#include <QString>
#include <QUrl>
#include <functional>
#include <variant>

namespace MusicProviders {
// Stable identity; never use a temporary stream URL as a library/cache key.
struct SourceScope {
    QString provider;
    QString instance;
    QString account;
    bool operator==(const SourceScope &) const = default;
};
struct MediaId {
    SourceScope scope;
    QString item;
    QString part;
    bool operator==(const MediaId &) const = default;
};
enum class ErrorCode {
    InvalidRequest, Cancelled, Network, Timeout, RateLimited,
    AuthenticationRequired, VerificationRequired, Unavailable, InvalidResponse
};
struct Error {
    ErrorCode code;
    QString message; // Sanitized for UI: no cookies, signed URLs or raw response body.
    bool retryable = false;
};
template<class T> using Result = std::variant<T, Error>;
template<class T> using Completion = std::function<void(Result<T>)>;
struct MediaItem {
    MediaId id;
    QString title;
    QString creator;
    QUrl artwork;
    qint64 durationMs = 0;
};
struct PageRequest { QString cursor; int limit = 20; };
template<class T> struct Page { QList<T> items; QString nextCursor; };
}
