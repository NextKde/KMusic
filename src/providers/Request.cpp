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
    m_cancelled = true;
    if (m_reply) m_reply->abort();
}
}
