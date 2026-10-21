#include "AccountController.h"
#include "OnlineMusicProvider.h"
#include <qt6keychain/keychain.h>
#include <qrencode.h>
#include <QImage>
#include <QBuffer>

namespace {
constexpr auto service = "NextKde.KMusic";
constexpr auto key = "netease.session";
QString qrData(const QString &url) {
    QRcode *qr = QRcode_encodeString(url.toUtf8().constData(), 0, QR_ECLEVEL_M, QR_MODE_8, 1);
    if (!qr) return {};
    const int margin = 4, scale = 6;
    QImage image((qr->width + margin * 2) * scale, (qr->width + margin * 2) * scale, QImage::Format_RGB32);
    image.fill(Qt::white);
    for (int y = 0; y < qr->width; ++y) for (int x = 0; x < qr->width; ++x)
        if (qr->data[y * qr->width + x] & 1)
            for (int dy = 0; dy < scale; ++dy) for (int dx = 0; dx < scale; ++dx)
                image.setPixel((x + margin) * scale + dx, (y + margin) * scale + dy, qRgb(0,0,0));
    QRcode_free(qr);
    QByteArray bytes; QBuffer buffer(&bytes); buffer.open(QIODevice::WriteOnly); image.save(&buffer, "PNG");
    return QStringLiteral("data:image/png;base64,") + QString::fromLatin1(bytes.toBase64());
}
}
AccountController::AccountController(OnlineMusicProvider *provider, QObject *parent) : QObject(parent), m_provider(provider) {
    m_poll.setSingleShot(true); m_poll.setInterval(2000);
    connect(&m_poll, &QTimer::timeout, this, &AccountController::poll);
    connect(provider, &OnlineMusicProvider::sessionExpired, this, [this] {
        if (m_state != "signedIn") return;
        ++m_generation; m_poll.stop(); m_key.clear(); m_image.clear(); m_nickname.clear();
        m_provider->accountRequest("sessionRestore", {{"cookie", ""}}, [](const QJsonObject &) {});
        clearStored(); setState("expired", tr("Your NetEase session expired. Sign in again.")); emit sessionChanged();
    });
    QTimer::singleShot(0, this, &AccountController::restore);
}
void AccountController::setState(const QString &state, const QString &message) { m_state = state; m_message = message; emit changed(); }
void AccountController::restore() {
    const auto generation = ++m_generation;
    setState("restoring", tr("Checking saved session…"));
    auto *job = new QKeychain::ReadPasswordJob(service, this);
    job->setKey(key); job->setInsecureFallback(false);
    connect(job, &QKeychain::Job::finished, this, [this, job, generation] {
        if (generation != m_generation) return;
        if (job->error() == QKeychain::EntryNotFound) { setState("signedOut"); return; }
        if (job->error() != QKeychain::NoError) {
            m_storageMessage = tr("System credential storage is unavailable. New sign-ins will remain in this session until storage succeeds.");
            setState("signedOut"); return;
        }
        const QString cookie = job->textData();
        if (cookie.isEmpty()) { setState("signedOut"); return; }
        m_provider->accountRequest("sessionRestore", {{"cookie", cookie}}, [this, generation](const QJsonObject &response) {
            if (generation != m_generation) return;
            if (!response.value("ok").toBool()) { setState("error", tr("Could not restore the session. Retry.")); return; }
            checkSession(generation);
        });
    });
    job->start();
}
void AccountController::retrySession() { if (m_state != "signedIn") restore(); }
void AccountController::beginLogin() {
    if (authenticated()) return;
    const auto generation = ++m_generation; m_poll.stop(); m_image.clear(); m_key.clear();
    setState("generating", tr("Creating a secure sign-in code…"));
    m_provider->accountRequest("qrKey", {}, [this, generation](const QJsonObject &response) {
        if (generation != m_generation) return;
        const QString key = response.value("body").toObject().value("key").toString();
        if (!response.value("ok").toBool() || key.isEmpty()) { setState("error", tr("Could not create a sign-in code. Check your connection and retry.")); return; }
        m_key = key; m_image = qrData("https://music.163.com/login?codekey=" + key);
        if (m_image.isEmpty()) { setState("error", tr("Could not generate the sign-in image.")); return; }
        m_expiry.start(); setState("waiting", tr("Scan with the NetEase Cloud Music app, then confirm on your phone.")); m_poll.start();
    });
}
void AccountController::cancelLogin() {
    if (authenticated() || m_state == "restoring") return;
    ++m_generation; m_poll.stop(); m_key.clear(); m_image.clear();
    m_provider->accountRequest("sessionRestore", {{"cookie", ""}}, [](const QJsonObject &) {});
    setState("signedOut");
}
void AccountController::poll() {
    if (m_key.isEmpty()) return;
    if (m_expiry.elapsed() > 180000) { m_image.clear(); m_key.clear(); setState("expired", tr("Sign-in code expired. Generate a new code.")); return; }
    const auto generation = m_generation;
    m_provider->accountRequest("qrCheck", {{"key", m_key}}, [this, generation](const QJsonObject &response) {
        if (generation != m_generation) return;
        const auto body = response.value("body").toObject(); const int code = body.value("code").toInt();
        if (!response.value("ok").toBool()) { m_image.clear(); setState("error", tr("Could not check sign-in. Retry with a new code.")); return; }
        if (code == 800) { m_image.clear(); m_key.clear(); setState("expired", tr("Sign-in code expired. Generate a new code.")); return; }
        if (code == 803) {
            m_image.clear(); m_key.clear(); setState("checking", tr("Verifying account…"));
            checkSession(generation, body.value("sessionCookie").toString()); return;
        }
        if (code != 801 && code != 802) { m_image.clear(); setState("error", tr("NetEase did not confirm this sign-in. Try again.")); return; }
        setState(code == 802 ? "scanned" : "waiting", code == 802 ? tr("Scanned. Confirm sign-in on your phone.") : tr("Scan with the NetEase Cloud Music app, then confirm on your phone."));
        m_poll.start();
    });
}
void AccountController::checkSession(quint64 generation, const QString &cookie) {
    m_provider->accountRequest("accountStatus", {}, [this, generation, cookie](const QJsonObject &response) {
        if (generation != m_generation) return;
        if (!response.value("ok").toBool()) { setState("error", tr("Unable to verify your session. Check the connection and retry.")); return; }
        const auto body = response.value("body").toObject();
        if (!body.value("authenticated").toBool()) {
            m_nickname.clear(); clearStored();
            m_provider->accountRequest("sessionRestore", {{"cookie", ""}}, [](const QJsonObject &) {});
            setState("expired", tr("Your NetEase session expired. Sign in again.")); return;
        }
        m_nickname = body.value("nickname").toString(); setState("signedIn", tr("Signed in to NetEase")); emit sessionChanged();
        if (!cookie.isEmpty()) save(cookie);
    });
}
void AccountController::save(const QString &cookie) {
    const auto generation = m_generation;
    auto *job = new QKeychain::WritePasswordJob(service, this); job->setKey(key); job->setTextData(cookie); job->setInsecureFallback(false);
    connect(job, &QKeychain::Job::finished, this, [this, job, generation] {
        if (generation != m_generation) return;
        m_storageMessage = job->error() == QKeychain::NoError ? tr("Session saved in the system credential store.") : tr("Could not save securely. Signed in for this session only."); emit changed();
    });job->start();
}
void AccountController::clearStored() {
    auto *job = new QKeychain::DeletePasswordJob(service, this); job->setKey(key); job->setInsecureFallback(false);
    connect(job, &QKeychain::Job::finished, this, [this, job] {
        if (job->error() != QKeychain::NoError && job->error() != QKeychain::EntryNotFound) {
            m_storageMessage = tr("Could not remove the saved session from the system credential store. Unlock it and retry sign-out."); emit changed();
        }
    });job->start();
}
void AccountController::logout() {
    ++m_generation; m_poll.stop(); m_key.clear(); m_image.clear(); m_nickname.clear(); m_storageMessage.clear();
    m_provider->accountRequest("logout", {}, [](const QJsonObject &) {}); clearStored(); setState("signedOut", tr("Signed out on this device.")); emit sessionChanged();
}
