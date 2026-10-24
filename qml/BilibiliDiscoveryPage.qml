import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
import "UiLanguage.mjs" as Language
Item {
    id: page
    required property var backend
    property real bottomContentInset: 100
    property real topContentInset: 68
    signal searchRequested()
    signal signInRequested()
    readonly property var discovery: backend.discovery
    readonly property var emptyFeed: ({ items: [], loading: false, error: "", more: false, loaded: false })
    function refreshIfVisible() { if (visible) discovery.ensureLoaded() }
    onVisibleChanged: refreshIfVisible()
    Component.onCompleted: refreshIfVisible()
    ScrollView {
        id: scroll
        anchors.fill: parent; contentWidth: availableWidth; clip: true
        ColumnLayout {
            x: 28; width: scroll.availableWidth - 56; spacing: 26
            Item { Layout.preferredHeight: page.topContentInset }
            RowLayout {
                Layout.fillWidth: true
                Label { Layout.fillWidth: true; color: AppTheme.mutedText; text: Language.text("Music videos from Bilibili", "来自哔哩哔哩的音乐视频") }
                MusicActionButton { text: Language.text("Search videos", "搜索视频"); iconName: "search"; onClicked: page.searchRequested() }
            }
            Repeater {
                model: ["newSongs", "recommendations", "popular", "following"]
                delegate: BilibiliFeedSection {
                    required property string modelData
                    Layout.fillWidth: true
                    visible: modelData !== "following" || page.backend.account.authenticated
                    heading: modelData === "newSongs" ? Language.text("New music", "新歌")
                        : modelData === "recommendations" ? Language.text("Music picks", "音乐推荐")
                        : modelData === "popular" ? Language.text("Popular music videos", "热门音乐视频") : Language.text("Following updates", "关注更新")
                    tileWidth: modelData === "newSongs" ? 240 : 208
                    feed: page.discovery.sections[modelData] || page.emptyFeed
                    requiresSignIn: modelData === "following" && !page.backend.account.authenticated
                    onRefreshRequested: page.discovery.reload(modelData)
                    onRetryRequested: page.discovery.retry(modelData)
                    onMoreRequested: page.discovery.loadMore(modelData)
                    onPlayRequested: row => page.discovery.play(modelData, row)
                    onSignInRequested: page.signInRequested()
                }
            }
            Item { Layout.preferredHeight: page.bottomContentInset + 16 }
        }
    }
}
