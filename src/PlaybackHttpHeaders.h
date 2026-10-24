#pragma once
#include <QByteArray>
#include <QUrl>
typedef struct _GstElement GstElement;
// Immutable per-load snapshot retained by the signal closure, safe on streaming threads.
unsigned long installPlaybackHttpHeaders(GstElement *player, const QByteArray &userAgent, const QUrl &referer);
