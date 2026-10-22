# 音源导航与能力调研

2026-10-22；本轮用户要求：先调研，完成简单菜单与可切换demo，10个小批次，约一小时后用户看效果。无截图、无自动视觉验收；保留Gallery共享材质。接口存在≠当前App已接通≠在线服务可用。

## 信息架构

左侧先选择来源：在线音乐（网易云/B站）、本地音乐、媒体源（具体服务器）。选定来源后才显示该来源的浏览和账号目录。页面标题、搜索占位符、空态都注明当前来源；不提供默认跨源搜索。队列和本机管理收藏/历史可跨源，但与来源账号内的收藏/历史分离。

## 能力矩阵

| 来源 | 浏览 | 账号内容 | 搜索边界 | KMusic现状 |
|---|---|---|---|---|
| 网易云 | 发现、歌曲/专辑/歌手/歌单 | 每日推荐、喜欢的歌曲、创建/收藏歌单、收藏专辑/歌手、最近播放 | 当前网易云账号/目录 | 发现新碟、搜索详情、URL歌词、二维码会话已接；账号内容接口尚未接 |
| B站 | 视频、UP主、合集 | 收藏夹、历史等为设计目标，不能等同网易云歌单/歌手 | B站内容 | 未接入；本轮只做标明状态的交互示意 |
| 本地 | 歌曲、文件夹、专辑、艺术家 | 无平台账号；标签/内嵌封面可存在，缺失时降级 | 本地导入文件 | 已接source=local歌曲/专辑/艺术家；文件夹浏览需按现有能力整理 |
| Navidrome/OpenSubsonic | 专辑、艺术家、歌曲、歌单；目录API可能为虚拟目录 | 服务器账号收藏/歌单 | 单个服务器实例 | 未接入；demo不连接用户服务器 |
| Jellyfin | 服务器音乐库及其音乐实体 | 服务器用户收藏等依接口 | 单个服务器音乐库 | 未接入 |
| WebDAV | 文件夹与音频文件 | 连接凭据，不等于音乐平台账号；默认无专辑目录接口 | 单个目录，索引前不声称完整全文搜索 | 未接入 |

## 网易云一手依据

