#pragma once
#include "ProviderTypes.h"
#include "Request.h"

namespace MusicProviders {
enum class LoginState { SignedOut, WaitingForScan, AwaitingApproval, SignedIn, Expired };
struct Account { SourceScope scope; QString name; QUrl avatar; };
// A challenge contains only the public QR content, never cookies or polling keys.
struct LoginChallenge { QUrl qrContent; };
struct LoginProgress { LoginState state; Account account; };
class AccountProvider {
public:
    virtual ~AccountProvider() = default;
    virtual Request *beginLogin(QObject *context, Completion<LoginChallenge>) = 0;
    virtual Request *pollLogin(QObject *context, Completion<LoginProgress>) = 0;
    virtual Request *refreshSession(QObject *context, Completion<Account>) = 0;
    virtual void signOut() = 0;
};
}
