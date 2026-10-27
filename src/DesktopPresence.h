#pragma once

#include <QObject>

// macOS 桌面常驻：菜单栏状态项（NSStatusItem）+ Dock 图标右键菜单。
// 两处菜单只负责发出请求；「打开主窗口」「跳到设置页」这类导航语义
// 由 main.cpp 连接到 QML 主窗口，播放指令连到 MusicController，
// 这样 KMusic 在 Linux 上仍可按原语义构建（本类只在 Apple 平台编译）。
class DesktopPresence : public QObject {
    Q_OBJECT

public:
    explicit DesktopPresence(QObject *parent = nullptr);
    ~DesktopPresence() override;

    // 创建菜单栏状态项。必须在 app 完成启动之后调用（见实现里的注释），
    // main.cpp 用 QTimer::singleShot(0) 在事件循环首轮触发。可重复调用。
    void installStatusItem();

    // 播放状态变化时同步「播放/暂停」标题与「上一首 / 下一首」的可用态
    void setPlaybackActions(bool playing, bool canPrevious, bool canNext);

signals:
    void openRequested();
    void settingsRequested();
    void playPauseRequested();
    void previousRequested();
    void nextRequested();
    void quitRequested();
};
