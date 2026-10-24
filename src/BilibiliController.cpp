#include "BilibiliController.h"
#include <QRegularExpression>
using namespace MusicProviders;
namespace {
QVariantList rows(const QList<MediaItem> &items) {
    QVariantList result;
    for (const auto &item : items) result.append(QVariantMap{
        {"title", item.title}, {"creator", item.creator}, {"artwork", item.artwork},
        {"bvid", item.id.item}, {"cid", item.id.part}, {"durationMs", item.durationMs}});
    return result;
}
}
BilibiliController::BilibiliController(QObject *parent) : QObject(parent), m_session(this), m_account(m_session, this),
    m_library(m_session, m_account, this), m_search(this, &m_session), m_detail(this, &m_session), m_resolver(this, &m_session) {
    connect(&m_library, &BilibiliLibraryController::selected, this, &BilibiliController::select);
    connect(&m_account, &BilibiliAccountController::sessionChanged, this, [this] { cancelBrowse(); cancelPlayback(); });
}
QVariantList BilibiliController::results() const { return rows(m_results); }
QVariantList BilibiliController::parts() const { return rows(m_parts); }
void BilibiliController::cancelBrowse() {
    delete m_searchRequest; delete m_detailRequest;
    m_busy = false; m_results.clear(); m_parts.clear(); m_next.clear(); m_error.clear(); emit changed();
}
void BilibiliController::search(const QString &query) {
    cancelBrowse(); m_query = query.trimmed();
    if (m_query.isEmpty()) return;
    // Accept a BV identifier or an official video URL as an explicit detail lookup.
    const QUrl url(m_query);
    QString bv = m_query;
    if (url.host() == "www.bilibili.com" || url.host() == "bilibili.com")
        bv = url.path().section('/', 2, 2);
    static const QRegularExpression pattern("^BV[0-9A-Za-z]{10}$");
    if (pattern.match(bv).hasMatch()) {
        m_busy = true; emit changed();
        m_detailRequest = m_detail.detail({{"bilibili", {}, {}}, bv, {}}, this, [this](Result<MediaDetail> result) {
            m_busy = false;
            if (auto error = std::get_if<Error>(&result)) m_error = error->message;
            else { const auto detail = std::get<MediaDetail>(result); m_results = {detail.item}; m_parts = detail.parts; }
            emit changed();
        });
        return;
    }
    fetch(false);
}
void BilibiliController::fetch(bool more) {
    delete m_searchRequest;
    m_busy = true; m_error.clear(); emit changed();
    m_searchRequest = m_search.search({"bilibili", {}, {}}, m_query, {more ? m_next : QString{}, 20}, this,
        [this, more](Result<Page<MediaItem>> result) {
            m_busy = false;
            if (auto error = std::get_if<Error>(&result)) m_error = error->message;
            else {
                auto page = std::get<Page<MediaItem>>(result);
                if (!more) m_results.clear();
                for (const auto &item : page.items) {
                    bool duplicate = false;
                    for (const auto &old : m_results) duplicate |= old.id == item.id;
                    if (!duplicate) m_results.append(item);
                }
                m_next = page.nextCursor;
            }
            emit changed();
        });
}
void BilibiliController::loadMore() { if (!m_busy && !m_next.isEmpty()) fetch(true); }
void BilibiliController::openParts(int row) {
    if (row < 0 || row >= m_results.size()) return;
    delete m_detailRequest; m_parts.clear(); m_error.clear(); emit changed();
    m_detailRequest = m_detail.detail(m_results[row].id, this, [this](Result<MediaDetail> result) {
        if (auto error = std::get_if<Error>(&result)) m_error = error->message;
        else m_parts = std::get<MediaDetail>(result).parts;
        emit changed();
    });
}
void BilibiliController::select(const MediaItem &item) {
    TrackRecord track;
    track.source = "bilibili";
    track.providerId = item.id.item + (item.id.part.isEmpty() ? QString{} : ":" + item.id.part);
    track.path = "bilibili:" + track.providerId;
    track.title = item.title; track.artist = item.creator; track.artworkUrl = item.artwork.toString();
    track.durationMs = item.durationMs; track.format = "AAC";
    emit trackSelected(track);
}
void BilibiliController::play(int row) { if (row >= 0 && row < m_results.size()) select(m_results[row]); }
void BilibiliController::playPart(int row) { if (row >= 0 && row < m_parts.size()) select(m_parts[row]); }
void BilibiliController::cancelPlayback() { delete m_playRequest; }
void BilibiliController::prepare(qint64 trackId, const QString &providerId) {
    cancelPlayback();
    MediaId id{{"bilibili", {}, {}}, providerId.section(':', 0, 0), providerId.section(':', 1, 1)};
    m_playRequest = m_resolver.resolve(id, "AAC", this, [this, trackId](Result<PlaybackSource> result) {
        if (auto error = std::get_if<Error>(&result)) emit failed(trackId, error->message);
        else emit resolved(trackId, std::get<PlaybackSource>(result));
    });
}
