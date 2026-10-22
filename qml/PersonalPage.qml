import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
import "UiLanguage.mjs" as Language

Item {
    id: page
    required property var music
    property string provider: "netease"
    property real bottomContentInset: 0
    property string section: "createdPlaylists"
    readonly property bool connected: provider === "netease"
    readonly property bool signedIn: connected && music.account.authenticated
    readonly property bool songs: section === "likedSongs" || section === "recentSongs"
    readonly property var feed: signedIn ? (music.personalFeed[section] || {}) : ({})
    readonly property var rows: feed.items || []
    readonly property var categories: [
        { key: "createdPlaylists", title: Language.text("My playlists", "我创建的歌单") },
        { key: "savedPlaylists", title: Language.text("Saved playlists", "收藏的歌单") },
        { key: "likedSongs", title: Language.text("Liked songs", "喜欢的音乐") },
        { key: "recentSongs", title: Language.text("Recent plays", "最近播放") },
        { key: "savedAlbums", title: Language.text("Saved albums", "收藏的专辑") },
        { key: "savedArtists", title: Language.text("Followed artists", "收藏的歌手") }
    ]
    signal signInRequested()
    function refresh() { if (visible && signedIn) music.reloadPersonal() }
    onVisibleChanged: refresh()
    onSignedInChanged: section = "createdPlaylists"
    Connections {
        target: page.music.account
        function onSessionChanged() { Qt.callLater(page.refresh) }
    }
    Connections {
        target: page.music
        function onReadyChanged() { Qt.callLater(page.refresh) }
    }
    onSectionChanged: { if (personalScroll && personalScroll.contentItem) personalScroll.contentItem.contentY = 0 }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(420, parent.width - 48)
        visible: !page.signedIn
        spacing: 14
        Label {
            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
            text: !page.connected ? Language.text("Bilibili account is not connected", "B站账号尚未接入")
                : page.music.account.state === "restoring" ? Language.text("Restoring your session…", "正在恢复登录…")
                : Language.text("Your music, in one place", "你的音乐，汇集于此")
            font.pixelSize: 22; font.weight: Font.Bold; color: AppTheme.text
        }
        Label {
            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            text: !page.connected ? Language.text("Personal content will be available when this platform is connected.", "此平台接入后可查看个人内容。")
                : Language.text("Sign in to NetEase to view your playlists, liked songs, collections and recent plays.", "登录网易云后，查看你的歌单、喜欢的音乐、收藏与最近播放。")
            font.pixelSize: 13; color: AppTheme.mutedText
        }
        MusicActionButton {
            Layout.alignment: Qt.AlignHCenter
            visible: page.connected
            enabled: page.music.account.state !== "restoring"
            text: Language.text("Sign in to NetEase", "登录网易云")
            onClicked: page.signInRequested()
        }
    }
    ScrollView {
        id: personalScroll
        anchors.fill: parent; visible: page.signedIn
        contentWidth: availableWidth; clip: true
        ColumnLayout {
            x: 24; width: personalScroll.availableWidth - 48; spacing: 18
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Artwork { Layout.preferredWidth: 44; Layout.preferredHeight: 44; radius: 22; source: page.signedIn ? page.music.account.avatarUrl : ""; title: page.signedIn ? page.music.account.nickname : "" }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 3
                    Label { text: page.signedIn ? page.music.account.nickname : ""; color: AppTheme.text; font.pixelSize: 21; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
                    Label { text: Language.text("NetEase Cloud Music", "网易云音乐"); color: AppTheme.mutedText; font.pixelSize: 12 }
                }
                MusicActionButton { text: Language.text("Refresh", "刷新"); enabled: !page.feed.loading; onClicked: page.refresh() }
            }
            Flow {
                Layout.fillWidth: true; spacing: 8
                Repeater {
                    model: page.categories
                    delegate: MusicActionButton {
                        required property var modelData
                        text: modelData.title; implicitHeight: 30
                        checked: page.section === modelData.key
                        onClicked: page.section = modelData.key
                    }
                }
            }
            Label {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                text: page.section === "recentSongs"
                    ? Language.text("Up to 100 recent songs from your NetEase account, separate from this device’s playback history.", "展示网易云账号最近播放的最多 100 首歌曲，与此设备的播放历史分开。")
                    : Language.text("From your NetEase account. Local playlists and favorites remain in Local Music.", "来自网易云账号；本机歌单与喜欢仍在本地音乐中。")
                color: AppTheme.mutedText; font.pixelSize: 12
            }
            RowLayout {
                Layout.fillWidth: true
                visible: page.feed.loading || !!page.feed.error || page.rows.length === 0
                Label {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap; color: AppTheme.mutedText; font.pixelSize: 13
                    text: page.feed.loading ? Language.text("Loading…", "正在加载…")
                        : page.feed.error ? Language.text("Could not load this section. Please try again.", "此栏目加载失败，请重试。")
                        : page.feed.more ? Language.text("More account entries are available. Load more to continue.", "账号还有更多条目，请加载更多继续查看。")
                        : Language.text("Nothing here yet.", "这里暂时没有内容。")
                }
                MusicActionButton { visible: !!page.feed.error && !page.feed.loading; text: Language.text("Retry", "重试"); onClicked: page.refresh() }
            }
            Label {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                visible: (page.feed.omittedCount || 0) > 0
                text: Language.text("Some song details are unavailable from NetEase.", "部分歌曲详情暂时无法从网易云获取。")
                color: AppTheme.mutedText; font.pixelSize: 12
            }
            GridLayout {
                Layout.fillWidth: true
                visible: !page.songs
                columns: Math.max(2, Math.floor(width / 170)); columnSpacing: 16; rowSpacing: 18
                Repeater {
                    model: page.songs ? [] : page.rows
                    delegate: AlbumTile {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true; Layout.preferredWidth: 1
                        title: modelData.title || ""; subtitle: modelData.artist || ""
                        artwork: modelData.artwork || ""
                        onClicked: page.music.openPersonalItem(page.section, index)
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 0; visible: page.songs
                Repeater {
                    model: page.songs ? page.rows : []
                    delegate: AbstractButton {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true; implicitHeight: 56
                        hoverEnabled: true
                        Accessible.name: Language.text("Play ", "播放 ") + (modelData.title || "")
                        onClicked: page.music.playPersonalSong(page.section, index)
                        background: Rectangle { radius: 8; color: parent.hovered ? MusicColors.hoverFill : "transparent"; border.width: parent.visualFocus ? 1 : 0; border.color: MusicColors.focus }
                        contentItem: RowLayout {
                            spacing: 12
                            Artwork { Layout.preferredWidth: 40; Layout.preferredHeight: 40; radius: 5; source: modelData.artwork || ""; title: modelData.title || "" }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 3
                                Label { text: modelData.title || ""; Layout.fillWidth: true; elide: Text.ElideRight; color: AppTheme.text; font.pixelSize: 13; font.weight: Font.Medium }
                                Label { text: modelData.artist || ""; Layout.fillWidth: true; elide: Text.ElideRight; color: AppTheme.mutedText; font.pixelSize: 11 }
                            }
                            Label {
                                visible: page.section === "recentSongs" && Number(modelData.playedAt || 0) > 0
                                text: visible ? Qt.formatDateTime(new Date(Number(modelData.playedAt)), "MM-dd hh:mm") : ""
                                font.pixelSize: 11; color: AppTheme.mutedText
                            }
                            VectorIcon { name: "mediaPlay"; filled: true; size: 14; color: MusicColors.sidebarAccent }
                        }
                    }
                }
            }
            MusicActionButton {
                Layout.alignment: Qt.AlignHCenter
                visible: !!page.feed.more
                enabled: !page.feed.loading
                text: page.feed.loading ? Language.text("Loading…", "正在加载…") : Language.text("Load more", "加载更多")
                onClicked: page.music.loadMorePersonal(page.section)
            }
            Item { Layout.preferredHeight: page.bottomContentInset + 16 }
        }
    }
}
