import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
import "UiLanguage.mjs" as Language

ScrollView {
    id: page
    required property var music
    property bool showHeading: true
    property real topContentInset: 0
    property real bottomContentInset: 0
    property real sidebarUnderlap: 0
    readonly property bool signedIn: music.account.authenticated
    signal importRequested()
    signal onlineRequested()
    signal onlineAlbumRequested(int row)
    signal nowPlayingRequested()
    signal albumRequested(string filter, string title)
    signal collectionRequested(string section, int row)
    contentWidth: availableWidth
    clip: true
    function feed(key) { return music.discoveryFeed[key] || {items: [], loading: false, error: ""} }
    function homeOpticalState() { return { content: "real NetEase discovery", personalized: signedIn } }
    function scrollReleaseReview(fraction) { return "{}" }

    component SectionTitle: Item {
        id: sectionTitle
        property string title: ""
        property string subtitle: ""
        property string actionText: ""
        signal actionRequested()
        Layout.fillWidth: true
        implicitHeight: Math.max(titleCopy.implicitHeight, titleAction.visible ? titleAction.height : 0)
        ColumnLayout {
            id: titleCopy
            anchors.left: parent.left
            anchors.right: titleAction.visible ? titleAction.left : parent.right
            anchors.rightMargin: titleAction.visible ? 16 : 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Label { text: sectionTitle.title; color: AppTheme.text; font.pixelSize: 21; font.weight: Font.Bold }
            Label { visible: text.length > 0; text: sectionTitle.subtitle; color: AppTheme.mutedText; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        }
        MusicActionButton {
            id: titleAction
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            visible: sectionTitle.actionText.length > 0
            text: sectionTitle.actionText; implicitHeight: 28
            onClicked: sectionTitle.actionRequested()
        }
    }
    component FeedState: RowLayout {
        property var state: ({})
        Layout.fillWidth: true
        visible: state.loading || (state.error || "").length > 0 || !(state.items || []).length
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; color: AppTheme.mutedText; font.pixelSize: 13
            text: parent.state.loading ? Language.text("Loading music…", "正在加载音乐…")
                : parent.state.error ? Language.text("Could not load this section.", "暂时无法加载此栏目。")
                : Language.text("No music available right now.", "暂时没有可展示的音乐。")
        }
        MusicActionButton {
            visible: (parent.state.error || "").length > 0
            text: Language.text("Retry", "重试"); implicitHeight: 28
            onClicked: page.music.reloadDiscovery()
        }
    }
    component CoverShelf: ColumnLayout {
        id: shelf
        property string heading: ""
        property string section: ""
        property var state: ({items: []})
        property bool albums: false
        property int startIndex: 0
        Layout.fillWidth: true; spacing: 10
        SectionTitle { title: shelf.heading }
        FeedState { state: shelf.state }
        Flickable {
            id: shelfView
            Layout.fillWidth: true; Layout.preferredHeight: 204
            visible: (shelf.state.items || []).length > 0
            contentWidth: covers.width; contentHeight: height; clip: false
            boundsBehavior: Flickable.StopAtBounds; flickableDirection: Flickable.HorizontalFlick
            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
            Row {
                id: covers; spacing: 14
                Repeater {
                    model: (shelf.state.items || []).slice(shelf.startIndex)
                    delegate: AlbumTile {
                        required property var modelData
                        required property int index
                        width: 152; title: modelData.title || ""; subtitle: modelData.artist || ""
                        artwork: modelData.artwork || ""
                        onClicked: shelf.albums ? page.onlineAlbumRequested(index + shelf.startIndex) : page.collectionRequested(shelf.section, index + shelf.startIndex)
                    }
                }
            }
        }
    }
    component SongSection: ColumnLayout {
        id: songSection
        property string heading: ""
        property string section: ""
        property int limit: 8
        property bool expanded: false
        property bool compact: false
        readonly property var state: page.feed(section)
        Layout.fillWidth: true; spacing: compact ? 8 : 10
        SectionTitle {
            title: songSection.heading
            actionText: (songSection.state.items || []).length <= songSection.limit ? "" : songSection.expanded ? Language.text("Show less", "收起") : Language.text("See all", "查看全部")
            onActionRequested: songSection.expanded = !songSection.expanded
        }
        FeedState { state: songSection.state }
        GridLayout {
            Layout.fillWidth: true; columns: width >= 620 ? 2 : 1
            columnSpacing: 20; rowSpacing: 0
            Repeater {
                model: (songSection.state.items || []).slice(0, songSection.expanded ? undefined : songSection.limit)
                delegate: AbstractButton {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true; Layout.preferredWidth: 1; implicitHeight: songSection.compact ? 48 : 58
                    hoverEnabled: true
                    Accessible.name: Language.text("Play ", "播放 ") + (modelData.title || "")
                    onClicked: page.music.playDiscoverySong(songSection.section, index)
                    background: Rectangle { radius: 8; color: parent.hovered ? MusicColors.hoverFill : "transparent"; border.width: parent.visualFocus ? 1 : 0; border.color: MusicColors.sidebarAccent }
                    contentItem: RowLayout {
                        spacing: songSection.compact ? 10 : 12
                        Artwork { Layout.preferredWidth: songSection.compact ? 38 : 46; Layout.preferredHeight: songSection.compact ? 38 : 46; source: modelData.artwork || ""; title: modelData.title || ""; radius: 6 }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: songSection.compact ? 2 : 4
                            Label { Layout.fillWidth: true; text: modelData.title || ""; elide: Text.ElideRight; font.pixelSize: 13; font.weight: Font.Medium; color: AppTheme.text }
                            Label { Layout.fillWidth: true; text: modelData.artist || ""; elide: Text.ElideRight; font.pixelSize: 11; color: AppTheme.mutedText }
                        }
                        VectorIcon { name: "mediaPlay"; filled: true; size: 12; color: MusicColors.sidebarAccent }
                    }
                }
            }
        }
    }

    ColumnLayout {
        width: page.availableWidth - page.sidebarUnderlap - 48
        x: page.sidebarUnderlap + 24; spacing: 20
        Item { Layout.preferredHeight: Math.max(0, page.topContentInset - 20); visible: page.topContentInset > 0 }
        Label { visible: page.showHeading; text: Language.text("Discover", "发现"); color: AppTheme.text; font.pixelSize: 28; font.weight: Font.Bold }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 10; visible: page.signedIn
            SectionTitle {
                title: Language.text("Made for you", "为你推荐")
                subtitle: Language.text("A fresh daily selection for your NetEase account.", "来自你网易云账号的每日新推荐。")
            }
            SongSection { heading: Language.text("Your daily mix", "每日推荐歌曲"); section: "dailySongs"; limit: 4 }
            CoverShelf { Layout.topMargin: 10; heading: Language.text("Playlists for you", "为你推荐的歌单"); section: "dailyPlaylists"; state: page.feed("dailyPlaylists") }
        }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 10
            SectionTitle {
                title: Language.text("Find your next favorite", "遇见下一首心动")
                subtitle: Language.text("Explore playlists from NetEase Cloud Music.", "探索网易云音乐的歌单精选。")
            }
            FeedState { state: page.feed("playlists") }
            Flickable {
                id: featuredPlaylists
                readonly property real cardWidth: (width - 32) / 2.5
                readonly property real cardHeight: cardWidth * 0.75
                Layout.fillWidth: true; Layout.preferredHeight: cardHeight
                visible: page.feed("playlists").items.length > 0
                contentWidth: featuredRow.width; contentHeight: height
                clip: true; boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick
                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
                Row {
                    id: featuredRow; spacing: 16
                Repeater {
                    model: page.feed("playlists").items
                    delegate: AbstractButton {
                        id: feature
                        required property var modelData
                        required property int index
                        width: featuredPlaylists.cardWidth; height: featuredPlaylists.cardHeight
                        hoverEnabled: true
                        Accessible.name: modelData.title || ""
                        onClicked: page.collectionRequested("playlists", index)
                        background: Rectangle { radius: 12; color: MusicColors.placeholder }
                        contentItem: Item {
                            Artwork { anchors.fill: parent; source: modelData.artwork || ""; title: modelData.title || ""; radius: 12 }
                            Rectangle {
                                anchors.fill: parent; radius: 12
                                gradient: Gradient {
                                    GradientStop { position: 0; color: "#08000000" }
                                    GradientStop { position: .4; color: "#18000000" }
                                    GradientStop { position: 1; color: "#dd000000" }
                                }
                            }
                            Column {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 20; spacing: 8
                                Label { text: Language.text("PLAYLIST SPOTLIGHT", "歌单精选"); color: "#dddddd"; font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: 1 }
                                Label { width: parent.width; text: modelData.title || ""; color: "white"; font.pixelSize: 22; font.weight: Font.Bold; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight }
                                Label { width: parent.width; text: modelData.artist || Language.text("NetEase Cloud Music", "网易云音乐"); color: "#dddddd"; font.pixelSize: 11; elide: Text.ElideRight }
                            }
                            Rectangle { anchors.fill: parent; radius: 12; color: feature.hovered ? "#0cffffff" : "transparent"; border.width: feature.visualFocus ? 2 : 0; border.color: MusicColors.sidebarAccent }
                        }
                        padding: 0
                    }
                }
                }
            }
        }
        SongSection { heading: Language.text("New songs", "新歌速递"); section: "newSongs"; compact: true }
        CoverShelf { heading: Language.text("New releases", "新碟上架"); albums: true; state: ({items: page.music.discoveryAlbums, loading: page.music.discoveryLoading, error: page.music.discoveryError}) }
        CoverShelf { heading: Language.text("On the charts", "排行榜"); section: "charts"; state: page.feed("charts") }
        Item { Layout.preferredHeight: page.bottomContentInset + 16 }
    }
}
