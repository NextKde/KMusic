#include "BilibiliLibraryController.h"
using namespace MusicProviders;
namespace {
QVariantList mediaRows(const QList<MediaItem> &items) {
    QVariantList rows;
    for (const auto &item : items) rows.append(QVariantMap{{"title", item.title}, {"artist", item.creator},
        {"artwork", item.artwork}, {"providerId", item.id.item}, {"durationMs", item.durationMs}});
    return rows;
}
}
BilibiliLibraryController::BilibiliLibraryController(BilibiliSession &session, BilibiliAccountController &account, QObject *parent)
    : QObject(parent), m_account(account), m_provider(session) {
    connect(&account, &BilibiliAccountController::sessionChanged, this, &BilibiliLibraryController::reset);
}
void BilibiliLibraryController::reset() {
    ++m_epoch; delete m_request; m_request = nullptr; m_folders.clear(); m_items.clear(); m_history.clear();
    m_folderId.clear(); m_folderTitle.clear(); m_next.clear(); m_error.clear(); m_busy = false; m_historyMode = false;
    m_provider.setAccount(m_account.scope()); emit changed();
}
QVariantList BilibiliLibraryController::folders() const {
    QVariantList rows; for (const auto &folder : m_folders) rows.append(QVariantMap{{"title", folder.title}, {"providerId", folder.id}, {"artwork", folder.artwork}}); return rows;
}
QVariantList BilibiliLibraryController::items() const { return mediaRows(m_items); }
QVariantList BilibiliLibraryController::history() const { return mediaRows(m_history); }
bool BilibiliLibraryController::fail(const Error &error) {
    if (error.code == ErrorCode::AuthenticationRequired) { m_account.expire(); return true; }
    if (error.code != ErrorCode::Cancelled) m_error = error.code == ErrorCode::VerificationRequired ? "verification" : error.code == ErrorCode::RateLimited ? "rateLimited" : "unavailable";
    return true;
}
void BilibiliLibraryController::retry() {
    if (!m_account.authenticated() || m_busy) return;
    if (m_historyMode || !m_folderId.isEmpty()) fetch(!m_next.isEmpty()); else reload();
}
void BilibiliLibraryController::reload() {
    if (!m_account.authenticated() || m_busy) return;
    reset(); m_busy = true; const auto epoch = m_epoch; emit changed();
    m_request = m_provider.list(m_account.scope(), LibraryKind::Playlists, {}, this, [this, epoch](Result<Page<LibraryEntry>> result) {
        if (epoch != m_epoch) return;
        auto request = m_request; m_request = nullptr; if (request) request->deleteLater();
        m_busy = false;
        if (auto e = std::get_if<Error>(&result)) fail(*e);
        else for (const auto &entry : std::get<Page<LibraryEntry>>(result).items) if (auto folder = std::get_if<Collection>(&entry)) m_folders.append(*folder);
        emit changed();
    });
}
void BilibiliLibraryController::openFolder(int row) {
    if (!m_account.authenticated() || row < 0 || row >= m_folders.size()) return;
    ++m_epoch; delete m_request; m_historyMode = false; m_folderId = m_folders[row].id; m_folderTitle = m_folders[row].title;
    m_items.clear(); m_next.clear(); fetch(false);
}
void BilibiliLibraryController::showHistory() {
    if (!m_account.authenticated()) return;
    ++m_epoch; delete m_request; m_folderId.clear(); m_folderTitle.clear(); m_historyMode = true;
    m_history.clear(); m_next.clear(); fetch(false);
}
void BilibiliLibraryController::fetch(bool more) {
    delete m_request; m_request = nullptr; m_busy = true; m_error.clear(); emit changed();
    const auto epoch = m_epoch;
    auto done = [this, epoch](Result<Page<LibraryEntry>> result) {
        if (epoch != m_epoch) return;
        auto request = m_request; m_request = nullptr; if (request) request->deleteLater();
        m_busy = false;
        if (auto e = std::get_if<Error>(&result)) fail(*e);
        else {
            const auto page = std::get<Page<LibraryEntry>>(result); m_next = page.nextCursor;
            auto &list = m_historyMode ? m_history : m_items;
            for (const auto &entry : page.items) if (auto item = std::get_if<MediaItem>(&entry)) {
                bool duplicate = false; for (const auto &old : list) duplicate |= old.id == item->id;
                if (!duplicate) list.append(*item);
            }
        }
        emit changed();
    };
    const PageRequest page{more ? m_next : QString{}, 20};
    if (m_historyMode) m_request = m_provider.list(m_account.scope(), LibraryKind::History, page, this, done);
    else m_request = m_provider.folder(m_account.scope(), m_folderId, page, this, done);
}
void BilibiliLibraryController::loadMore() { if (m_account.authenticated() && !m_busy && !m_next.isEmpty()) fetch(true); }
void BilibiliLibraryController::back() { ++m_epoch; delete m_request; m_request = nullptr; m_busy = false; m_historyMode = false; m_folderId.clear(); m_folderTitle.clear(); m_next.clear(); m_error.clear(); emit changed(); }
void BilibiliLibraryController::play(int row) {
    const auto &list = m_historyMode ? m_history : m_items;
    if (!m_account.authenticated() || row < 0 || row >= list.size() || list[row].id.scope != m_account.scope()) return;
    // Keep private library identities private. Explicit playback is a public
    // BV/cid identity, resolved using the current Bili session, never persisted cookies.
    auto item = list[row]; item.id.scope.account.clear(); emit selected(item);
}
