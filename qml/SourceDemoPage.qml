import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui

ScrollView {
    id: page
    property string sourceId: ""
    property string entryId: ""
    property string sourceName: ""
    property string instanceName: ""
    readonly property bool mediaSource: ["navidrome", "jellyfin", "webdav"].indexOf(sourceId) >= 0
    property string entryName: ""
    property string connectionStatus: "prototype"
    property bool requiresLogin: false
    property bool authenticated: false
    property real bottomContentInset: 0
    property string prototypeContentKind: "video"
    property string prototypeQuery: ""
    property string submittedPrototypeQuery: ""
    onSourceIdChanged: { prototypeQuery = ""; submittedPrototypeQuery = ""; prototypeContentKind = "video" }
    onEntryIdChanged: { prototypeQuery = ""; submittedPrototypeQuery = "" }
    signal accountRequested()
    signal connectionRequested()
    contentWidth: availableWidth
    clip: true
    function neteaseDescription() {
        switch (entryId) {
        case "daily": return qsTr("当前网易云账号的每日推荐，与发现页的新专辑内容不同。")
        case "liked": return qsTr("网易云账号中喜欢的歌曲，与 KMusic 本机喜欢分别保存。")
        case "created": return qsTr("网易云账号创建的歌单，不包含本机歌单。")
        case "collected": return qsTr("网易云账号收藏的歌单，与自己创建的歌单分别显示。")
        case "albums": return qsTr("网易云账号收藏的专辑，与本地文件的专辑分类不同。")
        case "artists": return qsTr("网易云账号关注的歌手，与本地文件标签中的艺术家不同。")
        case "history": return qsTr("网易云账号的最近播放，与听歌排行和本机播放历史不同。")
        default: return ""
        }
    }
    function biliDescription() {
        switch (entryId) {
        case "recommend": return qsTr("哔哩哔哩推荐的视频内容。")
        case "search": return qsTr("可选择视频、UP主或合集，仅演示哔哩哔哩范围内的搜索入口。")
        case "uploaders": return qsTr("UP主是哔哩哔哩内容创作者，投稿不会自动归类为音乐专辑。")
        case "collections": return qsTr("合集组织哔哩哔哩视频，不会转换成网易云歌单。")
        case "favorites": return qsTr("哔哩哔哩账号的收藏夹，与网易云喜欢和本机收藏分别保存。")
        case "history": return qsTr("哔哩哔哩账号的观看历史，与 KMusic 本机播放历史不同。")
        default: return ""
        }
    }
    function mediaDescription() {
        if (sourceId === "webdav") return qsTr("WebDAV 提供文件夹和文件，本身不提供艺术家、专辑、推荐或账号收藏分类。")
        if (sourceId === "navidrome") return qsTr("Navidrome / OpenSubsonic 是个人音乐服务器。专辑、艺术家、歌单和收藏属于该服务器及其账号。")
        return qsTr("Jellyfin 提供服务器媒体库，音乐库与账号归属于所连接的服务器。")
    }
    ColumnLayout {
        width: page.availableWidth - 64; x: 32; spacing: 16
        Item { implicitHeight: 24 }
        Label { text: page.sourceName; color: AppTheme.mutedText; font.pixelSize: 13 }
        Label { Layout.fillWidth: true; text: page.entryName; color: AppTheme.text; font.pixelSize: 24; font.weight: Font.Bold; wrapMode: Text.WordWrap }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: page.sourceId === "netease" && page.requiresLogin
                ? page.authenticated ? qsTr("账号已登录 · 账号目录尚未接入") : qsTr("登录以查看账号内容")
                : qsTr("导航示意 · 尚未接入")
            color: AppTheme.text; font.pixelSize: 15; font.weight: Font.DemiBold
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: page.sourceId === "netease" ? page.neteaseDescription() : page.sourceId === "bilibili" ? page.biliDescription() : page.mediaSource ? page.mediaDescription() : qsTr("此来源使用独立的音乐库和账号。")
            color: AppTheme.mutedText; font.pixelSize: 14
        }
        ColumnLayout {
            visible: page.mediaSource
            Layout.fillWidth: true; spacing: 12
            Label { text: qsTr("来源连接"); color: AppTheme.text; font.pixelSize: 17; font.weight: Font.DemiBold }
            Label {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                text: page.instanceName.length > 0 ? qsTr("%1 · 仅为示例，未连接").arg(page.instanceName) : qsTr("尚未连接服务器，可选择示例查看连接入口。")
                color: AppTheme.mutedText
            }
            MusicActionButton { text: qsTr("查看连接示意"); onClicked: page.connectionRequested() }
            Label {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                text: page.sourceId === "webdav" ? qsTr("浏览：文件夹 → 文件。建立索引后可在此来源内搜索。") : qsTr("浏览：服务器 → 音乐库 → 专辑、艺术家或歌单。搜索范围限定在该服务器内。")
                color: AppTheme.mutedText
            }
        }
        ColumnLayout {
            visible: page.sourceId === "bilibili" && page.entryId === "search"
            Layout.fillWidth: true; spacing: 12
            Label { text: qsTr("哔哩哔哩搜索 · 交互示意"); color: AppTheme.text; font.pixelSize: 17; font.weight: Font.DemiBold }
            Flow {
                Layout.fillWidth: true; spacing: 8
                Repeater {
                    model: [{id:"video", title:qsTr("视频")}, {id:"uploader", title:qsTr("UP主")}, {id:"collection", title:qsTr("合集")}]
                    delegate: MusicActionButton {
                        required property var modelData
                        text: modelData.title; checkable: true
                        checked: page.prototypeContentKind === modelData.id
                        onClicked: { page.prototypeContentKind = modelData.id; page.submittedPrototypeQuery = "" }
                    }
                }
            }
            LiquidTextField {
                Layout.fillWidth: true
                materialForm: true
                text: page.prototypeQuery
                placeholderText: qsTr("搜索哔哩哔哩（仅示意）")
                onTextEdited: page.prototypeQuery = text
                onAccepted: page.submittedPrototypeQuery = text.trim()
            }
            MusicActionButton {
                text: qsTr("查看搜索范围")
                enabled: page.prototypeQuery.trim().length > 0
                onClicked: page.submittedPrototypeQuery = page.prototypeQuery.trim()
            }
            Label {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                visible: page.submittedPrototypeQuery.length > 0
                text: qsTr("哔哩哔哩 / %1 / %2 · 仅为示意，未发送请求，也未生成结果。").arg(page.prototypeContentKind === "video" ? "视频" : page.prototypeContentKind === "uploader" ? "UP主" : "合集").arg(page.submittedPrototypeQuery)
                color: AppTheme.mutedText
            }
        }
        MusicActionButton {
            visible: page.sourceId === "netease" && page.requiresLogin && !page.authenticated
            text: qsTr("登录网易云音乐")
            onClicked: page.accountRequested()
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: page.sourceId === "bilibili"
                ? qsTr("哔哩哔哩尚未接入，账号、收藏、历史和视频播放暂不可用。网易云登录不会登录哔哩哔哩。")
                : page.mediaSource ? qsTr("媒体源尚未接入。示例不包含真实服务器、账号或音乐库。")
                : qsTr("当前仅展示菜单入口，账号目录尚未接入。登录后这些页面仍不会获取推荐、歌单或收藏。")
            color: AppTheme.mutedText; font.pixelSize: 13
        }
        Item { implicitHeight: page.bottomContentInset + 16 }
    }
}
