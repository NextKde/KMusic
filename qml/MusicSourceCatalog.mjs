// Declarative navigation only. Capability evidence is not an implemented adapter.
export const sources = [
    { id: "netease", category: "online", en: "NetEase Cloud Music", zh: "网易云音乐", status: "connected", search: ["song", "playlist", "album", "artist"] },
    { id: "bilibili", category: "online", en: "Bilibili", zh: "哔哩哔哩", status: "partial", search: ["video"] },
    { id: "local", category: "local", en: "Local Music", zh: "本地音乐", status: "connected", search: ["song", "album", "artist"] },
    { id: "navidrome", category: "media", en: "Navidrome / OpenSubsonic", zh: "Navidrome / OpenSubsonic", status: "unconnected", search: ["song", "album", "artist"] },
    { id: "jellyfin", category: "media", en: "Jellyfin", zh: "Jellyfin", status: "unconnected", search: ["song", "album", "artist"] },
    { id: "webdav", category: "media", en: "WebDAV", zh: "WebDAV", status: "unconnected", search: ["file", "folder"] }
]
export function source(id) { return sources.find(item => item.id === id) || sources[0] }
export function label(item, chinese) { return chinese ? item.zh : item.en }
function entry(id, en, zh, route, status, login = false) { return {id, en, zh, route, status, login} }
export function sections(id) {
    if (id === "netease") return [
        {en: "Browse", zh: "浏览", entries: [entry("discover", "Discover", "发现", "new", "connected"), entry("search", "Search", "搜索", "online", "connected")]},
        {en: "My Music", zh: "我的音乐", entries: [
            entry("daily", "Daily recommendations", "每日推荐", "demo", "prototype", true),
            entry("liked", "Liked songs", "我喜欢的音乐", "demo", "prototype", true),
            entry("created", "Created playlists", "创建的歌单", "demo", "prototype", true),
            entry("collected", "Collected playlists", "收藏的歌单", "demo", "prototype", true),
            entry("albums", "Collected albums", "收藏的专辑", "demo", "prototype", true),
            entry("artists", "Followed artists", "关注的歌手", "demo", "prototype", true),
            entry("history", "Recently played", "最近播放", "demo", "prototype", true)]}
    ]
    if (id === "bilibili") return [
        {en: "Browse", zh: "浏览", entries: [entry("recommend", "Discover", "发现", "bilibiliDiscover", "connected"), entry("search", "Search", "搜索", "bilibili", "connected"), entry("uploaders", "Uploaders", "UP主", "demo", "prototype"), entry("collections", "Collections", "合集", "demo", "prototype")]},
        {en: "My Bilibili", zh: "我的B站", entries: [entry("favorites", "Favorite folders", "收藏夹", "demo", "prototype", true), entry("history", "Watch history", "观看历史", "demo", "prototype", true)]}
    ]
    if (id === "local") return [
        {en: "Music Library", zh: "音乐库", entries: [entry("songs", "Songs", "歌曲", "songs", "connected"), entry("albums", "Albums", "专辑", "albums", "connected"), entry("artists", "Artists", "艺术家", "artists", "connected")]},
        {en: "Manage", zh: "管理", entries: [entry("folders", "Music folders", "音乐文件夹", "folders", "connected")]}
    ]
    if (id === "webdav") return [{en: "Connection", zh: "连接", entries: [entry("connection", "Connection preview", "连接示意", "demo", "unconnected")]}, {en: "File Source", zh: "文件来源", entries: [entry("folders", "Folders", "文件夹", "demo", "unconnected"), entry("files", "Audio files", "音频文件", "demo", "unconnected")]}]
    return [{en: "Connection", zh: "连接", entries: [entry("connection", "Connection preview", "连接示意", "demo", "unconnected")]}, {en: "Server Library", zh: "服务器音乐库", entries: [entry("albums", "Albums", "专辑", "demo", "unconnected"), entry("artists", "Artists", "艺术家", "demo", "unconnected"), entry("playlists", "Playlists", "歌单", "demo", "unconnected"), entry("favorites", "Server favorites", "服务器收藏", "demo", "unconnected")]}]
}
// Stable identity: provider + account/server instance + item kind + external id.
// Never merge equally named playlists or history from different scopes.
export function itemKey(provider, instance, kind, externalId) {
    return [provider, instance || "anonymous", kind, String(externalId)].map(encodeURIComponent).join(":")
}
