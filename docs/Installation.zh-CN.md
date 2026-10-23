# 安装 KMusic

[English](Installation.md) · [返回首页](../README.zh-CN.md)

## 支持范围

源码安装器识别 Arch Linux、Ubuntu、Debian，支持识别 x86_64 / aarch64。识别发行版不代表所有版本的默认依赖都满足要求；目前实际测试仅覆盖 x86_64。

[已完成的安装矩阵](https://github.com/NextKde/KMusic/actions/runs/39783294345)对应 `49264b0d45a6f8958e8d8b6eb4e5da1ee3e655d0`，在托管虚拟机内的发行版容器运行。Arch Linux、Ubuntu 26.04、Debian 13 覆盖成功安装与失败路径。Ubuntu 24.04 默认 Qt 6.4.2 低于要求，测试确认其正确拒绝安装，不代表该系统成功安装。Debian 成功测试环境预先提供 Node 22.19，默认 Node 20 不满足要求。启动测试为离屏启动，不是桌面视觉验收。

## 先准备依赖

请自行使用发行版支持的工具准备依赖。安装器不会调用包管理器，不自动安装依赖，也不使用 sudo。KMusic 不需要安装整个 NextKDE 桌面或 KWin 插件。

| Requirement | Minimum / modules |
| :--- | :--- |
| Tools | Python 3.9+, CMake 3.21+, C++20 compiler, make, Git, pkg-config |
| Node.js | 22.19+, available on the application's PATH |
| Qt | 6.8+: Core, Gui, Qml, Quick, QuickControls2, QuickDialogs2, Concurrent, DBus, Network, Sql, Svg, ShaderTools, Core5Compat |
| Libraries | Qt6Keychain, TagLib 1.12+, libqrencode, GStreamer core/audio/pbutils development libraries |
| QML | QtQuick, Effects, Controls, Dialogs, Layouts, Window, Templates, QtQml.WorkerScript, QtCore, Qt5Compat.GraphicalEffects |
| Qt plugins | SQLite, SVG, and Wayland or XCB platform support |
| GStreamer elements | playbin, autoaudiosink, audioconvert, audioresample, vorbisdec, flacdec, mpg123audiodec |

具体检查项见 [packaging/installer.py](../packaging/installer.py)。`check` 包含小型 C++20 编译器探测。缺失或版本过低会返回退出码 11，具体项目在 `details.dependencies` 中；解决后重试。通过版本管理器安装 Node 时，注意图形应用启动环境也必须能够找到 Node。

随附 provider 使用普通 JavaScript，兼容未编译 TypeScript 支持的发行版 Node。只有重新生成 provider 的开发者需要类型剥离功能，见 [provider 开发说明](../providers/README.md)。

## 安装与打开

```sh
git clone --branch codex/music-development https://github.com/NextKde/KMusic.git
cd KMusic
```

以普通用户运行，不要使用 root。`install.sh` 与 `packaging/installer.py` 必须一起提供，不支持仅下载单个 shell 文件后直接执行。

```sh
./install.sh check
./install.sh install --version 49264b0d45a6f8958e8d8b6eb4e5da1ee3e655d0
./install.sh status
```

依次执行 `check` 和 `install`。安装器拉取固定提交及其子模块并本地编译，不是下载预编译包。`status` 查看安装状态；只有需要卸载时才运行 `uninstall`。当前没有正式 release；安装其他已审查版本时，用完整 40 位 Git SHA 替换版本，不使用分支名或标签。

安装成功后从应用启动器打开 **KMusic**。安装器不会自动启动应用，也不会创建 `~/.local/bin/kmusic` 命令。

## 安装位置、更新与卸载

仅在需要卸载时执行：

```sh
./install.sh uninstall
```

- 版本目录：`${XDG_DATA_HOME:-$HOME/.local/share}/kmusic-app/versions/`；`current` 指向当前版本。
- 桌面入口和图标：用户 XDG applications / icons 目录。
- 安装器日志及锁：`${XDG_STATE_HOME:-$HOME/.local/state}/kmusic-installer`。
- 更新时先构建新版本，再切换 `current`；受控发布失败恢复之前的链接，不终止正在运行的播放器。
- 不覆盖已有非本安装器管理的桌面入口和图标。同版本安装在依赖检查后返回 `ALREADY_INSTALLED`。
- 卸载仅移除安装器管理的文件和链接；保留音乐原文件、应用数据、设置、缓存与凭据，不移除另一份手动或系统安装。

## 统一错误与 App Store 接入

标准输出为 JSONL：进度记录及正常完成或捕获错误时的最终结果。程序应解析 `success`、`code`、`stage`、`details`，不要依赖 `message` 文本。诊断写入 stderr 或日志。强制杀进程、掉电不能保证返回最终结果。

| Exit | Code |
| :--- | :--- |
| 0 | Success |
| 2 | Invalid arguments |
| 10 | Unsupported platform |
| 11 | DEPENDENCY_UNSATISFIED |
| 12 / 13 | Permission / concurrent installer |
| 20 / 21 | Download / source integrity |
| 30 / 31 / 32 | Build / installation / uninstall |
| 99 / 130 | Internal error / cancellation |

[App Store 接入契约与自动化测试](https://github.com/NextKde/NextKde/blob/codex/settings-extension-store/docs/app-store/KMusicInstallation.zh-CN.md)按要求放在主 NextKDE 仓库。商店应固定可信安装器和源码提交；SHA 一致性检查不等于发布者签名。测试环境的依赖准备脚本仅用于测试，不属于 KMusic 自动装依赖功能。

## 开发构建

开发构建与托管安装器独立，依赖要求相同：

```sh
git submodule update --init --recursive
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel 4
./build/kmusic
```

共享组件来自固定的 `vendor/nextkdeAppDemo` 子模块，来源说明见 [NOTICE.md](../NOTICE.md)。随附的 Node provider 不需要运行 npm install。
