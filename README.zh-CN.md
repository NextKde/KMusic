<p align="center"><img src="data/kmusic.svg" width="80" height="80" alt="KMusic logo"></p>

<h1 align="center">KMusic</h1>

<p align="center"><strong>原生 Qt 音乐播放器，属于 NextKDE。</strong><br>在线发现、本地音乐与自己的音乐服务器，共用一个播放器。</p>

<p align="center">
  <a href="#get-started">开始使用</a> ·
  <a href="docs/Installation.zh-CN.md">安装指南</a> ·
  <a href="#免责声明">免责声明</a> ·
  <a href="README.en.md">English</a>
</p>

<p align="center"><code>Linux</code> &nbsp; <code>Qt 6.8+</code> &nbsp; <code>GStreamer</code></p>

![KMusic 发现页：歌单精选、新歌速递与悬浮播放器](docs/images/kmusic-ipad.png)

设备外壳展示图 · KMusic 是 Linux 应用 · [原始截图](docs/images/kmusic-discover.png)

开发预览版，尚未发布正式版本。功能测试与安装测试不代表视觉验收。

## 音乐与资料库

| 在线音乐 | 本地音乐 | 媒体源 |
| :--- | :--- | :--- |
| 网易云发现、搜索、详情、歌词和二维码登录。 | 扫描文件夹、读取标签与内嵌封面，管理本机歌单。 | 连接单个 Navidrome / OpenSubsonic 服务器。 |

- **播放** — 队列、进度、音量、随机与循环，以及沉浸式歌词视图。
- **个人** — 网易云账号歌单、喜欢、收藏和播放记录的只读接入；真实账号授权及权限仍需用户确认。
- **外观** — 浅色、深色、跟随系统与语言选择；覆盖滚动内容的位置使用共享 QML 液态材质。
- **边界** — B站尚未接入；不支持 Jellyfin/WebDAV、多服务器或远端歌单写入。缺少文件封面时显示占位图，不自动生成封面。网易云试听与播放权限取决于服务端。

## 免责声明

KMusic 是独立的开源音乐客户端，在线功能通过第三方服务接口获取数据，与网易云音乐等平台不存在官方隶属、合作或背书关系。

- **版权归属**：音乐、录音、歌词、封面及相关资料的权利属于各自权利人。本项目的开源许可适用于软件本身，不代表取得音乐内容或第三方 API 的使用授权。
- **合规使用**：请仅使用你有权访问的内容、账号和媒体源，并遵守适用法律及平台服务条款。不得利用本软件绕过付费或访问限制、未经授权复制传播内容，或滥用第三方接口。
- **服务限制**：第三方接口可能变更、限流或停止服务。可播放范围、试听时长、音质及账号功能以平台实际权限和响应为准；本项目不承诺免费获取付费内容或提供持续可用的服务。
- **账号与隐私**：登录及授权由用户自行决定，请妥善保管账号和凭据，不要在公开反馈中提交 Cookie、令牌、二维码或其他敏感信息。
- **使用风险**：在适用法律允许的范围内，软件按“现状”提供，不对第三方服务的稳定性、准确性或持续可用性作保证；依法不能排除的责任不受本声明限制。

如发现版权、接口使用或其他权利问题，请通过 [Issues](https://github.com/NextKde/KMusic/issues) 提供相关说明和链接，项目维护者将核实处理。请支持正版音乐及原平台服务。

<a id="get-started"></a>
## 开始使用

先准备[安装指南](docs/Installation.zh-CN.md)所列依赖，再以普通用户运行：

```sh
git clone --recurse-submodules --branch main https://github.com/NextKde/KMusic.git
cd KMusic
./install.sh check
./install.sh install --source-dir .
```

上面直接安装已克隆的本地源码，不再次下载。源码和固定版本子模块需完整且无已跟踪修改；缺依赖直接返回统一 JSON 错误，**不会自动安装依赖，也不会调用 sudo**。安装成功后从应用启动器打开 KMusic。

本地模式同样支持 `./install.sh status` 和 `./install.sh uninstall`，卸载保留用户数据。远程固定 SHA 安装仍支持 `install --version <SHA>`。

下表是此前远程安装路径的测试记录，本地模式测试范围见[安装指南](docs/Installation.zh-CN.md)。

| 发行版（x86_64） | 已运行的安装测试 |
| :--- | :--- |
| Arch Linux / Ubuntu 26.04 / Debian 13 | 成功安装、更新、卸载、失败路径及离屏启动 |
| Ubuntu 24.04 默认依赖 | 依赖不足时拒绝安装；不是成功安装认证 |

[测试运行与日志](https://github.com/NextKde/KMusic/actions/runs/39783294345) · [完整安装、卸载与故障说明](docs/Installation.zh-CN.md)

## 开发与文档

- [本地音乐](docs/LocalMusic.zh-CN.md) · [个人资料库](docs/PersonalBackend.zh-CN.md) · [媒体源](docs/MediaSources.zh-CN.md)
- [设计说明](docs/Design.zh-CN.md) · [路线图](docs/Roadmap.zh-CN.md) · [来源与许可](NOTICE.md)
- [应用商店接入与自动化测试](https://github.com/NextKde/NextKde/blob/codex/settings-extension-store/docs/app-store/KMusicInstallation.zh-CN.md)
- [历史开发记录](docs/DevelopmentNotes.zh-CN.md)

<!-- progress-links:start -->
[界面预览](docs/images/kmusic-ipad.png) · [组件示例库](https://github.com/NextKde/nextkdeAppDemo/blob/ui-evidence/README.md)
<!-- progress-links:end -->
