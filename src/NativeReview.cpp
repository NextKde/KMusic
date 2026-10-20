#include "NativeReview.h"
#include "WindowMaterial.h"
#include <QCoreApplication>
#include <QDateTime>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusReply>
#include <QDBusUnixFileDescriptor>
#include <QDir>
#include <QFile>
#include <QFutureWatcher>
#include <QImage>
#include <QJsonDocument>
#include <QQmlEngine>
#include <QQuickView>
#include <QQuickWindow>
#include <QScreen>
#include <QtConcurrentRun>
#include <QTimer>
#include <fcntl.h>
#include <poll.h>
#include <unistd.h>
#include <memory>
#ifdef KMUSIC_HAVE_KWAYLAND_REVIEW
#include <KWayland/Client/connection_thread.h>
#include <KWayland/Client/registry.h>
#include <KWayland/Client/plasmawindowmanagement.h>
#endif

namespace {
QJsonObject rectJson(QRect rect) { return {{"x", rect.x()}, {"y", rect.y()}, {"width", rect.width()}, {"height", rect.height()}}; }
QString now() { return QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs); }
struct PipeResult { QByteArray bytes; QString error; };
struct Capture {
    QJsonObject before;
    QJsonObject runtime;
    QJsonObject verifiedWindowInfo;
    QVariantMap attributes;
    PipeResult pipe;
    QString error;
    bool dbusDone = false;
    bool pipeDone = false;
};
}
NativeReview::NativeReview(QQmlEngine *engine, WindowMaterial *material, QString reviewDir, QObject *parent)
    : QObject(parent), m_engine(engine), m_material(material), m_reviewDir(std::move(reviewDir)) {
#ifdef KMUSIC_HAVE_KWAYLAND_REVIEW
    if (!m_reviewDir.isEmpty()) {
        if (auto *connection = KWayland::Client::ConnectionThread::fromApplication(this)) {
            auto *registry = new KWayland::Client::Registry(this);
            QObject::connect(registry, &KWayland::Client::Registry::plasmaWindowManagementAnnounced,
                this, [this, registry](quint32 name, quint32 version) {
                    // Subscribe only. Never issue management/activation requests.
                    m_windowManagement = registry->createPlasmaWindowManagement(name, version, this);
                });
            registry->create(connection); registry->setup();
        }
    }
#endif
}
NativeReview::~NativeReview() { hideBackground(); }
void NativeReview::setWindow(QQuickWindow *window) { m_window = window; }
void NativeReview::respond(QJsonObject response) const {
    QFile file(QDir(m_reviewDir).filePath("response.json"));
    if (file.open(QIODevice::WriteOnly)) file.write(QJsonDocument(response).toJson());
}
void NativeReview::showBackground() {
    if (!m_window || m_reviewDir.isEmpty() || m_busy) return;
    if (!m_background) {
        m_background = new QQuickView(m_engine, nullptr);
        m_background->setTitle(QStringLiteral("KMusic dedicated native blur test background"));
        m_background->setFlags(Qt::Window | Qt::FramelessWindowHint | Qt::WindowDoesNotAcceptFocus);
        m_background->setResizeMode(QQuickView::SizeRootObjectToView);
        m_background->setSource(QUrl(QStringLiteral("qrc:/qt/qml/NextKde/Music/qml/ReviewBackdrop.qml")));
    }
    m_background->setScreen(m_window->screen());
    const auto geometry = status().value("windowGeometry").toObject();
    const QRect appRect(geometry.value("x").toInt(), geometry.value("y").toInt(), geometry.value("width").toInt(), geometry.value("height").toInt());
    if (appRect.size() != m_window->size()) return;
    // A dedicated normal window with only a 16px margin around this app.
    // Wayland placement is compositor-owned; the later guard verifies actual
    // coverage and rejects mismatches rather than assuming setGeometry worked.
    m_background->setGeometry(appRect.adjusted(-16, -16, 16, 16));
    m_background->show();
    // Re-map this dedicated app surface with its test parent already present.
    // Some Wayland integrations do not publish dynamic parent changes for an
    // existing normal toplevel. No other application's state is changed.
    m_window->hide();
    m_window->setTransientParent(m_background);
    m_window->show();
    QTimer::singleShot(200, this, [this] { if (m_background && m_background->isVisible() && m_window) m_window->requestActivate(); });
}
void NativeReview::hideBackground() {
    if (m_busy) return;
    if (m_window && m_window->transientParent() == m_background) m_window->setTransientParent(nullptr);
    if (m_background) { m_background->hide(); delete m_background; m_background = nullptr; }
}
void NativeReview::setBlurEnabled(bool enabled) {
    if (m_busy) return;
    m_blurEnabled = enabled;
    m_material->setReviewBlurEnabled(enabled);
}
QJsonObject NativeReview::status() const {
    const QRect region = m_material->region().adjusted(2, 2, -2, -2);
    QRect geometry;
    QRect backgroundGeometry;
    QString uuid;
    QString backgroundUuid;
    bool compositorActive = false;
    bool compositorParent = false;
#ifdef KMUSIC_HAVE_KWAYLAND_REVIEW
    if (auto *management = qobject_cast<KWayland::Client::PlasmaWindowManagement *>(m_windowManagement.data())) {
        KWayland::Client::PlasmaWindow *appWindow = nullptr;
        KWayland::Client::PlasmaWindow *backgroundWindow = nullptr;
        for (auto *window : management->windows()) {
            // Do not inspect or expose titles/identities from unrelated PIDs.
            if (window->pid() != QCoreApplication::applicationPid()) continue;
            if (window->title() == QStringLiteral("KMusic")) appWindow = window;
            else if (window->title() == QStringLiteral("KMusic dedicated native blur test background")
                || window->title() == QStringLiteral("KMusic dedicated native blur test background — KMusic")) backgroundWindow = window;
        }
        if (appWindow) { geometry = appWindow->geometry(); uuid = QString::fromUtf8(appWindow->uuid()); compositorActive = appWindow->isActive(); }
        if (backgroundWindow) { backgroundGeometry = backgroundWindow->geometry(); backgroundUuid = QString::fromUtf8(backgroundWindow->uuid()); }
        compositorParent = appWindow && backgroundWindow && appWindow->parentWindow() == backgroundWindow;
    }
#endif
    const bool compositorKnown = !uuid.isEmpty() && !backgroundUuid.isEmpty() && !geometry.isEmpty() && !backgroundGeometry.isEmpty();
    const QRect global = region.translated(geometry.topLeft());
    const bool backgroundVisible = m_background && m_background->isVisible() && m_background->isExposed();
    const bool sameScreen = m_window && m_background && m_background->screen() == m_window->screen();
    const bool covers = backgroundVisible && backgroundGeometry.contains(global);
    const bool transient = m_window && m_background && m_window->transientParent() == m_background;
    const bool inside = m_window && QRect(QPoint{}, m_window->size()).contains(region) && region.width() > 0 && region.height() > 0;
    const bool active = m_window && m_window->isActive() && compositorActive;
    return {{"timestamp", now()}, {"pid", QCoreApplication::applicationPid()}, {"busy", m_busy},
        {"windowActive", active}, {"windowGeometry", rectJson(geometry)}, {"qtWindowGeometry", rectJson(m_window ? m_window->geometry() : QRect{})},
        {"compositorGeometryKnown", compositorKnown}, {"windowUuid", uuid}, {"backgroundUuid", backgroundUuid}, {"compositorParentMatches", compositorParent},
        {"sidebarLocalRect", rectJson(region)},
        {"captureGlobalRect", rectJson(global)}, {"dpr", m_window ? m_window->devicePixelRatio() : 0},
        {"backgroundVisible", backgroundVisible}, {"backgroundGeometry", rectJson(backgroundGeometry)},
        {"sameScreen", sameScreen}, {"backgroundCoversCapture", covers}, {"transientParentMatches", transient},
        {"blurEnabled", m_blurEnabled}, {"effectAvailable", m_material->effectAvailable()}, {"blurRequested", m_material->blurRequested()},
        {"eligible", active && compositorKnown && compositorParent && inside && covers && sameScreen && transient && geometry.size() == m_window->size() && !m_reviewDir.isEmpty()}};
}
void NativeReview::captureSidebar(const QString &path) {
    if (m_busy) { respond({{"ok", false}, {"error", "Native capture already running"}}); return; }
    const QJsonObject before = status();
    QFile runtimeFile(QDir(m_reviewDir).filePath("../runtime.json"));
    const QJsonObject runtime = runtimeFile.open(QIODevice::ReadOnly)
        ? QJsonDocument::fromJson(runtimeFile.readAll()).object() : QJsonObject{};
    if (!before.value("eligible").toBool() || !QDir::isAbsolutePath(path)
        || runtime.value("pid").toVariant().toLongLong() != QCoreApplication::applicationPid()) {
        respond({{"ok", false}, {"error", "Capture guard failed: require active app, dedicated native background coverage and matching runtime PID"}, {"before", before}});
        return;
    }
    // Confirm that the protocol UUID still belongs to this PID immediately
    // before using its compositor coordinates. No interactive window selection.
    auto infoRequest = QDBusMessage::createMethodCall(QStringLiteral("org.kde.KWin"), QStringLiteral("/KWin"), QStringLiteral("org.kde.KWin"), QStringLiteral("getWindowInfo"));
    infoRequest.setArguments({before.value("windowUuid").toString()});
    const QDBusReply<QVariantMap> info = QDBusConnection::sessionBus().call(infoRequest, QDBus::Block, 1000);
    if (!info.isValid() || info.value().value("pid").toLongLong() != QCoreApplication::applicationPid()) {
        respond({{"ok", false}, {"error", "KWin own-window identity cross-check failed; capture skipped"}, {"before", before},
            {"windowInfo", info.isValid() ? QJsonObject::fromVariantMap(info.value()) : QJsonObject{{"error", info.error().message()}}}});
        return;
    }
    int pipes[2];
    if (::pipe2(pipes, O_CLOEXEC) != 0) { respond({{"ok", false}, {"error", "Cannot create capture pipe"}}); return; }
    m_busy = true;
    const auto capture = std::make_shared<Capture>(); capture->before = before; capture->runtime = runtime;
    capture->verifiedWindowInfo = QJsonObject::fromVariantMap(info.value());
    const auto finish = [this, capture, path] {
        if (!capture->dbusDone || !capture->pipeDone) return;
        const auto after = status();
        const bool stable = after.value("eligible").toBool()
            && after.value("windowGeometry") == capture->before.value("windowGeometry")
            && after.value("captureGlobalRect") == capture->before.value("captureGlobalRect")
            && after.value("backgroundGeometry") == capture->before.value("backgroundGeometry")
            && after.value("blurRequested") == capture->before.value("blurRequested")
            && after.value("windowUuid") == capture->before.value("windowUuid")
            && after.value("backgroundUuid") == capture->before.value("backgroundUuid")
            && after.value("dpr") == capture->before.value("dpr");
        QJsonObject report{{"ok", false}, {"path", path}, {"appRuntime", capture->runtime}, {"before", capture->before}, {"after", after},
            {"api", "org.kde.KWin.ScreenShot2.CaptureArea"}, {"options", QJsonObject{{"hide-caller-windows", false}, {"include-cursor", false}, {"native-resolution", true}}},
            {"kwinPidVerified", true}, {"verifiedWindowInfo", capture->verifiedWindowInfo},
            {"raw", QJsonObject::fromVariantMap(capture->attributes)}, {"rawBytes", capture->pipe.bytes.size()}, {"stable", stable}};
        QString error = !capture->error.isEmpty() ? capture->error : capture->pipe.error;
        const int width = capture->attributes.value("width").toInt();
        const int height = capture->attributes.value("height").toInt();
        const int stride = capture->attributes.value("stride").toInt();
        const int format = capture->attributes.value("format").toInt();
        const qint64 size = qint64(stride) * height;
        if (!stable) error = QStringLiteral("Post-capture guard failed; pixels discarded");
        if (error.isEmpty() && (width <= 0 || height <= 0 || stride < width * 4 || size != capture->pipe.bytes.size()
            || format != QImage::Format_RGBX8888)) error = QStringLiteral("Unexpected raw composite image format or size; pixels discarded");
        if (error.isEmpty()) {
            QImage image(reinterpret_cast<const uchar *>(capture->pipe.bytes.constData()), width, height, stride, QImage::Format(format));
            image.setDevicePixelRatio(capture->attributes.value("scale", 1).toDouble());
            if (!image.save(path)) error = QStringLiteral("Cannot save compositor image");
        }
        report.insert("ok", error.isEmpty()); report.insert("error", error);
        QFile sidecar(path + QStringLiteral(".runtime.json"));
        if (sidecar.open(QIODevice::WriteOnly)) sidecar.write(QJsonDocument(report).toJson());
        m_busy = false;
        respond(report);
    };
    // Reading is bounded and off the GUI thread; KWin writes pixels to the pipe
    // asynchronously after returning dimensions and QImage format metadata.
    auto *reader = new QFutureWatcher<PipeResult>(this);
    QObject::connect(reader, &QFutureWatcher<PipeResult>::finished, this, [reader, capture, finish] {
        capture->pipe = reader->result(); capture->pipeDone = true; reader->deleteLater(); finish();
    });
    reader->setFuture(QtConcurrent::run([fd = pipes[0]] {
        PipeResult result;
        char buffer[65536];
        while (result.bytes.size() <= 32 * 1024 * 1024) {
            pollfd descriptor{fd, POLLIN, 0};
            if (::poll(&descriptor, 1, 5000) <= 0) { result.error = QStringLiteral("Timed out reading capture pipe"); break; }
            const auto size = ::read(fd, buffer, sizeof(buffer));
            if (size == 0) break;
            if (size < 0) { result.error = QStringLiteral("Cannot read capture pipe"); break; }
            result.bytes.append(buffer, size);
        }
        if (result.bytes.size() > 32 * 1024 * 1024) { result.bytes.clear(); result.error = QStringLiteral("Capture exceeded byte bound"); }
        ::close(fd); return result;
    }));
    QDBusUnixFileDescriptor descriptor;
    descriptor.giveFileDescriptor(pipes[1]);
    auto message = QDBusMessage::createMethodCall(QStringLiteral("org.kde.KWin.ScreenShot2"), QStringLiteral("/org/kde/KWin/ScreenShot2"),
        QStringLiteral("org.kde.KWin.ScreenShot2"), QStringLiteral("CaptureArea"));
    const auto area = before.value("captureGlobalRect").toObject();
    message.setArguments({area.value("x").toInt(), area.value("y").toInt(), uint(area.value("width").toInt()), uint(area.value("height").toInt()),
        QVariantMap{{"include-cursor", false}, {"native-resolution", true}, {"hide-caller-windows", false}}, QVariant::fromValue(descriptor)});
    auto *watcher = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(message, 5000), this);
    QObject::connect(watcher, &QDBusPendingCallWatcher::finished, this, [watcher, capture, finish] {
        const QDBusPendingReply<QVariantMap> reply = *watcher;
        if (reply.isError()) capture->error = reply.error().name() + QStringLiteral(": ") + reply.error().message();
        else capture->attributes = reply.value();
        capture->dbusDone = true; watcher->deleteLater(); finish();
    });
}
