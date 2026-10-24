#pragma once

#include <QObject>
#include <functional>
#include <QPointer>
#include <QNetworkReply>

namespace MusicProviders {
// Owned by the caller's context. Destroying it aborts without calling completion.
// cancel() completes once with Cancelled; retain as QPointer across event loops.
class Request final : public QObject {
public:
    explicit Request(QObject *context) : QObject(context) {}
    ~Request() override;
    void cancel();
    void setCancelHandler(std::function<void()> handler) { m_cancelHandler = std::move(handler); }
private:
    friend class HttpTransport;
    friend class BilibiliSession;
    QPointer<QNetworkReply> m_reply;
    bool m_cancelled = false;
    std::function<void()> m_cancelHandler;
};
}
