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
        width: page.availableWidth - 56; x: 28; spacing: 20
        Label { text: qsTr("Discover"); color: AppTheme.text; font.pixelSize: 26; font.weight: Font.Bold; Layout.topMargin: 14 }
        RowLayout {
            Layout.fillWidth: true; spacing: 20
            ColumnLayout {
                Layout.fillWidth: true; Layout.preferredWidth: 3; spacing: 6
                Label { text: qsTr("CONTINUE LISTENING"); color: AppTheme.mutedText; font.pixelSize: 10; font.weight: Font.DemiBold }
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 222; radius: 12
                    color: AppTheme.dark ? "#34383e" : "#f3f4f5"
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 20
                        Artwork { source: page.music.currentArtworkUrl; title: page.music.currentTitle; Layout.preferredWidth: Math.min(174, page.width * .18); Layout.preferredHeight: Math.min(174, page.width * .18); radius: 8 }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 9
                            Label { text: page.music.currentTitle || qsTr("Your next favourite"); color: AppTheme.text; font.pixelSize: 22; font.weight: Font.Bold; Layout.fillWidth: true; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight }
                            Label { text: page.music.currentArtist || qsTr("Find a song, or bring your collection."); color: AppTheme.mutedText; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                            Label { text: page.music.currentAlbum; visible: text.length > 0; color: AppTheme.mutedText; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                            Item { Layout.fillHeight: true }
                            LiquidActionButton { id: heroPlay; objectName: "reviewHeroPlay"; text: page.music.currentTrackId > 0 ? qsTr("Listen now") : qsTr("Find music"); implicitHeight: 32; onClicked: page.music.currentTrackId > 0 ? page.music.togglePlayPause() : page.onlineRequested() }
                        }
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true; Layout.preferredWidth: 2; spacing: 6
                Label { text: qsTr("EXPLORE MUSIC"); color: AppTheme.mutedText; font.pixelSize: 10; font.weight: Font.DemiBold }
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 222; radius: 12
                    color: AppTheme.dark ? "#34383e" : "#f3f4f5"
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 22; spacing: 10
                        VectorIcon { name: "search"; size: 26; color: AppTheme.accent }
                        Label { text: qsTr("Find your sound"); font.pixelSize: 22; font.weight: Font.Bold; color: AppTheme.text; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                        Label { text: qsTr("Search NetEase Music for songs and artists. Availability and previews depend on the source."); font.pixelSize: 12; color: AppTheme.mutedText; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                        Item { Layout.fillHeight: true }
                        LiquidActionButton { text: qsTr("Search music"); implicitHeight: 32; onClicked: page.onlineRequested() }
                    }
                }
            }
        }
        ColumnLayout {
            visible: page.music.currentTrackId > 0; Layout.fillWidth: true; spacing: 10
            Label { text: qsTr("Recently selected"); color: AppTheme.text; font.pixelSize: 17; font.weight: Font.DemiBold }
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Artwork { source: page.music.currentArtworkUrl; title: page.music.currentTitle; Layout.preferredWidth: 44; Layout.preferredHeight: 44; radius: 6 }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 4
                    Label { text: page.music.currentTitle; color: AppTheme.text; font.pixelSize: 13 }
                    Label { text: page.music.providerStatus || page.music.currentArtist; color: AppTheme.mutedText; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                }
                LiquidActionButton { iconOnly: true; iconName: "more"; implicitWidth: 32; implicitHeight: 32; flat: true; onClicked: page.nowPlayingRequested(); Accessible.name: qsTr("Now playing details") }
            }
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: AppTheme.border }
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
                    Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.maximumWidth: 184
                    title: modelData.name; subtitle: modelData.subtitle; artwork: modelData.artworkUrl
                    onClicked: page.albumRequested(modelData.filterValue, modelData.name)
                }
            }
            Item { Layout.fillWidth: true; visible: page.music.albums.length < 4 }
        }
        Label { visible: page.music.albums.length === 0; text: qsTr("No imported albums yet. Add a music folder to build your library."); color: AppTheme.mutedText; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        Item { implicitHeight: 20 }
    }
}
