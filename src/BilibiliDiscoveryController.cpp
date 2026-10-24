#include "BilibiliDiscoveryController.h"
using namespace MusicProviders;
BilibiliDiscoveryController::BilibiliDiscoveryController(BilibiliSession &session, BilibiliAccountController &account, QObject *parent)
    : QObject(parent), m_account(account), m_provider(session) {
    for (const auto &name : {"newSongs", "recommendations", "popular", "following"}) m_sections.insert(name, {});
    connect(&account, &BilibiliAccountController::sessionChanged, this, &BilibiliDiscoveryController::resetFollowing);
}
BilibiliDiscoveryController::~BilibiliDiscoveryController() {
    // Requests hold callbacks into this controller and must die before its state/provider.
    for (auto &state : m_sections) ++state.epoch;
    for (auto request : m_requests) delete request;
}
QVariantMap BilibiliDiscoveryController::sections() const {
    QVariantMap result;
    for (auto it = m_sections.cbegin(); it != m_sections.cend(); ++it) {
        QVariantList rows;
        for (const auto &item : it->items) rows.append(QVariantMap{{"providerId", item.id.item}, {"title", item.title}, {"artist", item.creator}, {"artwork", item.artwork}});
        result.insert(it.key(), QVariantMap{{"items", rows}, {"loading", it->loading}, {"error", it->error}, {"more", !it->next.isEmpty()}, {"loaded", it->loaded}});
    }
    return result;
}
void BilibiliDiscoveryController::resetFollowing() {
    auto &state = m_sections["following"]; state.clear();
    delete m_requests["following"]; m_requests["following"] = nullptr;
    m_provider.setAccount(m_account.scope()); emit changed();
    // Public discovery is independent of account cookies. Only private updates refresh.
    if (m_account.authenticated()) fetch("following", false);
}
void BilibiliDiscoveryController::ensureLoaded() {
    for (auto it = m_sections.cbegin(); it != m_sections.cend(); ++it)
        if (!it->loaded && !it->loading && it->error.isEmpty() && (it.key() != "following" || m_account.authenticated())) fetch(it.key(), false);
}
void BilibiliDiscoveryController::reload(const QString &section) {
    if (!m_sections.contains(section)) return;
    m_sections[section].clear(); delete m_requests[section]; m_requests[section] = nullptr;
    fetch(section, false);
}
void BilibiliDiscoveryController::retry(const QString &section) {
    if (!m_sections.contains(section) || m_sections[section].loading) return;
    fetch(section, !m_sections[section].next.isEmpty());
}
void BilibiliDiscoveryController::loadMore(const QString &section) {
    if (m_sections.contains(section) && !m_sections[section].loading && !m_sections[section].next.isEmpty()) fetch(section, true);
}
void BilibiliDiscoveryController::fetch(const QString &section, bool more) {
    auto &state = m_sections[section]; if (state.loading) return;
    if (section == "following" && !m_account.authenticated()) { state.error = "auth"; state.loading = false; emit changed(); return; }
    const auto scope = section == "following" ? m_account.scope() : SourceScope{"bilibili", {}, {}};
    const auto generation = state.epoch; const QString cursor = more ? state.next : QString{};
    delete m_requests[section]; m_requests[section] = nullptr;
    state.loading = true; state.error.clear(); emit changed();
    m_requests[section] = m_provider.page(scope, section, cursor, this, [this, section, generation, cursor, scope](Result<Page<MediaItem>> result) {
        auto &state = m_sections[section];
        if (generation != state.epoch || (section == "following" && scope != m_account.scope())) return;
        auto request = m_requests[section]; m_requests[section] = nullptr; if (request) request->deleteLater();
        state.loading = false;
        if (auto error = std::get_if<Error>(&result)) {
            if (error->code == ErrorCode::AuthenticationRequired && section == "following") { m_account.expire(); return; }
            if (error->code != ErrorCode::Cancelled) state.error = error->code == ErrorCode::VerificationRequired ? "verification"
                : error->code == ErrorCode::RateLimited ? "rateLimited" : error->code == ErrorCode::InvalidResponse ? "response" : "network";
        } else state.accept(generation, std::get<Page<MediaItem>>(result), cursor, section == "recommendations");
        emit changed();
    });
}
void BilibiliDiscoveryController::play(const QString &section, int row) {
    if (!m_sections.contains(section)) return;
    const auto &items = m_sections[section].items;
    if (row < 0 || row >= items.size()) return;
    auto item = items[row];
    if (section == "following" && (!m_account.authenticated() || item.id.scope != m_account.scope())) return;
    // Private membership does not become a persisted media identity.
    item.id.scope.account.clear(); emit selected(item);
}
