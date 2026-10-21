import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
ScrollView {
    id: page
    required property var music
    signal importRequested()
    signal onlineRequested()
    signal nowPlayingRequested()
    signal albumRequested(string filter, string title)
    contentWidth: availableWidth; clip: true
    ColumnLayout {
        width: page.availableWidth - 56; x: 28; spacing: 18
        RowLayout {
            Layout.fillWidth: true; Layout.topMargin: 14
            Label { text: qsTr("Discover"); color: AppTheme.text; font.pixelSize: 26; font.weight: Font.Bold; Layout.fillWidth: true }
            LiquidActionButton { text: qsTr("Search music"); implicitHeight: 30; onClicked: page.onlineRequested() }
        }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 6
            Label { text: page.music.currentTrackId > 0 ? qsTr("CONTINUE LISTENING") : qsTr("YOUR MUSIC"); color: AppTheme.mutedText; font.pixelSize: 10; font.weight: Font.DemiBold }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 164; radius: 12
                color: AppTheme.dark ? "#34383e" : "#f3f4f5"
                RowLayout {
                    anchors.fill: parent; anchors.margins: 20; spacing: 20
                    Artwork { source: page.music.currentArtworkUrl; title: page.music.currentTitle; Layout.preferredWidth: 124; Layout.preferredHeight: 124; radius: 8 }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 7
                        Label { text: page.music.currentTitle || qsTr("Make room for music"); color: AppTheme.text; font.pixelSize: 22; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
                        Label { text: page.music.currentArtist || qsTr("Find a song online or import your collection."); color: AppTheme.mutedText; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                        Label { text: page.music.providerStatus || page.music.currentAlbum; color: AppTheme.mutedText; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight; ToolTip.text: text; ToolTip.visible: statusHover.hovered; HoverHandler { id: statusHover } }
                        Item { Layout.fillHeight: true }
                        RowLayout {
                            LiquidActionButton { id: heroPlay; objectName: "reviewHeroPlay"; text: page.music.currentTrackId > 0 ? qsTr("Listen now") : qsTr("Find music"); implicitHeight: 30; onClicked: page.music.currentTrackId > 0 ? page.music.togglePlayPause() : page.onlineRequested() }
                            LiquidActionButton { visible: page.music.currentTrackId > 0; iconOnly: true; iconName: "more"; implicitWidth: 30; implicitHeight: 30; flat: true; onClicked: page.nowPlayingRequested(); Accessible.name: qsTr("Now playing details") }
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Label { text: qsTr("Albums from your library"); color: AppTheme.text; font.pixelSize: 17; font.weight: Font.DemiBold; Layout.fillWidth: true }
            LiquidActionButton { text: qsTr("Import music"); implicitHeight: 30; onClicked: page.importRequested() }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 18
            Repeater {
                model: page.music.albums.slice(0, 4)
                delegate: AlbumTile {
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.maximumWidth: 144
                    title: modelData.name; subtitle: modelData.subtitle; artwork: modelData.artworkUrl
                    onClicked: page.albumRequested(modelData.filterValue, modelData.name)
                }
            }
            Item { Layout.fillWidth: true; visible: page.music.albums.length < 4 }
        }
        Label { visible: page.music.albums.length === 0; text: qsTr("No albums yet. Add a music folder to build your library."); color: AppTheme.mutedText; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        Item { implicitHeight: 16 }
    }
}
