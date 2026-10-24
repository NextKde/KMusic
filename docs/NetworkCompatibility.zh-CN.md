# Qt 网络兼容缓解

[English](NetworkCompatibility.md)

用户报告的 KMusic 崩溃发生在 Qt 6.12.0-3。协调者使用匹配调试符号确认：处理
HTTP/2 HEADERS 时，经 Qt network reply 私有指针发生非法访问，调用路径包含
`QHttpHeaderParser::setStatusCode` ← `QHttpNetworkReply::setStatusCode` ←
`QHttp2ProtocolHandler::handleHeadersReceived`。**非法指针的来源尚未证实**，
不能据此认定某个 Qt CVE 或应用生命周期错误。core、Cookie、账号凭据不提交、不上传。

KMusic 的 Qt 网络路径现在统一使用 `MusicProviders::NetworkAccessManager`：
复制请求，在创建 reply 前关闭 `Http2AllowedAttribute` 和 `Http2DirectAttribute`。
这是通过 HTTP/1.1 绕开已观察到的 HTTP/2 故障路径，不代表根因已修复。
覆盖提供者 HTTP、哔哩哔哩账号/API、直接歌词、Subsonic、旧音源传输，以及由独立
QML network factory 创建的封面/头像请求。QML manager 不与原生账号 Cookie jar 混用。
TLS 验证、Cookie、请求头、重定向、超时和取消策略保持原样，不改系统 Qt、桌面配置
或进程级网络环境变量。Node/GStreamer 不属于 Qt QNetworkAccessManager，保持不变。

Qt 对 [CVE-2026-95620](https://www.qt.io/blog/security-advisory-cve-2026-95620) 和
[CVE-2026-96432](https://www.qt.io/blog/security-advisory-cve-2026-96432) 推荐使用
这一逐请求禁用 HTTP/2 的机制；公告的受影响版本范围与本次主机 Qt 6.12.0 不同。
因此公告只支持缓解手段，不能证明本次崩溃与这些 CVE 相同。在查明根因前，对支持的
Qt 版本统一应用该策略。失去 HTTP/2 多路复用后，封面较多的页面可能增加连接数。

## 验证边界

全部构建/运行测试在 Qt 6.10.2 的开发虚拟机进行，主机实例不变。原版本六轮冷缓存
加载、切源和退出未复现主机崩溃，后续检查不能冒称已经复现并修复原始根因。

提供者测试补充原生/QML factory 策略、原请求和 TLS 配置/请求头保持、重定向、取消
及调用方销毁；真实 API 和实际封面请求返回 HTTP 200，确认
`Http2WasUsedAttribute=false` 且策略生效。仅记录状态，不记录 URL、响应内容、二维码
或 Cookie。完整应用另进行同样有界的冷缓存加载/退出检查；不等同于真实账号或视觉验收。
