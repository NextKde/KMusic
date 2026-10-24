#include "contracts/Request.h"

namespace MusicProviders {
Request::~Request()
{
    if (m_reply) {
        QObject::disconnect(m_reply, nullptr, this, nullptr);
        m_reply->abort();
        m_reply->deleteLater();
    }
}
void Request::cancel()
{
    if (m_cancelled) return;
    m_cancelled = true;
    if (m_cancelHandler) { m_cancelHandler(); return; }
    if (m_reply) m_reply->abort();
}
}
