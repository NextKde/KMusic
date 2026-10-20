#include "NativeReview.h"
#include "WindowMaterial.h"
#include <QCoreApplication>
#include <QDateTime>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
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
#include <fcntl.h>
#include <poll.h>
#include <unistd.h>
#include <memory>

namespace {
QJsonObject rectJson(QRect rect) { return {{"x", rect.x()}, {"y", rect.y()}, {"width", rect.width()}, {"height", rect.height()}}; }
QString now() { return QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs); }
struct PipeResult { QByteArray bytes; QString error; };
struct Capture {
    QJsonObject before;
    QJsonObject runtime;
    QVariantMap attributes;
    PipeResult pipe;
    QString error;
    bool dbusDone = false;
    bool pipeDone = false;
};
}
NativeReview::NativeReview(QQmlEngine *engine, WindowMaterial *material, QString reviewDir, QObject *parent)
    : QObject(parent), m_engine(engine), m_material(material), m_reviewDir(std::move(reviewDir)) {}
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
    m_background->showFullScreen();
    m_window->setTransientParent(m_background);
    m_window->requestActivate();
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
    const QRect geometry = m_window ? m_window->geometry() : QRect{};
    const QRect global = region.translated(geometry.topLeft());
    const bool backgroundVisible = m_background && m_background->isVisible() && m_background->isExposed();
    const bool sameScreen = m_window && m_background && m_background->screen() == m_window->screen();
    const bool covers = backgroundVisible && m_background->geometry().contains(global);
    const bool transient = m_window && m_background && m_window->transientParent() == m_background;
    const bool inside = m_window && QRect(QPoint{}, m_window->size()).contains(region) && region.width() > 0 && region.height() > 0;
    const bool active = m_window && m_window->isActive();
    return {{"timestamp", now()}, {"pid", QCoreApplication::applicationPid()}, {"busy", m_busy},
        {"windowActive", active}, {"windowGeometry", rectJson(geometry)}, {"sidebarLocalRect", rectJson(region)},
        {"captureGlobalRect", rectJson(global)}, {"dpr", m_window ? m_window->devicePixelRatio() : 0},
        {"backgroundVisible", backgroundVisible}, {"backgroundGeometry", rectJson(m_background ? m_background->geometry() : QRect{})},
        {"sameScreen", sameScreen}, {"backgroundCoversCapture", covers}, {"transientParentMatches", transient},
        {"blurEnabled", m_blurEnabled}, {"effectAvailable", m_material->effectAvailable()}, {"blurRequested", m_material->blurRequested()},
        {"eligible", active && inside && covers && sameScreen && transient && !m_reviewDir.isEmpty()}};
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
    int pipes[2];
    if (::pipe2(pipes, O_CLOEXEC) != 0) { respond({{"ok", false}, {"error", "Cannot create capture pipe"}}); return; }
    m_busy = true;
    const auto capture = std::make_shared<Capture>(); capture->before = before; capture->runtime = runtime;
    const auto finish = [this, capture, path] {
        if (!capture->dbusDone || !capture->pipeDone) return;
        const auto after = status();
        const bool stable = after.value("eligible").toBool()
            && after.value("windowGeometry") == capture->before.value("windowGeometry")
            && after.value("captureGlobalRect") == capture->before.value("captureGlobalRect")
            && after.value("backgroundGeometry") == capture->before.value("backgroundGeometry")
            && after.value("blurRequested") == capture->before.value("blurRequested");
        QJsonObject report{{"ok", false}, {"path", path}, {"appRuntime", capture->runtime}, {"before", capture->before}, {"after", after},
            {"api", "org.kde.KWin.ScreenShot2.CaptureArea"}, {"options", QJsonObject{{"hide-caller-windows", false}, {"include-cursor", false}, {"native-resolution", true}}},
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
