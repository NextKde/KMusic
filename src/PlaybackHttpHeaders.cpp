#include "PlaybackHttpHeaders.h"
#include <gst/gst.h>
namespace {
struct Headers { QByteArray agent, referer; };
}
unsigned long installPlaybackHttpHeaders(GstElement *player, const QByteArray &userAgent, const QUrl &referer)
{
    if (userAgent.isEmpty() && referer.isEmpty()) return 0;
    if (userAgent.contains('\r') || userAgent.contains('\n')) return 0;
    auto *snapshot = new Headers{userAgent, referer.toEncoded()};
    return g_signal_connect_data(player, "source-setup", G_CALLBACK(+[](
        GstElement *, GstElement *source, gpointer data) {
        const auto *headers = static_cast<const Headers *>(data);
        if (!headers->agent.isEmpty() && g_object_class_find_property(G_OBJECT_GET_CLASS(source), "user-agent"))
            g_object_set(source, "user-agent", headers->agent.constData(), nullptr);
        if (!headers->referer.isEmpty() && g_object_class_find_property(G_OBJECT_GET_CLASS(source), "extra-headers")) {
            GstStructure *fields = gst_structure_new("headers", "Referer", G_TYPE_STRING, headers->referer.constData(), nullptr);
            g_object_set(source, "extra-headers", fields, nullptr);
            gst_structure_free(fields);
        }
    }), snapshot, +[](gpointer data, GClosure *) { delete static_cast<Headers *>(data); }, GConnectFlags(0));
}
