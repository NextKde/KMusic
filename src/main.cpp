#include "MusicController.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QQuickItem>
#include <QQuickItemGrabResult>
#include <QSGRendererInterface>
#include <QFile>
#include <QDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTimer>
#include <QMouseEvent>
#include <QElapsedTimer>
#include <QJsonArray>
#include <memory>
#include <QtConcurrentRun>
#include <QFutureWatcher>
int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("kmusic"));
    app.setApplicationDisplayName(QStringLiteral("KMusic"));
    app.setOrganizationName(QStringLiteral("NextKde"));
    app.setApplicationVersion(QStringLiteral(MUSIC_VERSION));
    app.setDesktopFileName(QStringLiteral("kmusic"));
    QQuickStyle::setStyle(QStringLiteral("Basic"));
    QQuickWindow::setDefaultAlphaBuffer(true);
    MusicController music;
    QQmlApplicationEngine engine;
    engine.setInitialProperties({{QStringLiteral("music"), QVariant::fromValue(&music)}});
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.loadFromModule(QStringLiteral("NextKde.Music"), QStringLiteral("Main"));
    const auto files = app.arguments().mid(1);
    if (!files.isEmpty()) QObject::connect(&music, &MusicController::readyChanged, &music, [&music, files] {
        if (music.ready()) music.openUri(files.first());
    }, Qt::SingleShotConnection);
    // Explicitly opt-in review hook: captures the live window's content, with
    // its actual GPU render and DPR. No offscreen or replacement shell.
    const QString reviewDir = qEnvironmentVariable("KMUSIC_REVIEW_DIR");
    QTimer reviewTimer;
    if (!reviewDir.isEmpty()) {
        QDir().mkpath(reviewDir);
        QObject::connect(&reviewTimer, &QTimer::timeout, &engine, [&engine, &music, &app, reviewDir] {
            QFile request(QDir(reviewDir).filePath("request.json"));
            if (!request.open(QIODevice::ReadOnly)) return;
            const auto data = QJsonDocument::fromJson(request.readAll()).object();
            request.close(); request.remove();
            if (engine.rootObjects().isEmpty()) return;
            auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
            if (!window) return;
            const QString action = data.value("action").toString();
            if (action == "capture") {
                const QString path = data.value("path").toString();
                auto result = window->contentItem()->grabToImage();
                window->update();
                if (result) QObject::connect(result.data(), &QQuickItemGrabResult::ready, window, [result, path, reviewDir] {
                    const bool ok = result->saveToFile(path);
                    QFile response(QDir(reviewDir).filePath("response.json"));
                    if (response.open(QIODevice::WriteOnly)) response.write(QJsonDocument(QJsonObject{{"ok", ok}, {"path", path}}).toJson());
                });
            } else if (action == "homePointer") {
                // Dedicated-window review only: actual Qt Quick pointer dispatch,
                // restricted to named product controls; never moves the system cursor.
                const QString control = data.value("control").toString();
                const QString state = data.value("state").toString();
                if ((control != "hero" && control != "player" && control != "discoveryFirst") ||
                    (state != "hover" && state != "press" && state != "cancel" && state != "click")) return;
                auto *item = window->findChild<QQuickItem *>(control == "hero" ? "reviewHeroPlay" : control == "player" ? "reviewPlayerPlay" : "reviewDiscoveryFirst");
                if (!item || !item->isVisible() || !item->isEnabled()) return;
                QPointF position = item->mapToScene(QPointF(item->width() / 2, item->height() / 2));
                if (state == "cancel") position = QPointF(window->width() - 120, 40);
                const auto send = [window, position](QEvent::Type type, Qt::MouseButton button, Qt::MouseButtons buttons) {
                    QMouseEvent event(type, position, window->mapToGlobal(position.toPoint()), button, buttons, Qt::NoModifier);
                    QCoreApplication::sendEvent(window, &event);
                };
                send(QEvent::MouseMove, Qt::NoButton, state == "cancel" ? Qt::LeftButton : Qt::NoButton);
                if (state == "press" || state == "click") send(QEvent::MouseButtonPress, Qt::LeftButton, Qt::LeftButton);
                if (state == "click") send(QEvent::MouseButtonRelease, Qt::LeftButton, Qt::NoButton);
                if (state == "cancel") send(QEvent::MouseButtonRelease, Qt::LeftButton, Qt::NoButton);
                QFile response(QDir(reviewDir).filePath("response.json"));
                if (response.open(QIODevice::WriteOnly)) response.write(QJsonDocument(QJsonObject{
                    {"ok", true}, {"control", control}, {"state", state},
                    {"hovered", item->property("hovered").toBool()}, {"down", item->property("down").toBool()},
                    {"scale", item->scale()}, {"windowLocalX", position.x()}, {"windowLocalY", position.y()}
                }).toJson());
            } else if (action == "onlineSearch") {
                QMetaObject::invokeMethod(window, "reviewOnlineSearch", Q_ARG(QVariant, data.value("query").toString()));
            } else if (action == "playDiscovery") music.playDiscoveryAlbum(data.value("row").toInt());
            else if (action == "reloadDiscovery") music.reloadDiscovery();
            else if (action == "playOnline") music.playOnlineRow(data.value("row").toInt());
            else if (action == "selectMenu") QMetaObject::invokeMethod(window, "openReviewSelect", Q_ARG(QVariant, data.value("name").toString()));
            else if (action == "materialSequence") {
                const QString control = data.value("control").toString();
                const QString directory = data.value("directory").toString();
                if ((control != "switch" && control != "segment" && control != "hero") || !QDir::isAbsolutePath(directory)) return;
                QDir().mkpath(directory);
                const int index = data.value("index").toInt(1);
                auto elapsed = std::make_shared<QElapsedTimer>(); elapsed->start();
                auto frames = std::make_shared<QJsonArray>();
                auto stateAction = [window, index, control](const QString &state) {
                    if (control != "hero") {
                        QMetaObject::invokeMethod(window, "reviewMaterialAction", Q_ARG(QVariant, state), Q_ARG(QVariant, index));
                        return;
                    }
                    auto *item = window->findChild<QQuickItem *>("reviewHeroPlay");
                    if (!item || !item->isVisible() || !item->isEnabled()) return;
                    const bool release = state.endsWith("Release");
                    const QPointF position = release ? QPointF(window->width() - 120, 40)
                        : item->mapToScene(QPointF(item->width() / 2, item->height() / 2));
                    QMouseEvent move(QEvent::MouseMove, position, window->mapToGlobal(position.toPoint()),
                        Qt::NoButton, release ? Qt::LeftButton : Qt::NoButton, Qt::NoModifier);
                    QCoreApplication::sendEvent(window, &move);
                    QMouseEvent event(release ? QEvent::MouseButtonRelease : QEvent::MouseButtonPress,
                        position, window->mapToGlobal(position.toPoint()), Qt::LeftButton,
                        release ? Qt::NoButton : Qt::LeftButton, Qt::NoModifier);
                    QCoreApplication::sendEvent(window, &event);
                };
                stateAction(control + "Press");
                QTimer::singleShot(200, window, [stateAction, control] { stateAction(control + "Release"); });
                const QList<int> delays{0, 40, 100, 160, 240, 300, 380, 500};
                for (const int delay : delays) QTimer::singleShot(delay, window, [window, directory, control, delay, elapsed, frames] {
                    QVariant state;
                    QMetaObject::invokeMethod(window, "materialReviewState", Q_RETURN_ARG(QVariant, state));
                    const qint64 requestedAt = elapsed->elapsed();
                    auto result = window->contentItem()->grabToImage();
                    window->update();
                    if (!result) return;
                    const QString path = QDir(directory).filePath(control + QStringLiteral("-%1.png").arg(delay, 3, 10, QLatin1Char('0')));
                    QObject::connect(result.data(), &QQuickItemGrabResult::ready, window, [result, window, path, directory, control, delay, requestedAt, elapsed, state, frames] {
                        const qint64 readyAt = elapsed->elapsed();
                        // PNG compression must not stall the animation/event loop.
                        const QImage image = result->image();
                        auto *writer = new QFutureWatcher<bool>(window);
                        QObject::connect(writer, &QFutureWatcher<bool>::finished, window, [writer, path, directory, control, delay, requestedAt, readyAt, state, frames] {
                            frames->append(QJsonObject{{"scheduledMs", delay}, {"requestedAtMs", requestedAt}, {"grabReadyAtMs", readyAt}, {"saved", writer->result()}, {"path", path},
                                {"stateAtRequest", QJsonDocument::fromJson(state.toString().toUtf8()).object()}});
                            QFile metadata(QDir(directory).filePath("frames.json"));
                            if (metadata.open(QIODevice::WriteOnly)) metadata.write(QJsonDocument(QJsonObject{
                                {"trigger", control == "hero" ? "actual QtQuick QMouseEvent delivery; release outside button; no system pointer movement" : "shared control state entry; no synthetic pointer or keyboard events"},
                                {"pressAtMs", 0}, {"releaseScheduledMs", 200}, {"frames", *frames}}).toJson());
                            writer->deleteLater();
                        });
                        writer->setFuture(QtConcurrent::run([image, path] { return image.save(path); }));
                    });
                });
            }
            else if (action == "materialReview") {
                QMetaObject::invokeMethod(window, "reviewMaterialAction",
                    Q_ARG(QVariant, data.value("state").toString()), Q_ARG(QVariant, data.value("index").toInt()));
            }
            else if (action == "activate") window->requestActivate();
            else if (action == "retryLyrics") music.reloadLyrics();
            else if (action == "pause") music.pause();
            else if (action == "play") music.play();
            else if (action == "seek") music.seek(data.value("positionMs").toVariant().toLongLong());
            else if (action == "quit") app.quit();
            else if (action == "status") {
                const auto api = window->rendererInterface()->graphicsApi();
                const QString renderer = api == QSGRendererInterface::OpenGL ? "OpenGL" : api == QSGRendererInterface::Vulkan ? "Vulkan" : api == QSGRendererInterface::Software ? "Software" : api == QSGRendererInterface::Metal ? "Metal" : "other";
                QVariant materialState;
                QMetaObject::invokeMethod(window, "materialReviewState", Q_RETURN_ARG(QVariant, materialState));
                QFile response(QDir(reviewDir).filePath("response.json"));
                if (response.open(QIODevice::WriteOnly)) response.write(QJsonDocument(QJsonObject{
                    {"ok", true}, {"renderer", renderer},
                    {"materialReview", QJsonDocument::fromJson(materialState.toString().toUtf8()).object()},
                    {"page", window->property("destination").toString()}, {"windowVisible", window->isVisible()},
                    {"windowVisibility", static_cast<int>(window->visibility())},
                    {"windowActive", window->isActive()}, {"windowX", window->x()}, {"windowY", window->y()},
                    {"fakeAudio", qEnvironmentVariableIsSet("KOS_MUSIC_FAKE_AUDIO")}, {"playbackState", music.playbackState()}, {"positionMs", music.positionMs()},
                    {"durationMs", music.durationMs()}, {"providerStatus", music.providerStatus()},
                    {"lyricsEnabled", music.lyricsEnabled()}, {"lyricsLoading", music.lyricsLoading()}, {"lyricsCount", music.lyrics().size()},
                    {"lyricsError", music.lyricsError()}, {"lyricRequestCount", music.lyricRequestCount()},
                    {"playbackSession", QJsonObject::fromVariantMap(music.playbackSessionInfo())},
                    {"discoveryCount", music.discoveryAlbums().size()}, {"discoveryLoading", music.discoveryLoading()},
                    {"discoveryError", music.discoveryError()}, {"discoveryPlaying", music.discoveryPlaying()},
                    {"onlineCount", music.onlineModel()->count()}, {"onlineSearching", music.onlineSearching()},
                    {"onlineError", music.onlineError()}, {"error", music.errorMessage()},
                    {"windowWidth", window->width()}, {"windowHeight", window->height()}, {"dpr", window->devicePixelRatio()}
                }).toJson());
            } else if (action == "theme") {
                QMetaObject::invokeMethod(window, "setReviewTheme", Q_ARG(QVariant, data.value("theme").toString()));
            } else if (action == "page") window->setProperty("destination", data.value("page").toString());
            else if (action == "resize") { window->setWidth(data.value("width").toInt(1280)); window->setHeight(data.value("height").toInt(800)); }
        });
        reviewTimer.start(200);
    }
    return app.exec();
}
