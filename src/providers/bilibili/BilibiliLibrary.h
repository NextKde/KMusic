#pragma once
#include "BilibiliSession.h"
#include "../contracts/LibraryProvider.h"
namespace MusicProviders {
// Read-only cloud library. Private identity is retained until explicit playback.
class BilibiliLibrary final : public LibraryProvider {
public:
    explicit BilibiliLibrary(BilibiliSession &session) : m_session(session) {}
    void setAccount(const SourceScope &scope) { m_scope = scope; }
    Request *list(const SourceScope &, LibraryKind, const PageRequest &, QObject *, Completion<Page<LibraryEntry>>) override;
    Request *folder(const SourceScope &, const QString &, const PageRequest &, QObject *, Completion<Page<LibraryEntry>>);
    static Result<Page<LibraryEntry>> decodeFolders(const SourceScope &, const QByteArray &);
    static Result<Page<LibraryEntry>> decodeFolder(const SourceScope &, const QByteArray &, int page);
    static Result<Page<LibraryEntry>> decodeHistory(const SourceScope &, const QByteArray &, const QString &cursor = {});
private:
    Request *fetch(const SourceScope &, const QString &, const QUrlQuery &, QObject *, Completion<QByteArray>);
    BilibiliSession &m_session;
    SourceScope m_scope;
};
}
