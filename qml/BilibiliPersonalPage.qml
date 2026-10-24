import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
import "UiLanguage.mjs" as Language
Item {
    id: page
    required property var backend
    property real bottomContentInset: 0
    signal signInRequested()
    readonly property var account: backend.account
    readonly property var library: backend.library
    readonly property bool folderOpen: library.folderTitle.length > 0
    readonly property var rows: library.showingHistory ? library.history : library.items
    function refresh() { if (visible && account.authenticated) library.reload() }
    onVisibleChanged: refresh()
    Connections { target: page.account; function onSessionChanged() { Qt.callLater(page.refresh) } }
    ColumnLayout {
        anchors.centerIn: parent; width: Math.min(420, parent.width - 48); spacing: 14
        visible: !page.account.authenticated
        Label { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; color: AppTheme.text; font.pixelSize: 23; text: Language.text("Your Bilibili library", "你的哔哩哔哩资料库") }
        Label { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; color: AppTheme.mutedText; text: Language.text("Sign in to read your favorites folders and account video history. Nothing is written to the cloud.", "登录后查看收藏夹与账号视频历史，不会向云端写入内容。") }
        MusicActionButton { Layout.alignment: Qt.AlignHCenter; text: Language.text("Sign in to Bilibili", "登录哔哩哔哩"); onClicked: page.signInRequested() }
    }
    ScrollView {
        id: scroll
        anchors.fill: parent; visible: page.account.authenticated; contentWidth: availableWidth; clip: true
        ColumnLayout {
            x: 24; width: scroll.availableWidth - 48; spacing: 16
            RowLayout {
                Layout.fillWidth: true
                Artwork { source: page.account.avatarUrl; title: page.account.nickname; radius: 22; Layout.preferredWidth: 44; Layout.preferredHeight: 44 }
                Label { text: page.account.nickname; textFormat: Text.PlainText; color: AppTheme.text; font.pixelSize: 21; Layout.fillWidth: true; elide: Text.ElideRight }
                MusicActionButton { text: Language.text("Account", "账号"); onClicked: page.signInRequested() }
            }
            RowLayout {
                MusicActionButton { text: Language.text("Favorites folders", "收藏夹"); checked: !page.library.showingHistory; onClicked: page.library.reload(); enabled: !page.library.busy }
                MusicActionButton { text: Language.text("Account history", "账号历史"); checked: page.library.showingHistory; onClicked: page.library.showHistory(); enabled: !page.library.busy }
                MusicActionButton { visible: page.folderOpen; text: Language.text("Back", "返回"); onClicked: page.library.back() }
            }
            Label { Layout.fillWidth: true; color: AppTheme.text; font.pixelSize: 20; textFormat: Text.PlainText; text: page.library.showingHistory ? Language.text("Recent account videos", "账号最近视频") : page.folderOpen ? page.library.folderTitle : Language.text("Favorites folders", "收藏夹") }
            Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: AppTheme.mutedText; text: Language.text("Read-only Bilibili account data, separate from local recent plays. Deleted or unsupported entries may be omitted; playback remains subject to Bilibili permissions.", "来自哔哩哔哩的只读账号资料，与本地最近播放分开。已删除或不支持的条目可能省略，可播放范围仍受来源权限限制。") }
            RowLayout {
                Layout.fillWidth: true; visible: page.library.busy || page.library.error.length > 0
                Label { Layout.fillWidth: true; color: AppTheme.mutedText; text: page.library.busy ? Language.text("Loading…", "正在加载…") : page.library.error === "verification" ? Language.text("Complete verification on the official Bilibili website, then retry.", "请在哔哩哔哩官方网站完成验证后重试。") : page.library.error === "rateLimited" ? Language.text("Bilibili request limit reached. Wait and retry.", "哔哩哔哩请求过于频繁，请稍后重试。") : Language.text("Could not load Bilibili. Check the connection and retry.", "暂时无法加载哔哩哔哩，请检查连接后重试。") ; wrapMode: Text.WordWrap }
                MusicActionButton { visible: !page.library.busy; text: Language.text("Retry", "重试"); onClicked: page.library.retry() }
            }
            GridLayout {
                Layout.fillWidth: true; visible: !page.library.showingHistory && !page.folderOpen
                columns: Math.max(2, Math.floor(width / 170)); columnSpacing: 16; rowSpacing: 16
                Repeater { model: page.library.folders; delegate: AlbumTile {
                    required property var modelData; required property int index
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    title: modelData.title || ""; artwork: modelData.artwork || ""; subtitle: Language.text("Favorites folder", "收藏夹")
                    onClicked: page.library.openFolder(index)
                } }
            }
            ColumnLayout {
                Layout.fillWidth: true; visible: page.library.showingHistory || page.folderOpen
                Repeater { model: page.rows; delegate: AbstractButton {
                    required property var modelData; required property int index
                    Layout.fillWidth: true; implicitHeight: 58; hoverEnabled: true
                    Accessible.name: Language.text("Play ", "播放 ") + (modelData.title || "")
                    onClicked: page.library.play(index)
                    background: Rectangle { radius: 8; color: parent.hovered ? MusicColors.hoverFill : "transparent"; border.width: parent.visualFocus ? 1 : 0; border.color: MusicColors.focus }
                    contentItem: RowLayout { spacing: 12
                        Artwork { source: modelData.artwork || ""; title: modelData.title || ""; radius: 5; Layout.preferredWidth: 48; Layout.preferredHeight: 36 }
                        ColumnLayout { Layout.fillWidth: true
                            Label { text: modelData.title || ""; textFormat: Text.PlainText; color: AppTheme.text; elide: Text.ElideRight; Layout.fillWidth: true }
                            Label { text: modelData.artist || ""; textFormat: Text.PlainText; color: AppTheme.mutedText; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                        VectorIcon { name: "mediaPlay"; filled: true; size: 15; color: MusicColors.sidebarAccent }
                    }
                } }
            }
            Label { visible: !page.library.busy && !page.library.error.length && (page.library.showingHistory || page.folderOpen ? page.rows.length === 0 : page.library.folders.length === 0); text: Language.text("Nothing returned by Bilibili yet.", "哔哩哔哩暂未返回内容。"); color: AppTheme.mutedText }
            MusicActionButton { Layout.alignment: Qt.AlignHCenter; visible: page.library.more; enabled: !page.library.busy; text: Language.text("Load more", "加载更多"); onClicked: page.library.loadMore() }
            Item { Layout.preferredHeight: page.bottomContentInset + 16 }
        }
    }
}
