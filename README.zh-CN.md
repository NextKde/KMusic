<p align="center"><img src="data/kmusic.svg" width="80" height="80" alt="KMusic logo"></p>

<h1 align="center">KMusic</h1>

<p align="center"><strong>原生 Qt 音乐播放器，属于 NextKDE。</strong><br>在线发现、本地音乐与自己的音乐服务器，共用一个播放器。</p>

<p align="center">
  <a href="#get-started">开始使用</a> ·
  <a href="docs/Installation.zh-CN.md">安装指南</a> ·
  <a href="README.md">English</a>
</p>

<p align="center"><code>Linux</code> &nbsp; <code>Qt 6.8+</code> &nbsp; <code>GStreamer</code></p>

开发预览版，尚未发布正式版本。功能测试与安装测试不代表视觉验收。

## 音乐与资料库

| 在线音乐 | 本地音乐 | 媒体源 |
| :--- | :--- | :--- |
| 网易云发现、搜索、详情、歌词和二维码登录。 | 扫描文件夹、读取标签与内嵌封面，管理本机歌单。 | 连接单个 Navidrome / OpenSubsonic 服务器。 |

- **播放** — 队列、进度、音量、随机与循环，以及沉浸式歌词视图。
- **个人** — 网易云账号歌单、喜欢、收藏和播放记录的只读接入；真实账号授权及权限仍需用户确认。
- **外观** — 浅色、深色、跟随系统与语言选择；覆盖滚动内容的位置使用共享 QML 液态材质。
- **边界** — B站尚未接入；不支持 Jellyfin/WebDAV、多服务器或远端歌单写入。缺少文件封面时显示占位图，不自动生成封面。网易云试听与播放权限取决于服务端。

<a id="get-started"></a>
## 开始使用

先准备[安装指南](docs/Installation.zh-CN.md)所列依赖，再以普通用户运行：

```sh
git clone --branch codex/music-development https://github.com/NextKde/KMusic.git
cd KMusic
./install.sh check
./install.sh install --version 49264b0d45a6f8958e8d8b6eb4e5da1ee3e655d0
```

上面固定到已通过安装矩阵的提交。安装器从官方仓库下载对应源码并编译；缺依赖直接返回统一 JSON 错误，**不会自动安装依赖，也不会调用 sudo**。安装成功后从应用启动器打开 KMusic。

| 发行版（x86_64） | 已运行的安装测试 |
| :--- | :--- |
| Arch Linux / Ubuntu 26.04 / Debian 13 | 成功安装、更新、卸载、失败路径及离屏启动 |
| Ubuntu 24.04 默认依赖 | 依赖不足时拒绝安装；不是成功安装认证 |

[测试运行与日志](https://github.com/NextKde/KMusic/actions/runs/39783294345) · [完整安装、卸载与故障说明](docs/Installation.zh-CN.md)

## 开发与文档

- [Local Music](docs/LocalMusic.zh-CN.md) · [Personal](docs/PersonalBackend.zh-CN.md) · [Media Sources](docs/MediaSources.zh-CN.md)
- [Design](docs/Design.zh-CN.md) · [Roadmap](docs/Roadmap.zh-CN.md) · [Source attribution](NOTICE.md)
- [App Store integration / 自动化测试](https://github.com/NextKde/NextKde/blob/codex/settings-extension-store/docs/app-store/KMusicInstallation.zh-CN.md)
- [Historical development notes](docs/DevelopmentNotes.zh-CN.md)

<!-- progress-links:start -->
[Latest progress and screenshots](https://github.com/NextKde/KMusic/blob/ui-evidence/README.md) · [Component Gallery](https://github.com/NextKde/nextkdeAppDemo/blob/ui-evidence/README.md)
<!-- progress-links:end -->
