#pragma once
#include "providers/contracts/ProviderTypes.h"
#include <QSet>
// Small state object shared by the controller and deterministic lifecycle fixtures.
struct BilibiliFeedState {
    QList<MusicProviders::MediaItem> items;
    QSet<QString> cursors;
    QString next, error;
    bool loading = false, loaded = false;
    quint64 epoch = 0;
    void clear() { ++epoch; items.clear(); cursors.clear(); next.clear(); error.clear(); loading = false; loaded = false; }
    bool accept(quint64 generation, const MusicProviders::Page<MusicProviders::MediaItem> &page, const QString &requested, bool stopOnDuplicates) {
        if (generation != epoch) return false;
        loading = false;
        if (!page.nextCursor.isEmpty() && (page.nextCursor == requested || cursors.contains(page.nextCursor))) { error = "response"; return false; }
        const auto before = items.size();
        for (const auto &item : page.items) {
            bool duplicate = false; for (const auto &old : items) duplicate |= old.id == item.id;
            if (!duplicate) items.append(item);
        }
        if (!requested.isEmpty()) cursors.insert(requested);
        next = stopOnDuplicates && items.size() == before ? QString{} : page.nextCursor;
        error.clear(); loaded = true; return true;
    }
};
