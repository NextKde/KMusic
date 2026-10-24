# 哔哩哔哩账号与资料库

[English](BilibiliAccount.md)

B站头像和个人页使用独立的哔哩哔哩账号窗口。生成二维码后，由用户用官方手机端扫码确认；
只有 `/x/web-interface/nav` 核实身份后才接受会话。不读取浏览器 Cookie，不输入密码，不自动确认扫码。
二维码 180 秒过期；取消会停止轮询并清除尚未确认的会话，绝不访问响应中的跨域登录地址。

个人页仅提供只读资料：收藏夹、夹内视频（每页 20 项）和账号视频历史（每次 20 条游标分页）。
非视频或失效条目可能省略。账号历史来自服务端，与本地最近播放分开；没有新增播放历史上报。
浏览不保存本地曲目、不改变队列；明确播放时才转换为公共 BV/cid 身份，以当前会话重新解析。
继续使用已有普通 AAC 与权限判断，不绕过会员或版权限制。

账号 API 和 passport 共用来源独立的原生 Cookie 容器，只访问固定 HTTPS 域名，拒绝重定向，
单响应最多 4 MiB，绝对期限 15 秒。Cookie 不进入 CDN 播放描述或本地媒体身份。
私有资料保留账号作用域，读取／操作时核对；仅明确播放时移除账号身份。会话变化取消旧请求，
清空资料、搜索与待播放状态。网络／验证错误不会删掉凭据，明确未登录响应才使会话失效。

凭据使用独立 QtKeychain 项 `NextKde.KMusic/bilibili.session`，禁止不安全明文回退。
本机退出立即同步关闭恢复开关，凭据库删除失败也不会恢复旧账号。读写与删除串行：
旧读写完成后才移除，存储清理期间禁止开始新登录／恢复。保存失败仅本次会话有效，可重试清理。
退出只作用于此设备，不是服务端全设备撤销；没有刷新 Token 或云写入接口。

模块分为会话 HTTP、AccountProvider、LibraryProvider、独立账号／资料控制器，以及个人页／账号窗口。
网易云流程保持独立。专用截图接口会避开两种来源的二维码及已显示的账号身份。

协议参考为真实 B站端点的社区资料，并非官方稳定 API 承诺：
[扫码](https://github.com/bilibili-plugins/bilibili-api-collect/blob/master/docs/login/login_action/QR.md)、
[收藏夹](https://github.com/bilibili-plugins/bilibili-api-collect/blob/master/docs/fav/info.md)、
[夹内条目](https://github.com/bilibili-plugins/bilibili-api-collect/blob/master/docs/fav/list.md)、
[历史游标](https://github.com/bilibili-plugins/bilibili-api-collect/blob/master/docs/historytoview/history.md)。
代码独立实现，没有复制、翻译或移植 Biu 源码。

验证仅在 VM。解析／会话夹具覆盖状态码、二维码域名路径、身份与验证错误、缺失数据、
虚构 Cookie 的恢复／清除／过期、账号作用域、取消和历史游标推进。夹具不代表真实登录、
实际密钥环竞态执行或私有资料可用；仍需用户真实扫码及交互确认。夹具与日志不含真实凭据。

二维码仅允许精确 HTTPS 入口 `passport.bilibili.com/h5-app/passport/login/scan`
（旧版）及 `account.bilibili.com/h5/account-h5/auth/scan-web`（本轮真实响应），
并核对挑战参数一致，不接受同域任意路径。

本轮虚拟机完整应用构建和四项提供者测试通过。真实匿名请求已完成生成二维码、
等待扫码、取消挑战、nav 返回未登录的检查；只记录状态，不记录二维码地址或密钥，
未进行用户扫码。隔离应用已打开哔哩哔哩个人页，未出现 QML 错误。
真实账号收藏/历史以及系统凭据库并发操作仍待用户授权扫码后验证。
