# 网易云个人页后端

[English](PersonalBackend.md)

已实现只读账号资料适配，真实认证调用尚未验证；需要本应用确认的网易云会话。
本地收藏、本地最近播放仍是独立数据；没有新增云端喜欢／关注／歌单修改或同步操作。

`MusicController.personalFeed` 为 `QVariantMap`，通知信号 `personalChanged`。
各分区含 `items/loading/error/more/nextOffset/scopeLabel` 和累计 `omittedCount`；
成功响应另有 `loaded/total`，`total=-1` 表示未知或不可充当分类总数。
项目字段为 `providerId/title/artist/artwork/kind/source`；歌曲另有 `album/durationMs`，
历史事件另有毫秒级 `playedAt` 与区分重复歌曲事件的 `entryId`。

| 分区 | 真实接口与分页 |
| --- | --- |
| createdPlaylists | `user_playlist`，每批 50 个原始账号项目，创建者等于私有当前用户 ID。 |
| savedPlaylists | 同一混合列表及游标，创建者不同；某分类本批可能为空但仍有更多，不将混合总数冒充分类总数。 |
| likedSongs | 内存 `likelist` ID 快照，再按来源顺序每批 100 个 `song_detail`；缺失／无名称元数据计入省略数。 |
| recentSongs | `/api/play-record/song/list` 最新最多 100 条真实服务端记录；无 offset，明确上限并设 `more=false`。保留服务顺序及重复事件，不是听歌排行或本地历史。 |
| savedAlbums | `album_sublist`，每批 50，真实 offset 与来源 count/hasMore。 |
| savedArtists | `artist_sublist`，每批 50，真实 offset 与来源 count/hasMore。 |

`reloadPersonal()` 重置并加载六区，已有加载时拒绝重复刷新。
`loadMorePersonal(section)` 去重追加；失败设置 `loading=false/error`，保留列表、游标、
`more` 和省略计数，可重试本页或刷新。辅助进程重启丢失喜欢 ID 快照时需要刷新。
服务端资料可能在分页间变化，这不是服务端原子快照。

`openPersonalItem(section,row)` 复用歌单／专辑／歌手详情并发出 `personalCollectionOpened()`。
`playPersonalSong(section,row)` 仅接受喜欢／历史歌曲，明确操作才保存所选元数据并重新解析地址，
继续使用已有试听／权限判断。浏览不向 SQLite 写入账号内容，不改播放和队列。

用户 ID 仅有 C++ getter，不暴露为 QML 属性。登录、恢复、退出和失效均清除分区与已开的个人详情。
C++ 会话／请求代号及辅助进程认证代号拒绝旧响应；ID 快照仅在内存，替换会话和退出时清除。
界面在 ready／会话重置完成后延迟刷新。

主要来源为[固定 SPlayer 模块](https://github.com/SPlayer-Dev/SPlayer-Next/tree/05a4e5929030df21a8448ddb24c77dbd353f974e/electron/main/apis/netease/modules)。
原历史模块依赖 Electron web-client；本应用明确改为同端点原生 weapi，协议形态参照
[增强版模块](https://github.com/neteasecloudmusicapienhanced/api-enhanced/blob/main/module/record_recent_song.js)。
失败保留错误，不退回 `user_record` 听歌排行榜。来源及传输差异见 `providers/netease/NOTICE.md`。

本次没有执行功能测试、模拟登录、截图或图形验证。统一构建／打开由协调者负责；
真实扫码、账号分页／权限／历史仍需用户完成验证。
