# 音源模块与接口契约

状态：第一批基础代码已实现；Bilibili 尚未接入 UI，不代表搜索、播放或登录已经可用。

## 模块边界

| 模块 | 职责 | 禁止承担的职责 |
| --- | --- | --- |
| `providers/contracts/` | 来源身份、分页、错误及各能力接口 | 网络实现、QML 状态、凭据存储 |
| `HttpTransport` | 异步 HTTP、大小限制、错误映射 | 视频 JSON、WBI 签名、登录业务 |
| `bilibili/BilibiliDetail` | 视频详情与分 P 的解码 | 搜索、播放地址、登录、个人资料库 |
| 后续 `BilibiliSearch` | 搜索请求与结果映射 | 播放、收藏、登录 |
| 后续 `BilibiliPlaybackResolver` | 按 BV/cid 解析临时音频地址 | 操作播放器或保存临时 URL |
| 后续 `BilibiliAccount` | 扫码状态、会话恢复与退出 | 操作首页列表、把 Cookie 暴露给 QML |
| 后续 `BilibiliLibrary` | 收藏夹、历史、歌单及分页 | 复用其他平台或其他账号的数据 |
| 后续 UI facade | 把能力结果转换为页面状态 | 端点、签名、Cookie、原始 JSON |
| `PlaybackEngine` | 播放解析后的媒体描述 | 调用平台 API、识别 BV、负责登录 |

每种能力一个小接口；不要求所有来源实现全部能力，也不引入一个包含所有端点的基类。
不把 Bilibili 请求追加到 `MusicController.cpp` 或网易云 Node helper。
现有网易云实现先保持兼容，后续用适配器逐项对接，避免同时重写两个平台。
端点增加时应写入对应的业务模块；共用签名器、会话存储也应各自独立。

## 身份与数据

- `SourceScope` = provider + instance + account。搜索、缓存、个人列表均必须带来源范围。
- `MediaId` = 来源范围 + item + part。Bilibili 使用 BV + cid；不能与网易云数值 ID 混用。
- 详情的 UP 主映射为 creator，不捏造专辑或专业艺人资料。分 P 保留独立 cid。
- `Page<T>` 使用不透明游标；调用方不能自行猜测平台页号。
- 收藏歌曲和收藏夹不是同一种数据，`LibraryEntry` 显式区分媒体与集合。
- `PlaybackSource` 是临时的原生侧数据，包含 URL、备用 URL、质量、UA、Referer、可选过期时间。
  不持久化、不暴露给 QML；没有过期时间不代表永久有效。后续播放器只接收这个描述。
- 播放描述不允许任意凭据 Header；API Cookie 不能自动带往 CDN。接入播放时需单独实现并测试 Header 隔离。

## 异步与错误

- 传入非空 `QObject *context`，所有操作均在该对象线程调用；回调也在同一线程执行。
- 返回 `Request*` 由 context 持有；需要跨事件循环保存时使用 `QPointer<Request>`。
- `cancel()` 至多回调一次 `Cancelled`；context 销毁则取消且不回调。
  已完成请求再次取消没有副作用。调用方可主动销毁已完成句柄释放资源。
- Provider 必须覆盖在途请求的生命周期；切换来源/账号时 facade 销毁对应请求 context，清空旧页面状态。
  后续有状态模块还须检查 session generation，拒绝旧会话结果。
- `Result<T>` 只能是业务结果或结构化错误，不把 HTTP 200 当作业务成功。
- 错误类别统一为参数错误、取消、网络、超时、限流、需登录、需官方验证、不可用、响应异常。
  `retryable` 只是信息，不意味着无限自动重试；验证要求交给用户处理。
- 回调不能把原始响应、带签名 URL、Cookie、扫码轮询 key 写到错误文字/日志。

## 第一批实现与验证范围

实现 `BilibiliDetail`，独立读取 `/x/web-interface/view`，检查 BV 与分 P 身份、业务错误和必要字段。
原生 Qt Network 传输使用单独 manager/cookie jar、15 秒传输超时、4 MiB 响应上限，拒绝自动重定向。
没有引入 Electron、额外 HTTP 服务或新的运行时。没有复制、翻译或移植 Biu 源码。

`tests/providers/` 为独立原生测试：构造详情数据、本地 HTTP 服务响应、取消与 context 销毁、
HTTP 限流/验证错误、重定向拒绝、响应上限。只能在虚拟机运行，不依赖真实账号或真实 Bilibili 服务。
这批测试不能证明线上接口当前可用，更不代表 UI 或声音已经验收。

下一批应独立实现播放解析和签名模块，再给 GStreamer 增加按次加载的 UA/Referer；
搜索、账号和个人资料库分别接入。每批补对应契约测试，不先创建空的业务实现冒充已支持。

协议研究参考：[Bilibili 音乐项目架构说明](https://github.com/YOUYUDAWANG/bili-music/blob/main/ARCHITECTURE.md)、
[Qt Network](https://doc.qt.io/qt-6/qnetworkaccessmanager.html)、
[GStreamer HTTP source](https://gstreamer.freedesktop.org/documentation/soup/souphttpsrc.html)。
