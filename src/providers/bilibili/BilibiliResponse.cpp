#include "BilibiliResponse.h"
#include <QJsonDocument>
namespace MusicProviders {
Result<QJsonObject> biliData(const QByteArray &body) {
    const auto doc = QJsonDocument::fromJson(body);
    const auto root = doc.object();
    if (!doc.isObject() || !root.value("code").isDouble())
        return Error{ErrorCode::InvalidResponse, QStringLiteral("Invalid Bilibili response.")};
    const int code = root.value("code").toInt();
    const auto data = root.value("data").toObject();
    if (code == -352 || code == -412 || code == -403 || data.contains("v_voucher"))
        return Error{ErrorCode::VerificationRequired, QStringLiteral("Bilibili requires verification. Please use its official website.")};
    if (code == -101) return Error{ErrorCode::AuthenticationRequired, QStringLiteral("Bilibili sign-in is required.")};
    if (code != 0) return Error{ErrorCode::Unavailable, QStringLiteral("Bilibili content is unavailable.")};
    if (!root.value("data").isObject()) return Error{ErrorCode::InvalidResponse, QStringLiteral("Bilibili response has no data.")};
    return data;
}
}
