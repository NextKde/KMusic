#pragma once
#include "BilibiliSession.h"
#include "../contracts/AccountProvider.h"
#include <QElapsedTimer>
namespace MusicProviders {
class BilibiliAccount final : public AccountProvider {
public:
    explicit BilibiliAccount(BilibiliSession &session) : m_session(session) {}
    Request *beginLogin(QObject *, Completion<LoginChallenge>) override;
    Request *pollLogin(QObject *, Completion<LoginProgress>) override;
    Request *refreshSession(QObject *, Completion<Account>) override;
    void signOut() override;
    void cancelLogin();
    static Result<LoginChallenge> decodeChallenge(const QByteArray &, QString *privateKey = nullptr);
    static Result<LoginState> decodePoll(const QByteArray &);
    static Result<Account> decodeAccount(const QByteArray &);
private:
    BilibiliSession &m_session;
    QString m_key;
    QElapsedTimer m_challengeAge;
    quint64 m_loginEpoch = 0;
};
}
