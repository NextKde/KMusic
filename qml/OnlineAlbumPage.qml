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
    readonly property alias reviewList: songs.reviewList
    property string displayedAlbumId: ""
    Connections {
        target: page.music
        function onOnlineAlbumChanged() {
            const id = String(page.music.onlineAlbum.providerId || "")
            if (id !== page.displayedAlbumId) { page.displayedAlbumId = id; search.text = "" }
        }
    }
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
        emptyMessage: page.music.albumLoading ? qsTr("Loading album…") : page.music.albumError || (search.text.length ? qsTr("No matching songs in this album") : qsTr("No songs available in this album"))
        headerContent: Component {
            Item {
                implicitHeight: 320
                RowLayout {
                    x: 32; y: 64; width: parent.width - 64; height: 218; spacing: 24
                    Artwork { Layout.preferredWidth: 184; Layout.preferredHeight: 184; source: page.music.onlineAlbum.artwork || ""; title: page.music.onlineAlbum.title || ""; radius: 9 }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 8
                        Label { text: page.music.onlineAlbum.title || qsTr("Album"); color: AppTheme.text; font.pixelSize: 26; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
                        Label { text: page.music.onlineAlbum.artist || ""; color: MusicColors.sidebarAccent; font.pixelSize: 18; Layout.fillWidth: true; elide: Text.ElideRight }
                        Label {
                            text: "NetEase" + (page.music.onlineAlbum.publishTime ? " · " + new Date(Number(page.music.onlineAlbum.publishTime)).getFullYear() : "") + (page.music.onlineAlbum.trackCount !== undefined ? " · " + (page.music.onlineAlbum.trackCount === 1 ? qsTr("1 song") : qsTr("%1 songs").arg(page.music.onlineAlbum.trackCount)) : "")
                            color: AppTheme.mutedText; font.pixelSize: 11
                        }
                        Label { text: page.music.onlineAlbum.description || ""; visible: text.length > 0; color: AppTheme.mutedText; font.pixelSize: 11; wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight; Layout.fillWidth: true }
                        RowLayout {
                            spacing: 10
                            MusicActionButton { objectName: "reviewAlbumPlay"; text: qsTr("Play album"); iconName: ""; textColor: MusicColors.sidebarAccent; surfaceColor: MusicColors.rowFill; enabled: page.albumReady; onClicked: page.music.playOnlineAlbum() }
                            MusicActionButton { objectName: "reviewAlbumQueue"; text: qsTr("Add album to queue"); surfaceColor: MusicColors.rowFill; enabled: page.albumReady; onClicked: page.music.enqueueOnlineAlbum() }
                        }
                    }
                }
                Label {
                    x: 32; y: 292; width: parent.width - 64; elide: Text.ElideRight; font.pixelSize: 11
                    text: page.music.albumMessage || qsTr("Playback depends on account and track permissions. Previews are labelled when available.")
                    color: AppTheme.mutedText
                }
            }
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
            MusicActionButton { iconOnly: true; iconName: "back"; flat: true; implicitWidth: 30; implicitHeight: 30; onClicked: page.backRequested(); Accessible.name: qsTr("Back to discovery") }
            Label { text: page.music.onlineAlbum.title || qsTr("Album"); color: AppTheme.text; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
            MusicActionButton { objectName: "reviewAlbumRetry"; visible: page.music.albumError.length > 0; text: qsTr("Retry"); onClicked: page.music.retryOnlineAlbum() }
            LiquidTextField {
                id: search
                Layout.preferredWidth: Math.min(210, page.width * .28); implicitHeight: 30
                materialForm: true; placeholderText: qsTr("Find in album"); font.pixelSize: 12
                onTextChanged: page.music.albumTracksModel.search = text
            }
        }
    }
}
