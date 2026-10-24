#include "BilibiliAccountController.h"
#include <qt6keychain/keychain.h>
#include <QSettings>
#include <QJsonDocument>
#include <QJsonObject>
#include <QImage>
#include <QBuffer>
#include <qrencode.h>
using namespace MusicProviders;
namespace {
constexpr auto service = "NextKde.KMusic";
constexpr auto key = "bilibili.session";
QString makeQrImage(const QUrl &url) {
    auto *code = QRcode_encodeString(url.toEncoded().constData(), 0, QR_ECLEVEL_M, QR_MODE_8, 1);
    if (!code) return {};
    QImage image((code->width + 8) * 6, (code->width + 8) * 6, QImage::Format_RGB32); image.fill(Qt::white);
    for (int y = 0; y < code->width; ++y) for (int x = 0; x < code->width; ++x)
        if (code->data[y * code->width + x] & 1)
            for (int dy = 0; dy < 6; ++dy) for (int dx = 0; dx < 6; ++dx) image.setPixel((x + 4) * 6 + dx, (y + 4) * 6 + dy, qRgb(0,0,0));
    QRcode_free(code); QByteArray bytes; QBuffer buffer(&bytes); buffer.open(QIODevice::WriteOnly); image.save(&buffer, "PNG");
    return "data:image/png;base64," + QString::fromLatin1(bytes.toBase64());
}
}
BilibiliAccountController::BilibiliAccountController(BilibiliSession &session, QObject *parent)
    : QObject(parent), m_session(session), m_provider(session) {
    m_poll.setSingleShot(true); m_poll.setInterval(2000);
    connect(&m_poll, &QTimer::timeout, this, &BilibiliAccountController::poll);
    QTimer::singleShot(0, this, &BilibiliAccountController::restore);
}
void BilibiliAccountController::setState(const QString &state, const QString &en, const QString &zh) {
    m_state = state; m_message = en; m_messageZh = zh; emit changed();
}
void BilibiliAccountController::retireRequest() {
    auto request = m_request; m_request = nullptr; if (request) request->deleteLater();
}
void BilibiliAccountController::failure(const Error &error) {
    if (error.code == ErrorCode::AuthenticationRequired) { expire(); return; }
    if (error.code == ErrorCode::Cancelled) return;
    setState(authenticated() ? "signedIn" : "error",
        error.code == ErrorCode::VerificationRequired ? "Bilibili requires verification on its official website." : "Could not connect to Bilibili. Retry without signing out.",
        error.code == ErrorCode::VerificationRequired ? "哔哩哔哩要求验证，请先使用官方网站。" : "暂时无法连接哔哩哔哩，请重试；无需退出账号。");
}
void BilibiliAccountController::beginLogin() {
    if (authenticated() || m_storageBusy) return;
    cancelLogin(); const auto epoch = ++m_epoch;
    setState("generating", "Creating a Bilibili sign-in code…", "正在生成哔哩哔哩登录二维码…");
    m_request = m_provider.beginLogin(this, [this, epoch](Result<LoginChallenge> result) {
        if (epoch != m_epoch) return;
        retireRequest();
        if (auto error = std::get_if<Error>(&result)) { failure(*error); return; }
        m_qr = makeQrImage(std::get<LoginChallenge>(result).qrContent);
        if (m_qr.isEmpty()) { setState("error", "Could not create the sign-in image.", "无法生成登录二维码。"); return; }
        setState("waiting", "Scan with the official Bilibili app and confirm on your phone.", "请用哔哩哔哩官方手机客户端扫码，并在手机上确认。"); m_poll.start();
    });
}
void BilibiliAccountController::cancelLogin() {
    ++m_epoch; m_poll.stop(); delete m_request; m_provider.cancelLogin(); m_qr.clear();
    if (!authenticated()) { m_session.clear(); setState("signedOut", "Sign in to Bilibili.", "登录哔哩哔哩。"); }
}
void BilibiliAccountController::poll() {
    const auto epoch = m_epoch;
    m_request = m_provider.pollLogin(this, [this, epoch](Result<LoginProgress> result) {
        if (epoch != m_epoch) return;
        retireRequest();
        if (auto error = std::get_if<Error>(&result)) { m_qr.clear(); failure(*error); return; }
        const auto progress = std::get<LoginProgress>(result);
        if (progress.state == LoginState::SignedIn) {
            if (!m_session.hasSession()) { expire(); return; }
            m_identity = progress.account; m_qr.clear(); save();
            setState("signedIn", "Signed in to Bilibili.", "已登录哔哩哔哩。"); emit sessionChanged();
        } else if (progress.state == LoginState::Expired) {
            m_qr.clear(); m_provider.cancelLogin(); m_session.clear();
            setState("expired", "Sign-in code expired. Generate a new code.", "二维码已过期，请重新生成。");
        } else {
            setState(progress.state == LoginState::AwaitingApproval ? "scanned" : "waiting",
                progress.state == LoginState::AwaitingApproval ? "Scanned. Confirm on your phone." : "Waiting for the Bilibili app to scan.",
                progress.state == LoginState::AwaitingApproval ? "已扫码，请在手机上确认。" : "等待哔哩哔哩手机客户端扫码。"); m_poll.start();
        }
    });
}
void BilibiliAccountController::save() {
    m_storageBusy = true;
    const auto epoch = m_epoch;
    auto *job = new QKeychain::WritePasswordJob(service, this); job->setKey(key); job->setInsecureFallback(false);
    job->setTextData(QString::fromUtf8(QJsonDocument(QJsonObject{{"account", m_identity.scope.account},
        {"cookies", QString::fromLatin1(m_session.credentials().toBase64())}}).toJson(QJsonDocument::Compact)));
    connect(job, &QKeychain::Job::finished, this, [this, epoch, job] {
        m_storageBusy = false;
        if (m_pendingErase) { m_pendingErase = false; erase(); }
        if (epoch != m_epoch) { emit changed(); return; }
        if (job->error() == QKeychain::NoError) { QSettings().setValue("bilibili/restoreAllowed", true); m_cleanup = false; m_storage.clear(); }
        else m_storage = "Secure storage unavailable. Signed in for this session only.";
        emit changed();
    }); job->start();
}
void BilibiliAccountController::erase() {
    QSettings settings; settings.setValue("bilibili/restoreAllowed", false); settings.sync();
    if (m_storageBusy) { m_pendingErase = true; return; }
    m_storageBusy = true;
    auto *job = new QKeychain::DeletePasswordJob(service, this); job->setKey(key); job->setInsecureFallback(false);
    connect(job, &QKeychain::Job::finished, this, [this, job] {
        m_storageBusy = false; m_pendingErase = false;
        m_cleanup = job->error() != QKeychain::NoError && job->error() != QKeychain::EntryNotFound;
        m_storage = m_cleanup ? "Unlock credential storage and retry removal." : QString{}; emit changed();
    }); job->start();
}
void BilibiliAccountController::logout() {
    ++m_epoch; m_poll.stop(); delete m_request; m_qr.clear(); m_identity = {}; m_provider.signOut(); erase();
    setState("signedOut", "Signed out on this device.", "已退出此设备登录。"); emit sessionChanged();
}
void BilibiliAccountController::expire() {
    ++m_epoch; m_poll.stop(); m_qr.clear(); m_identity = {}; m_provider.signOut(); erase();
    setState("expired", "Bilibili session expired. Sign in again.", "哔哩哔哩会话已失效，请重新登录。"); emit sessionChanged();
}
void BilibiliAccountController::verify(quint64 epoch, const QString &expected) {
    m_request = m_provider.refreshSession(this, [this, epoch, expected](Result<Account> result) {
        if (epoch != m_epoch) return;
        retireRequest();
        if (auto error = std::get_if<Error>(&result)) { failure(*error); return; }
        auto account = std::get<Account>(result);
        if (!m_session.hasSession() || (!expected.isEmpty() && expected != account.scope.account)) { expire(); return; }
        m_identity = account; setState("signedIn", "Signed in to Bilibili.", "已登录哔哩哔哩。"); emit sessionChanged();
    });
}
void BilibiliAccountController::restore() {
    if (authenticated() || m_storageBusy) return;
    cancelLogin();
    const auto epoch = ++m_epoch;
    if (!QSettings().value("bilibili/restoreAllowed", false).toBool()) { setState("signedOut", "Sign in to Bilibili.", "登录哔哩哔哩。"); return; }
    setState("restoring", "Checking the saved Bilibili session…", "正在检查已保存的哔哩哔哩会话…");
    m_storageBusy = true;
    auto *job = new QKeychain::ReadPasswordJob(service, this); job->setKey(key); job->setInsecureFallback(false);
    connect(job, &QKeychain::Job::finished, this, [this, job, epoch] {
        m_storageBusy = false;
        if (m_pendingErase) { m_pendingErase = false; erase(); }
        if (epoch != m_epoch) { emit changed(); return; }
        if (job->error() != QKeychain::NoError) { setState("error", "Could not read secure storage. Unlock it and retry.", "无法读取系统凭据库，请解锁后重试。"); return; }
        const auto saved = QJsonDocument::fromJson(job->textData().toUtf8()).object();
        if (saved.value("account").toString().isEmpty() || !m_session.restore(QByteArray::fromBase64(saved.value("cookies").toString().toLatin1()))) { expire(); return; }
        verify(epoch, saved.value("account").toString());
    }); job->start();
}
void BilibiliAccountController::retrySession() { restore(); }
