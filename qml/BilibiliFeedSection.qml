import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
import "UiLanguage.mjs" as Language
ColumnLayout {
    id: section
    required property string heading
    required property var feed
    property bool requiresSignIn: false
    property real tileWidth: 208
    signal refreshRequested()
    signal retryRequested()
    signal moreRequested()
    signal playRequested(int row)
    signal signInRequested()
    spacing: 12
    RowLayout {
        Layout.fillWidth: true
        Label { Layout.fillWidth: true; text: section.heading; color: AppTheme.text; font.pixelSize: 21; font.weight: Font.DemiBold }
        MusicActionButton { text: Language.text("Refresh", "刷新"); visible: !section.requiresSignIn; enabled: !section.feed.loading; onClicked: section.refreshRequested() }
    }
    RowLayout {
        Layout.fillWidth: true
        visible: section.requiresSignIn || section.feed.loading || section.feed.error.length > 0 || (section.feed.loaded && section.feed.items.length === 0)
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; color: AppTheme.mutedText
            text: section.requiresSignIn ? Language.text("Sign in to see videos from accounts you follow, across all categories.", "登录后查看关注账号的视频更新，包含各类视频。")
                : section.feed.loading ? Language.text("Loading…", "正在加载…")
                : section.feed.error === "verification" ? Language.text("Complete verification on Bilibili’s official website, then retry.", "请在哔哩哔哩官方网站完成验证后重试。")
                : section.feed.error === "rateLimited" ? Language.text("Too many requests. Wait and retry.", "请求过于频繁，请稍后重试。")
                : section.feed.error === "response" ? Language.text("Bilibili returned unavailable data. Retry this section later.", "哔哩哔哩返回的数据暂时不可用，请稍后重试此分区。")
                : section.feed.error.length > 0 ? Language.text("Could not load this section. Retry when connected.", "此分区暂时无法加载，请检查连接后重试。")
                : Language.text("No playable videos returned in this batch.", "这一批暂未返回可播放视频。")
        }
        MusicActionButton { visible: section.requiresSignIn; text: Language.text("Sign in", "登录"); onClicked: section.signInRequested() }
        MusicActionButton { visible: !section.requiresSignIn && !section.feed.loading && section.feed.error.length > 0; text: Language.text("Retry", "重试"); onClicked: section.retryRequested() }
    }
    ListView {
        id: videos
        Layout.fillWidth: true; Layout.preferredHeight: section.tileWidth * 0.5625 + 51
        visible: section.feed.items.length > 0 && !section.requiresSignIn
        orientation: ListView.Horizontal; spacing: 16; clip: true
        model: section.feed.items
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
        delegate: AbstractButton {
            required property var modelData
            required property int index
            width: section.tileWidth; height: videos.height - 8; hoverEnabled: true
            Accessible.name: Language.text("Play ", "播放 ") + (modelData.title || "")
            onClicked: section.playRequested(index)
            background: Item {}
            contentItem: Item {
                Artwork { id: image; width: parent.width; height: width * 0.5625; source: modelData.artwork || ""; title: modelData.title || ""; radius: 8 }
                Rectangle { anchors.fill: image; radius: 8; color: parent.parent.down ? "#18000000" : parent.parent.hovered ? "#0affffff" : "transparent"; border.width: parent.parent.visualFocus ? 2 : 0; border.color: AppTheme.focusRing }
                Label { anchors.top: image.bottom; anchors.topMargin: 8; width: parent.width; text: modelData.title || ""; textFormat: Text.PlainText; elide: Text.ElideRight; color: AppTheme.text; font.pixelSize: 13 }
                Label { anchors.top: image.bottom; anchors.topMargin: 27; width: parent.width; text: modelData.artist || ""; textFormat: Text.PlainText; elide: Text.ElideRight; color: AppTheme.mutedText; font.pixelSize: 11 }
            }
        }
    }
    MusicActionButton { Layout.alignment: Qt.AlignLeft; text: Language.text("Load more videos", "加载更多视频"); visible: section.feed.more && !section.requiresSignIn; enabled: !section.feed.loading; onClicked: section.moreRequested() }
}
