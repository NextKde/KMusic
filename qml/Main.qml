import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window
import Kos.Ui
ApplicationWindow {
    id: window
    required property var music
    width: 1280; height: 800; minimumWidth: 1024; minimumHeight: 640
    visible: true; title: "KMusic"; color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    property string destination: "new"
    property string pageTitle: qsTr("Songs")
    property double selectedPlaylist: -1
    property double pendingTrack: -1
    function reviewOnlineSearch(text) { destination = "online"; onlinePage.queryText = text; music.searchOnline(text) }
    function openReviewSelect(name) { if (name === "quality") { destination = "online"; onlinePage.openQualityMenu() } else appearanceSelect.openMenu() }
    function reviewMaterialAction(action, index) { destination = "now"; nowPlaying.reviewMaterialAction(action, index) }
    function materialReviewState() { return nowPlaying.materialReviewState() }
    function setReviewTheme(theme) { AppTheme.appearanceMode = theme }
    function toggleMaximized() { if (visibility === Window.Maximized) showNormal(); else showMaximized() }
    function toggleFullScreen() { if (visibility === Window.FullScreen) showNormal(); else showFullScreen() }
    function navigate(key, title) { destination = key; pageTitle = title || qsTr("Songs"); music.setSearch(""); music.setLibraryView("songs") }
    Component.onCompleted: { AppTheme.appearanceMode = "light"; AppTheme.accentName = "purple" }
    Shortcut { sequence: "Ctrl+O"; onActivated: folderDialog.open() }
    Shortcut { sequence: "Space"; enabled: !nowPlaying.ownsControlFocus(window.activeFocusItem) && !(window.activeFocusItem instanceof TextInput) && !(window.activeFocusItem instanceof TextEdit); onActivated: music.togglePlayPause() }
    Shortcut { sequence: "Ctrl+F"; onActivated: { window.navigate("search", qsTr("Search")); search.forceActiveFocus() } }
    Connections { target: music; function onRaiseRequested() { window.showNormal(); window.raise(); window.requestActivate() } }
    readonly property color shellColor: AppTheme.dark ? "#202326" : "#eff0f1"
    readonly property color contentColor: AppTheme.dark ? "#2a2d31" : "#e3e5e7"
    font.family: "Inter"; font.pixelSize: 13
    Item {
        id: appCanvas
        anchors.fill: parent
        // This is real current-track artwork inside the app scene, never desktop imagery.
        Item {
            id: artworkUnderlay
            anchors.fill: parent
            Rectangle { anchors.fill: parent; color: window.shellColor }
            Image {
                x: -110; y: 30; width: 650; height: parent.height - 114
                source: music.currentArtworkUrl; fillMode: Image.PreserveAspectCrop
                opacity: AppTheme.dark ? .32 : .22; asynchronous: true
            }
        }
        LiquidBackdrop { id: appBackdrop; sourceItem: artworkUnderlay; maximumTextureSize: 2048 }
        LiquidSurface {
            id: sidebarMaterial
            width: 236; height: parent.height - 84; radius: 0
            backdrop: appBackdrop; tintColor: window.shellColor
            tintStrength: .56; readability: .1; blurStrength: 3
            reflectionStrength: .25; refractionStrength: 2; magnification: 1.015
        }
        ScrollView {
            id: sidebar
            x: 0; y: 35; width: 236; height: parent.height - 84 - y
            contentWidth: availableWidth; clip: true
            ColumnLayout {
                width: 212; x: 12; spacing: 4
                RowLayout {
                    Layout.leftMargin: 10; Layout.topMargin: 8; Layout.bottomMargin: 14; spacing: 9
                    VectorIcon { name: "music"; size: 20; color: AppTheme.accent }
                    Label { text: "KMusic"; color: AppTheme.text; font.pixelSize: 16; font.weight: Font.DemiBold }
                }
                LiquidTextField {
                    id: search
                    Layout.fillWidth: true; Layout.bottomMargin: 10; implicitHeight: 30
                    materialForm: false; liquidFinish: true; placeholderText: qsTr("Search library"); font.pixelSize: 12
                    onTextChanged: { if (text.length) { window.destination = "search"; window.pageTitle = qsTr("Search") }; music.setSearch(text) }
                }
                LiquidNavigationButton { Layout.fillWidth: true; implicitHeight: 32; cornerRadius: 8; iconName: "sparkle"; text: qsTr("Discover"); checked: window.destination === "new"; onClicked: window.navigate("new") }
                LiquidNavigationButton { Layout.fillWidth: true; implicitHeight: 32; cornerRadius: 8; iconName: "search"; text: qsTr("Online search"); checked: window.destination === "online"; onClicked: window.navigate("online", qsTr("Online search")) }
                Label { text: qsTr("Library"); color: AppTheme.mutedText; font.pixelSize: 11; font.weight: Font.DemiBold; Layout.topMargin: 18; Layout.bottomMargin: 4; Layout.leftMargin: 10 }
                Repeater {
                    model: [{key:"songs", label:qsTr("Songs"), icon:"music"}, {key:"albums", label:qsTr("Albums"), icon:"album"}, {key:"artists", label:qsTr("Artists"), icon:"artist"}, {key:"queue", label:qsTr("Play queue"), icon:"queue"}]
                    delegate: LiquidNavigationButton {
                        required property var modelData
                        Layout.fillWidth: true; implicitHeight: 32; cornerRadius: 8
                        text: modelData.label; iconName: modelData.icon; checked: window.destination === modelData.key
                        onClicked: window.navigate(modelData.key, modelData.label)
                    }
                }
                RowLayout {
                    Layout.fillWidth: true; Layout.topMargin: 18; Layout.leftMargin: 10
                    Label { text: qsTr("Playlists"); color: AppTheme.mutedText; font.pixelSize: 11; font.weight: Font.DemiBold; Layout.fillWidth: true }
                    LiquidActionButton { iconOnly: true; iconName: "plus"; implicitWidth: 26; implicitHeight: 26; flat: true; onClicked: playlistDialog.open(); Accessible.name: qsTr("New playlist") }
                }
                Repeater {
                    model: music.playlists
                    delegate: LiquidNavigationButton {
                        required property var modelData
                        Layout.fillWidth: true; implicitHeight: 30; cornerRadius: 8; text: modelData.name; iconName: "music"
                        checked: window.destination === "playlist" && window.selectedPlaylist === modelData.id
                        onClicked: { window.selectedPlaylist = modelData.id; music.selectPlaylist(modelData.id); window.destination = "playlist"; window.pageTitle = modelData.name }
                    }
                }
                Item { implicitHeight: 18 }
                LiquidActionButton { Layout.fillWidth: true; implicitHeight: 30; text: music.scanning ? qsTr("Scanning…") : qsTr("Import music folder"); enabled: !music.scanning; onClicked: folderDialog.open() }
                LiquidSelect {
                    id: appearanceSelect
                    accentColor: AppTheme.accent; implicitHeight: 30
                    Layout.fillWidth: true; model: [qsTr("System appearance"), qsTr("Light appearance"), qsTr("Dark appearance")]; materialForm: false
                    appearanceMode: AppTheme.appearanceMode; currentIndex: AppTheme.appearanceMode === "system" ? 0 : AppTheme.dark ? 2 : 1
                    onActivated: index => AppTheme.appearanceMode = ["system", "light", "dark"][index]
                }
                Item { implicitHeight: 14 }
            }
        }
        Rectangle {
            x: 236; y: 0; width: parent.width - x; height: parent.height - 84
            color: window.contentColor
            Item {
                anchors.fill: parent; anchors.topMargin: 30
                DiscoveryPage {
                    anchors.fill: parent; visible: window.destination === "new"; music: window.music
                    onImportRequested: folderDialog.open()
                    onOnlineRequested: window.navigate("online", qsTr("Online search"))
                    onNowPlayingRequested: window.destination = "now"
                    onAlbumRequested: (filter, title) => { window.music.setLibraryView("album", filter); window.pageTitle = title; window.destination = "detail" }
                }
                SongsPage {
                    anchors.fill: parent
                    visible: ["songs", "search", "detail", "queue", "playlist"].indexOf(window.destination) >= 0
                    music: window.music; heading: window.pageTitle
                    queueView: window.destination === "queue"; playlistView: window.destination === "playlist"; playlistId: window.selectedPlaylist
                    trackModel: queueView ? music.queueModel : playlistView ? music.playlistTracksModel : music.libraryModel
                    onImportRequested: folderDialog.open()
                    onAddToPlaylistRequested: trackId => { window.pendingTrack = trackId; addDialog.open() }
                }
                ScrollView {
                    id: groupScroll
                    anchors.fill: parent; visible: window.destination === "albums" || window.destination === "artists"; contentWidth: availableWidth; clip: true
                    ColumnLayout {
                        width: groupScroll.availableWidth - 64; x: 32; spacing: 18
                        Label { text: window.destination === "artists" ? qsTr("Artists") : qsTr("Albums"); color: AppTheme.text; font.pixelSize: 26; font.weight: Font.Bold; Layout.topMargin: 24 }
                        Repeater {
                            model: window.destination === "artists" ? music.artists : music.albums
                            delegate: LiquidNavigationButton {
                                required property var modelData
                                Layout.fillWidth: true; text: modelData.name + " · " + modelData.count + qsTr(" songs")
                                onClicked: { music.setLibraryView(window.destination === "artists" ? "artist" : "album", modelData.filterValue); window.pageTitle = modelData.name; window.destination = "detail" }
                            }
                        }
                        Label { visible: (window.destination === "artists" ? music.artists : music.albums).length === 0; text: qsTr("Import a music folder to get started."); color: AppTheme.mutedText }
                    }
                }
                OnlinePage { id: onlinePage; anchors.fill: parent; visible: window.destination === "online"; music: window.music }
                NowPlaying { id: nowPlaying; anchors.fill: parent; visible: window.destination === "now"; music: window.music }
            }
        }
        Rectangle {
            anchors.bottom: player.top; width: parent.width; height: 28
            visible: music.errorMessage.length > 0 || music.scanning
            color: window.shellColor
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 18
                Label { text: music.errorMessage || music.scanStatus; color: AppTheme.text; Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 11 }
                LiquidActionButton { iconOnly: true; iconName: "close"; visible: music.errorMessage.length > 0; implicitWidth: 24; implicitHeight: 24; flat: true; onClicked: music.clearError() }
            }
        }
        PlayerBar { id: player; anchors.bottom: parent.bottom; width: parent.width; music: window.music; onQueueRequested: window.navigate("queue", qsTr("Play queue")); onNowPlayingRequested: window.destination = "now" }
        WindowChrome { width: parent.width; targetWindow: window }
    }
    KosWindowResizeHandles { targetWindow: window }
    FolderDialog { id: folderDialog; title: qsTr("Import music folder"); onAccepted: music.addLibraryFolder(selectedFolder.toString()) }
    LiquidDialog {
        id: playlistDialog; anchors.centerIn: parent; width: 360; modal: true; title: qsTr("New playlist"); standardButtons: Dialog.Ok | Dialog.Cancel
        contentItem: LiquidTextField { id: playlistName; placeholderText: qsTr("Playlist name"); materialForm: false; liquidFinish: true }
        onAccepted: { if (playlistName.text.trim()) music.createPlaylist(playlistName.text.trim()); playlistName.text = "" }
    }
    LiquidDialog {
        id: addDialog; anchors.centerIn: parent; width: 360; modal: true; title: qsTr("Add to playlist"); standardButtons: Dialog.Close
        contentItem: ColumnLayout {
            Label { visible: music.playlists.length === 0; text: qsTr("Create a playlist in the sidebar first."); color: AppTheme.text; wrapMode: Text.WordWrap }
            Repeater {
                model: music.playlists
                delegate: LiquidNavigationButton {
                    required property var modelData
                    Layout.fillWidth: true; text: modelData.name
                    onClicked: { music.addTrackToPlaylist(modelData.id, window.pendingTrack); addDialog.close() }
                }
            }
        }
    }
}