- 当前本地归因参考SPlayer-Next 05a4e592：.task/reference/electron/main/apis/netease/index.ts列出likelist、record_recent_song、user_playlist、recommend_songs。现有helper是独立allowlist，不能把参考项目支持当作App已支持。
- [每日推荐模块](https://github.com/NeteaseCloudMusicApiEnhanced/api-enhanced/blob/main/module/recommend_songs.js)：每日歌曲，不等于匿名新碟。
- [用户歌单模块](https://github.com/NeteaseCloudMusicApiEnhanced/api-enhanced/blob/main/module/user_playlist.js)：用户歌单；创建/收藏需按返回归属划分。
- [喜欢歌曲模块](https://github.com/NeteaseCloudMusicApiEnhanced/api-enhanced/blob/main/module/likelist.js)：返回喜欢的歌曲ID，不是完整歌曲详情。
- [最近播放模块](https://github.com/NeteaseCloudMusicApiEnhanced/api-enhanced/blob/main/module/record_recent_song.js)：recent songs，与[user_record](https://github.com/NeteaseCloudMusicApiEnhanced/api-enhanced/blob/main/module/user_record.js)的周/累计听歌排行不是同一个概念。
- [库接口声明](https://github.com/NeteaseCloudMusicApiEnhanced/api-enhanced/blob/main/interface.d.ts)含album_sublist/artist_sublist等；本轮不调用未接入账号接口、不冒称扫码已完成。

## B站调研边界

[SocialSisterYi/bilibili-API-collect](https://github.com/SocialSisterYi/bilibili-API-collect)当前为deprecated且删除接口文档；[Nemo2011/bilibili-api](https://github.com/Nemo2011/bilibili-api)当前也已关停。搜索缓存中的旧函数不能作为当前接口可用证据。仅保留视频/UP主/合集/账号收藏夹等明确标识的导航设计，不能写成已实现音乐破解或可播放。后续应单独确认可维护的适配来源。

## 媒体源一手依据

- [OpenSubsonic端点](https://opensubsonic.netlify.app/docs/endpoints/)定义search3、getAlbum/getArtist、getPlaylists、getStarred2等；是否提供须按具体服务器能力显示。
- [Navidrome API说明](https://github.com/navidrome/website/blob/master/content/en/docs/developers/subsonic-api.md)：目录接口可能模拟Artist/Album树，不保证物理目录；stream请求不等于已记录播放，需播放上报。
- [Jellyfin音乐库](https://jellyfin.org/docs/general/server/media/music.html/)说明标签和内嵌封面；API站此次403未读到，不据此补全操作承诺。

## 十轮工作单

1. 已完成：在线查证、当前helper能力盘点、记录证据与不确定项。
2. 已完成：音源与能力声明模型；区分真实接入、需登录、示意、未连接，搜索由来源决定。
3. 来源选择菜单：三类清晰，来源实例与叶子目录分开，避免把账号目录塞满常驻侧栏。
4. 当前来源搜索：保留query和来源边界，不跨网易云/B站/本地/服务器串用结果。
5. 网易云目录：浏览/我的音乐分开；账号未接入功能以明确空态展示，真实登录入口保留。
6. B站demo：视频/UP主/合集/收藏夹语义，不伪造专辑/歌手或播放。
7. 媒体源demo：服务器/文件服务分开，连接配置仅示意不收集真实凭据。
8. 本地和本机管理：文件音乐库与跨来源收藏/历史/歌单说明明确，保留现有操作。
9. 收敛标题、空态、入口与键盘可达性源代码；说明需要用户检查的部分，不做自动交互验收。
10. 构建、打开最终demo，记录二进制版本，停止本次唤醒，交用户验收。构建成功不算视觉通过。

### 第4轮：来源搜索边界

当前只向已集成的网易云和本地文件库发送搜索。顶栏输入按来源保留各自query；切换来源不会把本地过滤条件带给网易云，也不会将其他demo来源的文字送入本地库。网易云页内搜索与导航搜索同步草稿，按Enter才从导航提交远端查询。Ctrl+F只聚焦当前可搜索来源；Ctrl+O与所有导入入口先切换本地来源。未接入B站/服务器时搜索禁用并说明，不展示其他来源结果。账号/服务器实例扩展时必须增加会话边界；本轮没有宣称多账号或多实例搜索已接通。

### 第5轮：网易云账号目录状态

浏览（匿名发现/搜索）与我的音乐分组分开；我的音乐包含每日推荐、喜欢、创建/收藏歌单、收藏专辑、关注歌手、最近播放。未登录显示真实登录入口；登录后仍明确“账号目录适配未接通”，不显示虚构音乐。每页解释与本机收藏/歌单/历史、听歌排行的区别。会话变更清理网易云搜索草稿；本地草稿不受影响。没有调用新的账号接口，也没有代替用户扫码。

### 第6轮：B站内容语义与交互示意

B站目录使用推荐视频、搜索、UP主、合集、收藏夹和观看历史，不借用音乐专辑/歌手。搜索页提供视频/UP主/合集的可切换示意与可输入query，提交只显示当前范围，不发请求、不伪造结果。底部B站账号入口只打开B站示意页，绝不调用网易云登录或显示网易云头像；本地/媒体源不展示在线平台账号入口。提示资料参考项目已停维护所对应的“当前未接入”状态，未添加真实B站适配器。

### 第7轮：媒体源连接与库类型

Navidrome/OpenSubsonic、Jellyfin以服务器音乐库为单位；WebDAV只显示目录/音频文件，不冒称有专辑/歌手API。媒体源先进入连接示意，能打开只包含示例名称和只读.invalid地址的菜单demo；修改名称仅在当前进程内保留，不连接服务器、不收集或保存凭据，不生成虚构音乐库。各来源名称独立，服务器收藏/歌单不与在线平台账号或本机集合混合。真正多实例适配仍待实现。

### 第8轮：本地文件与本机集合

本地“音乐文件夹”使用已有真实导入根目录，保留添加/重新扫描操作；它是已登记根目录列表，不冒称子目录浏览器。本地歌曲、专辑、艺术家来自导入文件与标签，封面缺失沿用占位图。本机收藏、播放历史、歌单页增加范围说明：可以保留不同来源的曲目引用，但不等同平台账号喜欢/历史/歌单，也不向平台同步。队列明确跨来源。没有变更共享组件材质，没有构建、交互验证或截图，运行版本仍为38f4f20。
