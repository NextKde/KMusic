# Bilibili 搜索与播放

通过顶部的切换平台按钮选择 **Bilibili**。在输入框中搜索视频，或输入 BV 号、官方视频链接。
结果可以直接播放；“分 P”打开视频分集列表。搜索记录按来源保存，不与网易云混用。

当前提供游客视频搜索、分页、详情、分 P、普通 AAC 音频播放及现有播放器的暂停、进度跳转。
播放条、队列与本机播放记录复用 KMusic。视频 UP 主显示为创作者，封面来自视频缩略图。
暂未接入 B站账号、收藏夹、平台历史、推荐及歌词，也不请求 Dolby/FLAC 等高级音轨。
服务要求登录、验证或内容不可用时会明确报错；不会绕过访问权限。

## 实现边界

- `WbiSigner`：纯签名逻辑，无网络。
- `BilibiliApi` / `HttpTransport`：请求编排与传输，错误不携带原始响应或签名 URL。
- `BilibiliSearch`：搜索与分页模型。
- `BilibiliDetail`：BV/cid、分 P 和元数据。
- `BilibiliPlaybackResolver`：播放时解析临时 AAC 地址。
- `BilibiliController`：页面状态、查询生命周期；`MusicControllerBilibili` 连接本机队列。
- `PlaybackHttpHeaders`：GStreamer 每次加载的不可变 UA/Referer，后续加载清除；不传账号 Cookie。

本机记录只保存 `bilibili:BV[:cid]` 等稳定身份，不保存临时播放地址。接口实现独立编写，没有复制、翻译或移植 Biu 源码。

## 验证

测试仅在用户指定虚拟机 **172.20.23.3** 执行：

```sh
cmake -S tests/providers -B build-provider-contracts -G Ninja -DKMUSIC_TEST_PLAYBACK_HEADERS=ON
cmake --build build-provider-contracts --parallel 2
ctest --test-dir build-provider-contracts --output-on-failure
# 可选：实际访问 Bilibili 的游客搜索和播放解析，不输出签名 URL
./build-provider-contracts/bilibili_flow_tests --live
```

三组测试覆盖网络取消/响应上限、WBI 固定向量、搜索分页与身份、错误处理、AAC 选择，
以及 GStreamer HTTP 音频解码、暂停和跨来源 Header 隔离。
原生 UI 测试另验证真实搜索、播放进度、暂停与 15 秒位置跳转。线上接口结果可能随平台变化。

AAC 播放需要可用的 GStreamer AAC 解码插件，例如 Debian/Ubuntu 的 `gstreamer1.0-libav`。
测试虚拟机缺少该插件时，在专用测试目录解包并通过 `GST_PLUGIN_PATH` 加载；没有修改系统包或 Shell/KWin。
这不改变安装脚本“缺依赖直接报错、不自动安装”的约定。

[完整模块契约](ProviderContracts.zh-CN.md)

本次虚拟机预览使用 XWayland、软件 OpenGL，并设置 `QSG_NO_VSYNC=1`、
`QML_DISABLE_DISK_CACHE=1`、`QV4_FORCE_INTERPRETER=1` 才获得正常刷新的界面与截图。
默认渲染配置出现过旧画面不刷新的现象，尚未把原因归结为单一设置；这些选项仅用于测试进程。
实际验证了一首约两分钟的视频音频；另一个长视频请求曾超时，不能据此宣称所有视频均可播放。
