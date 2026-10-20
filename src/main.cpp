#include "MusicController.h"
#include "WindowMaterial.h"
#include "NativeReview.h"
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
    WindowMaterial material;
    QQmlApplicationEngine engine;
    engine.setInitialProperties({{QStringLiteral("music"), QVariant::fromValue(&music)}, {QStringLiteral("windowMaterial"), QVariant::fromValue(&material)}});
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.loadFromModule(QStringLiteral("NextKde.Music"), QStringLiteral("Main"));
    if (!engine.rootObjects().isEmpty()) material.setWindow(qobject_cast<QQuickWindow *>(engine.rootObjects().first()));
    const auto files = app.arguments().mid(1);
    if (!files.isEmpty()) QObject::connect(&music, &MusicController::readyChanged, &music, [&music, files] {
        if (music.ready()) music.openUri(files.first());
    }, Qt::SingleShotConnection);
    // Explicitly opt-in review hook: captures the live window's content, with
    // its actual GPU render and DPR. No offscreen or replacement shell.
    const QString reviewDir = qEnvironmentVariable("KMUSIC_REVIEW_DIR");
    NativeReview nativeReview(&engine, &material, reviewDir);
    if (!engine.rootObjects().isEmpty()) nativeReview.setWindow(qobject_cast<QQuickWindow *>(engine.rootObjects().first()));
    QTimer reviewTimer;
    if (!reviewDir.isEmpty()) {
        QDir().mkpath(reviewDir);
        QObject::connect(&reviewTimer, &QTimer::timeout, &engine, [&engine, &music, &material, &nativeReview, &app, reviewDir] {
            QFile request(QDir(reviewDir).filePath("request.json"));
            if (!request.open(QIODevice::ReadOnly)) return;
            const auto data = QJsonDocument::fromJson(request.readAll()).object();
            request.close(); request.remove();
            if (engine.rootObjects().isEmpty()) return;
            auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
            if (!window) return;
            const QString action = data.value("action").toString();
            if (action == "nativeBackground") { if (data.value("visible").toBool()) nativeReview.showBackground(); else nativeReview.hideBackground(); }
            else if (action == "nativeBlur") nativeReview.setBlurEnabled(data.value("enabled").toBool());
            else if (action == "nativeSidebar") nativeReview.captureSidebar(data.value("path").toString());
            else if (action == "capture") {
                const QString path = data.value("path").toString();
                auto result = window->contentItem()->grabToImage();
                if (result) QObject::connect(result.data(), &QQuickItemGrabResult::ready, window, [result, path, reviewDir] {
                    const bool ok = result->saveToFile(path);
                    QFile response(QDir(reviewDir).filePath("response.json"));
                    if (response.open(QIODevice::WriteOnly)) response.write(QJsonDocument(QJsonObject{{"ok", ok}, {"path", path}}).toJson());
                });
            } else if (action == "onlineSearch") {
                QMetaObject::invokeMethod(window, "reviewOnlineSearch", Q_ARG(QVariant, data.value("query").toString()));
            } else if (action == "playOnline") music.playOnlineRow(data.value("row").toInt());
            else if (action == "selectMenu") QMetaObject::invokeMethod(window, "openReviewSelect", Q_ARG(QVariant, data.value("name").toString()));
            else if (action == "materialSequence") {
                const QString control = data.value("control").toString();
                const QString directory = data.value("directory").toString();
                if ((control != "switch" && control != "segment") || !QDir::isAbsolutePath(directory)) return;
                QDir().mkpath(directory);
                const int index = data.value("index").toInt(1);
                auto elapsed = std::make_shared<QElapsedTimer>(); elapsed->start();
                auto frames = std::make_shared<QJsonArray>();
                auto stateAction = [window, index](const QString &state) {
                    QMetaObject::invokeMethod(window, "reviewMaterialAction", Q_ARG(QVariant, state), Q_ARG(QVariant, index));
                };
                stateAction(control + "Press");
                QTimer::singleShot(200, window, [stateAction, control] { stateAction(control + "Release"); });
                const QList<int> delays{0, 40, 100, 160, 240, 300, 380, 500};
                for (const int delay : delays) QTimer::singleShot(delay, window, [window, directory, control, delay, elapsed, frames] {
                    QVariant state;
                    QMetaObject::invokeMethod(window, "materialReviewState", Q_RETURN_ARG(QVariant, state));
                    const qint64 requestedAt = elapsed->elapsed();
                    auto result = window->contentItem()->grabToImage();
                    if (!result) return;
                    const QString path = QDir(directory).filePath(control + QStringLiteral("-%1.png").arg(delay, 3, 10, QLatin1Char('0')));
                    QObject::connect(result.data(), &QQuickItemGrabResult::ready, window, [result, window, path, directory, delay, requestedAt, state, frames] {
                        // PNG compression must not stall the animation/event loop.
                        const QImage image = result->image();
                        auto *writer = new QFutureWatcher<bool>(window);
                        QObject::connect(writer, &QFutureWatcher<bool>::finished, window, [writer, path, directory, delay, requestedAt, state, frames] {
                            frames->append(QJsonObject{{"scheduledMs", delay}, {"requestedAtMs", requestedAt}, {"saved", writer->result()}, {"path", path},
                                {"stateAtRequest", QJsonDocument::fromJson(state.toString().toUtf8()).object()}});
                            QFile metadata(QDir(directory).filePath("frames.json"));
                            if (metadata.open(QIODevice::WriteOnly)) metadata.write(QJsonDocument(QJsonObject{
                                {"trigger", "shared control state entry; no synthetic pointer or keyboard events"},
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
                    {"ok", true}, {"renderer", renderer}, {"nativeReview", nativeReview.status()},
                    {"materialReview", QJsonDocument::fromJson(materialState.toString().toUtf8()).object()},
                    {"windowActive", window->isActive()}, {"windowX", window->x()}, {"windowY", window->y()},
                    {"blurAvailable", material.effectAvailable()}, {"effectAvailable", material.effectAvailable()},
                    {"blurRequested", material.blurRequested()}, {"blurFallback", material.fallback()},
                    {"blurRegion", QJsonObject{{"x", material.region().x()}, {"y", material.region().y()}, {"width", material.region().width()}, {"height", material.region().height()}}}, {"fakeAudio", qEnvironmentVariableIsSet("KOS_MUSIC_FAKE_AUDIO")}, {"playbackState", music.playbackState()}, {"positionMs", music.positionMs()},
                    {"durationMs", music.durationMs()}, {"providerStatus", music.providerStatus()},
                    {"lyricsEnabled", music.lyricsEnabled()}, {"lyricsLoading", music.lyricsLoading()}, {"lyricsCount", music.lyrics().size()},
                    {"lyricsError", music.lyricsError()}, {"lyricRequestCount", music.lyricRequestCount()},
                    {"playbackSession", QJsonObject::fromVariantMap(music.playbackSessionInfo())},
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
