#pragma once

#include <QHash>
#include <QImage>
#include <QObject>
#include <QSet>
#include <QTimer>
#include <QVariantMap>

class MusicController;
class QNetworkAccessManager;

// macOS 版「MPRIS」：用 MediaPlayer 框架的 MPNowPlayingInfoCenter（上报状态/元数据）
// 与 MPRemoteCommandCenter（接收媒体键指令）替代 Linux 的 D-Bus MPRIS。
// 公共接口与原实现一致，MusicController 无需改动。
class MprisService : public QObject {
    Q_OBJECT

public:
    explicit MprisService(MusicController *controller, QObject *parent = nullptr);
    ~MprisService() override;

    bool registered() const;

private:
    void updateNowPlaying();
    void updateCommandAvailability();
    void requestArtwork(const QString &url);
    QString artworkFilePath() const;

    MusicController *m_controller = nullptr;
    void *m_targets = nullptr; // NSMutableArray<id>，保存命令注册句柄用于注销
    QNetworkAccessManager *m_nam = nullptr;
    QHash<QString, QImage> m_artworkCache;
    QSet<QString> m_pendingArtwork;
    QTimer m_progressTimer;
    bool m_registered = false;
};
