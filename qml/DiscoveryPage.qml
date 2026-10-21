import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Kos.Ui
ScrollView {
    id: page
    required property var music
    signal importRequested()
    signal onlineRequested()
    signal nowPlayingRequested()
    signal albumRequested(string filter, string title)
    contentWidth: availableWidth; clip: true
    function homeOpticalState() {
        return { hovered: heroPlay.hovered, down: heroPlay.down, contentScale: heroPlay.scale,
            lensExpansion: heroPlay.opticalExpansion, refraction: heroPlay.opticalRefraction,
            magnification: heroPlay.opticalMagnification, reflection: heroPlay.opticalReflection,
            sampling: heroPlay.sampling, backdropAvailable: featureBackdrop.available }
    }
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
                color: "transparent"
                Item {
                    id: featureUnderlay
                    anchors.fill: parent
                    Rectangle { anchors.fill: parent; radius: 12; color: AppTheme.dark ? "#34383e" : "#f3f4f5" }
                    Image { id: featureArtwork; anchors.fill: parent; source: page.music.currentArtworkUrl; sourceSize: Qt.size(1024, 512); fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: false }
                    Rectangle { id: featureMask; anchors.fill: parent; radius: 12; color: "white"; visible: false; layer.enabled: true }
                    MultiEffect { anchors.fill: parent; source: featureArtwork; maskEnabled: true; maskSource: featureMask; blurEnabled: true; blurMax: 24; blur: .35; autoPaddingEnabled: false; opacity: AppTheme.dark ? .22 : .14 }
                }
                LiquidBackdrop { id: featureBackdrop; sourceItem: featureUnderlay; registerAsDefault: false }
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
                            LiquidActionButton { id: heroPlay; objectName: "reviewHeroPlay"; backdrop: featureBackdrop; text: page.music.currentTrackId > 0 ? qsTr("Listen now") : qsTr("Find music"); implicitHeight: 30; onClicked: page.music.currentTrackId > 0 ? page.music.togglePlayPause() : page.onlineRequested() }
                            LiquidActionButton { visible: page.music.currentTrackId > 0; iconOnly: true; iconName: "more"; implicitWidth: 30; implicitHeight: 30; flat: true; onClicked: page.nowPlayingRequested(); Accessible.name: qsTr("Now playing details") }
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true; spacing: 3
                Label { text: qsTr("New releases"); color: AppTheme.text; font.pixelSize: 17; font.weight: Font.DemiBold }
                Label { text: qsTr("NetEase · public new albums, not personalized"); color: AppTheme.mutedText; font.pixelSize: 11 }
            }
            LiquidActionButton { text: page.music.discoveryLoading ? qsTr("Loading…") : page.music.discoveryError.length ? qsTr("Retry") : qsTr("Refresh"); implicitHeight: 30; enabled: !page.music.discoveryLoading; onClicked: page.music.reloadDiscovery() }
        }
        Label { visible: page.music.discoveryLoading || page.music.discoveryError.length > 0; text: page.music.discoveryLoading ? qsTr("Loading new albums from NetEase…") : page.music.discoveryError; color: page.music.discoveryError.length ? AppTheme.destructive : AppTheme.mutedText; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        Flickable {
            id: releases
            Layout.fillWidth: true; Layout.preferredHeight: 178
            visible: page.music.discoveryAlbums.length > 0
            clip: true; contentWidth: releaseRow.width; contentHeight: height
            boundsBehavior: Flickable.StopAtBounds; flickableDirection: Flickable.HorizontalFlick
            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
            Row {
                id: releaseRow; spacing: 18
                Repeater {
                    model: page.music.discoveryAlbums
                    delegate: AlbumTile {
                        required property var modelData
                        required property int index
                        width: 128; title: modelData.title; subtitle: modelData.artist; artwork: modelData.artwork
                        onClicked: page.music.playDiscoveryAlbum(index)
                    }
                }
            }
        }
        Label { visible: page.music.discoveryAlbums.length > 0; text: page.music.discoveryPlaying ? qsTr("Loading album tracks…") : qsTr("Select an album to play. Preview and account restrictions may apply."); color: AppTheme.mutedText; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
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
