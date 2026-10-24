#include "WbiSigner.h"
#include <QCryptographicHash>
#include <QRegularExpression>
namespace MusicProviders {
Result<QUrlQuery> WbiSigner::sign(QMap<QString, QString> parameters,
                                 const QString &imageKey, const QString &subKey, qint64 timestamp)
{
    // Protocol permutation, independently implemented from published WBI specification.
    constexpr int positions[] = {46,47,18,2,53,8,23,32,15,50,10,31,58,3,45,35,
                                27,43,5,49,33,9,42,19,29,28,14,39,12,38,41,13};
    static const QRegularExpression keyPattern(QStringLiteral("^[a-fA-F0-9]{32}$"));
    if (!keyPattern.match(imageKey).hasMatch() || !keyPattern.match(subKey).hasMatch() || timestamp < 0)
        return Error{ErrorCode::InvalidResponse, QStringLiteral("Invalid Bilibili signing keys.")};
    const QString raw = imageKey + subKey;
    QByteArray salt;
    for (const int position : positions) salt.append(raw.at(position).toLatin1());
    parameters.remove("w_rid"); parameters["wts"] = QString::number(timestamp);
    QByteArray encoded;
    for (auto it = parameters.cbegin(); it != parameters.cend(); ++it) {
        QString value = it.value();
        for (const QChar character : QStringLiteral("!'()*")) value.remove(character);
        if (!encoded.isEmpty()) encoded.append('&');
        encoded += QUrl::toPercentEncoding(it.key()) + '=' + QUrl::toPercentEncoding(value);
    }
    const auto digest = QCryptographicHash::hash(encoded + salt, QCryptographicHash::Md5).toHex();
    return QUrlQuery(QString::fromLatin1(encoded + "&w_rid=" + digest));
}
}
