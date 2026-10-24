# 哔哩哔哩发现

[English](BilibiliDiscovery.md)

选择哔哩哔哩后进入发现，搜索保留为独立页面，并可返回发现。首页包含新歌、
音乐推荐、热门音乐视频三个普通内容分区。登录后才显示「关注更新」，它是关注
账号的各类视频投稿，不冒充纯音乐或个性化推荐。浏览只读取元数据，不改变播放；
明确点击视频才通过已有 BV/分 P 详情及 AAC 解析链路播放。

## 模块和接口

- `BilibiliDiscovery`：公开数据使用独立、无账号 Cookie 的传输。
  新歌 `/x/centralization/interface/new/music`，热门
  `/x/centralization/interface/music/comprehensive/web/rank`；音乐推荐使用 WBI 签名的
  `/x/web-interface/region/feed/rcmd`，参数 `from_region=1003`、`device=web`、
  `plat=30`、`request_cnt=15`、递增 `display_id`。本轮在虚拟机直接核对真实匿名
  JSON。热门只取 `related_archive` 的视频身份和 cid，避免混用歌曲与视频标识；
  新歌缺 cid 时交由已有 BV 详情补齐。
- `BilibiliFollowing`：私有只读关注接口独立实现，调用
  `/x/polymer/web-dynamic/v1/feed/all?type=video&platform=web`，原样传递 `offset`。
  协议参考：[社区动态列表文档](https://github.com/bilibili-plugins/bilibili-api-collect/blob/master/docs/dynamic/all.md)。
  账号、会话代次限制每次响应；换号/退出会取消请求并清空私有条目。仅明确播放
  才移除账号范围，转为公开视频身份；不调用关注、点赞或历史写入接口。
- `BilibiliDiscoveryController`：各区独立请求、加载、错误、重试与去重。
  `BilibiliFeedState` 用于确定性的过期响应和分页边界测试。析构先使代次失效、
  销毁请求句柄，避免回调进入已析构成员。
- `BilibiliDiscoveryPage` / `BilibiliFeedSection`：复用现有普通控件与固定顶栏，
  未修改共享材质。

`music.bilibili.discovery.sections` 的键为 `newSongs`、`recommendations`、
`popular`、`following`，每区含 `{items:[{providerId,title,artist,artwork}],
loading,error,more,loaded}`。提供 `ensureLoaded`、`reload(section)`、
`retry(section)`、`loadMore(section)`、`play(section,row)`。
加载更多失败保留旧条目和游标；拒绝游标停滞或循环，并按 BV/cid 去重。
新歌/热门是来源单次快照；音乐推荐最多请求 100 批，无新增视频则停止。
关注仅保留支持的直接视频投稿，已删、非视频或不支持内容可能省略。
页面不会把这些条目数冒充目录总数。

## 验证边界

仅在虚拟机完整构建、运行和测试。夹具覆盖正常/空/错误、热门关联视频匹配、
取消、合成会话下跨账号拒绝、换号过期结果、分页游标、重复条目及析构。
真实匿名探针仅记录状态和数量，不记录账号、Cookie、二维码或流地址。
真实关注数据仍需用户本人扫码；未登录的 `-101` 作为登录错误，不伪装成功空态。
夹具不能证明真实登录后的资料可用或视觉验收。未复制、翻译、移植 Biu 代码或网页素材；
主机不构建、不运行，原有实例不变。
