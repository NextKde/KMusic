import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
Item {
    id: page
    required property var music
    property real bottomContentInset: 0
    property alias filterText: search.text
    signal backRequested()
    readonly property var reviewList: music.artistAlbumsVisible ? artistAlbums : songs.reviewList
    property string displayedAlbumId: ""
    Connections {
        target: page.music
        function onOnlineAlbumChanged() {
            const id = String(page.music.onlineAlbum.kind || "album") + ":" + String(page.music.onlineAlbum.providerId || "")
            if (id !== page.displayedAlbumId) { page.displayedAlbumId = id; search.text = "" }
        }
    }
    readonly property bool artistView: music.onlineAlbum.kind === "artist"
    readonly property bool playlistView: music.onlineAlbum.kind === "playlist"
    readonly property bool partial: music.onlineAlbum.partial === true
    readonly property bool albumReady: !music.albumLoading && !music.albumError.length && (music.onlineAlbum.trackCount || 0) > 0
    Item {
        id: albumScrollScene
        anchors.fill: parent
        Rectangle { anchors.fill: parent; color: AppTheme.dark ? "#1c1c1e" : "#ffffff" }
    SongsPage {
        id: songs
        anchors.fill: parent
        music: page.music; trackModel: page.music.albumTracksModel
        showHeading: false; albumView: true; bottomContentInset: page.bottomContentInset
        emptyMessage: page.music.albumLoading ? (page.artistView ? qsTr("Loading popular songs…") : page.playlistView ? qsTr("Loading playlist…") : qsTr("Loading album…")) : page.music.albumError || (search.text.length ? qsTr("No matching songs") : qsTr("No songs available"))
        visible: !page.music.artistAlbumsVisible
        headerContent: detailHeader
    }
    CollectionList {
        id: artistAlbums
        anchors.fill: parent; visible: page.music.artistAlbumsVisible
        rows: page.music.artistAlbums; headerContent: detailHeader
        firstControlName: "reviewArtistAlbumFirst"; bottomContentInset: page.bottomContentInset
        emptyMessage: page.music.artistAlbumsLoading ? qsTr("Loading albums…") : page.music.artistAlbumsError || qsTr("No albums available from NetEase")
        onActivated: row => page.music.openArtistAlbum(row)
    }
    }
    Component {
        id: detailHeader
            Item {
                implicitHeight: 320
                RowLayout {
                    x: 32; y: 64; width: parent.width - 64; height: 218; spacing: 24
                    Artwork { Layout.preferredWidth: 184; Layout.preferredHeight: 184; source: page.music.onlineAlbum.artwork || ""; title: page.music.onlineAlbum.title || ""; radius: 9 }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 8
                        Label { text: page.music.onlineAlbum.title || qsTr("Album"); color: AppTheme.text; font.pixelSize: 26; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
                        Label { text: page.playlistView ? qsTr("By %1").arg(page.music.onlineAlbum.artist || "") : page.music.onlineAlbum.artist || ""; color: MusicColors.sidebarAccent; font.pixelSize: 18; Layout.fillWidth: true; elide: Text.ElideRight }
                        Label {
                            text: page.artistView ? qsTr("NetEase · %1 popular songs loaded").arg(page.music.onlineAlbum.trackCount || 0) + (page.music.onlineAlbum.catalogueTrackCount > 0 ? qsTr(" · %1 catalogue songs").arg(page.music.onlineAlbum.catalogueTrackCount) : "") : "NetEase" + (page.music.onlineAlbum.publishTime ? " · " + new Date(Number(page.music.onlineAlbum.publishTime)).getFullYear() : "") + (page.music.onlineAlbum.trackCount !== undefined ? " · " + (page.partial ? qsTr("%1 of %2 songs loaded").arg(page.music.onlineAlbum.trackCount).arg(page.music.onlineAlbum.totalCount) : page.music.onlineAlbum.trackCount === 1 ? qsTr("1 song") : qsTr("%1 songs").arg(page.music.onlineAlbum.trackCount)) : "")
                            color: AppTheme.mutedText; font.pixelSize: 11
                        }
                        Label { text: page.music.onlineAlbum.description || ""; visible: text.length > 0; color: AppTheme.mutedText; font.pixelSize: 11; wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight; Layout.fillWidth: true }
                        RowLayout {
                            visible: !page.music.artistAlbumsVisible
                            spacing: 10
                            MusicActionButton { objectName: "reviewAlbumPlay"; text: page.artistView ? qsTr("Play popular songs") : page.partial ? qsTr("Play loaded songs") : page.playlistView ? qsTr("Play playlist") : qsTr("Play album"); iconName: ""; textColor: MusicColors.sidebarAccent; surfaceColor: MusicColors.rowFill; enabled: page.albumReady; onClicked: page.music.playOnlineAlbum() }
                            MusicActionButton { objectName: "reviewAlbumQueue"; text: page.artistView ? qsTr("Queue popular songs") : page.partial ? qsTr("Queue loaded songs") : qsTr("Add to queue"); surfaceColor: MusicColors.rowFill; enabled: page.albumReady; onClicked: page.music.enqueueOnlineAlbum() }
                        }
                    }
                }
                Label {
                    x: 32; y: 292; width: parent.width - 64; elide: Text.ElideRight; font.pixelSize: 11
                    text: page.music.artistAlbumsVisible ? (page.music.artistAlbumsError || qsTr("%1 albums loaded").arg(page.music.artistAlbums.length) + (page.music.artistAlbumsTotal > 0 ? qsTr(" of %1").arg(page.music.artistAlbumsTotal) : "")) : page.music.albumLoadMoreError || page.music.albumMessage || (page.artistView ? qsTr("Popular songs from NetEase, not all works. Playback depends on track permissions.") : page.music.albumLoadingMore ? qsTr("Loading more songs…") : page.partial ? (page.music.onlineAlbum.hasMore ? qsTr("More songs are available. Play and queue actions use the loaded songs.") : qsTr("Some song metadata is unavailable from NetEase. Play and queue actions use the loaded songs.")) : qsTr("Playback depends on account and track permissions. Previews are labelled when available."))
                    color: AppTheme.mutedText
                }
            }
        }
    // The fixed toolbar is the only page overlay glass; its source is the real
    // scrolling list/header sibling, never a second catalogue or the toolbar.
    LiquidBackdrop { id: toolbarBackdrop; sourceItem: albumScrollScene; registerAsDefault: false; blur: .15 }
    Item {
        width: parent.width; height: 48
        LiquidSurface { anchors.fill: parent; radius: 0; backdrop: toolbarBackdrop; tintColor: AppTheme.dark ? "#1c1c1e" : "#ffffff"; tintStrength: .84; readability: 0; blurStrength: 0; refractionStrength: 2; reflectionStrength: .2 }
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 24; anchors.rightMargin: 24; spacing: 12
            MusicActionButton { iconOnly: true; iconName: "back"; flat: true; implicitWidth: 30; implicitHeight: 30; objectName: "reviewAlbumBack"; onClicked: { if (page.music.artistParentAvailable) page.music.restoreArtistDetails(); else page.backRequested() } Accessible.name: qsTr("Back") }
            Label { text: page.music.onlineAlbum.title || qsTr("Album"); color: AppTheme.text; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
            MusicActionButton {
                objectName: "reviewArtistAlbums"
                visible: page.artistView
                text: page.music.artistAlbumsVisible ? qsTr("Popular songs") : qsTr("Albums")
                enabled: !page.music.albumLoading && !page.music.albumError.length
                onClicked: { if (page.music.artistAlbumsVisible) page.music.showArtistPopularSongs(); else page.music.showArtistAlbums() }
            }
            MusicActionButton {
                objectName: "reviewArtistAlbumsMore"
                visible: page.artistView && page.music.artistAlbumsVisible && (page.music.artistAlbumsMore || page.music.artistAlbumsError.length)
                text: page.music.artistAlbumsLoading ? qsTr("Loading…") : page.music.artistAlbumsError.length ? qsTr("Retry albums") : qsTr("More albums")
                enabled: !page.music.artistAlbumsLoading
                onClicked: page.music.loadMoreArtistAlbums()
            }
            MusicActionButton {
                objectName: "reviewAlbumMore"
                visible: page.playlistView && page.music.onlineAlbum.hasMore === true
                text: page.music.albumLoadingMore ? qsTr("Loading…") : page.music.albumLoadMoreError.length ? qsTr("Retry more") : qsTr("Load more")
                enabled: !page.music.albumLoadingMore && !page.music.albumLoading
                onClicked: page.music.loadMorePlaylistTracks()
            }
            MusicActionButton { objectName: "reviewAlbumRetry"; visible: page.music.albumError.length > 0; text: qsTr("Retry"); onClicked: page.music.retryOnlineAlbum() }
            LiquidTextField {
                id: search
                visible: !page.music.artistAlbumsVisible
                Layout.preferredWidth: Math.min(210, page.width * .28); implicitHeight: 30
                materialForm: true; placeholderText: page.artistView ? qsTr("Find in popular songs") : page.playlistView ? qsTr("Find in playlist") : qsTr("Find in album"); font.pixelSize: 12
                onTextChanged: page.music.albumTracksModel.search = text
            }
        }
    }
}
