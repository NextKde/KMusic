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
    ColumnLayout {
        anchors.fill: parent; spacing: 0
        WindowChrome { Layout.fillWidth: true; targetWindow: window }
        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 0
            Rectangle {
                id: sidebar
                Layout.preferredWidth: 240; Layout.fillHeight: true
                // Interim cleanup surface; the DesignReset QML underlay follows.
                color: AppTheme.sidebar
                ScrollView {
                    anchors.fill: parent; anchors.margins: 18; contentWidth: availableWidth; clip: true
                    ColumnLayout {
                        width: 204; spacing: 7
                        Label { text: "♫  Music"; font.pixelSize: 25; font.weight: Font.Bold; color: AppTheme.text; Layout.topMargin: 14; Layout.bottomMargin: 16 }
                        LiquidTextField {
                            id: search
                            Layout.fillWidth: true; materialForm: false; liquidFinish: true
                            placeholderText: qsTr("Search your library"); font.pixelSize: 13
                            onTextChanged: { if (text.length) { window.destination = "search"; window.pageTitle = qsTr("Search") }; music.setSearch(text) }
                        }
                        LiquidNavigationButton { Layout.fillWidth: true; text: qsTr("⌕   Search"); checked: window.destination === "search"; onClicked: { window.navigate("search", qsTr("Search")); search.forceActiveFocus() } }
                        LiquidNavigationButton { Layout.fillWidth: true; text: qsTr("▧   New"); checked: window.destination === "new"; onClicked: window.navigate("new") }
                        LiquidNavigationButton { Layout.fillWidth: true; text: qsTr("◎   Online · NetEase"); checked: window.destination === "online"; onClicked: window.navigate("online", qsTr("Online search")) }
                        Label { text: qsTr("LIBRARY"); color: AppTheme.mutedText; font.pixelSize: 10; font.weight: Font.DemiBold; Layout.topMargin: 24; Layout.leftMargin: 12 }
                        Repeater {
                            model: [{key:"songs", label:qsTr("♫   Songs")}, {key:"albums", label:qsTr("▣   Albums")}, {key:"artists", label:qsTr("♙   Artists")}]
                            delegate: LiquidNavigationButton {
                                required property var modelData
                                Layout.fillWidth: true; text: modelData.label; checked: window.destination === modelData.key
                                onClicked: window.navigate(modelData.key, modelData.label.slice(4))
                            }
                        }
                        LiquidNavigationButton { Layout.fillWidth: true; text: qsTr("≡   Play queue"); checked: window.destination === "queue"; onClicked: window.navigate("queue", qsTr("Play queue")) }
                        RowLayout {
                            Layout.fillWidth: true; Layout.topMargin: 22
                            Label { text: qsTr("PLAYLISTS"); color: AppTheme.mutedText; font.pixelSize: 10; font.weight: Font.DemiBold; Layout.fillWidth: true; Layout.leftMargin: 12 }
                            LiquidActionButton { iconOnly: true; text: "+"; implicitWidth: 30; flat: true; onClicked: playlistDialog.open(); Accessible.name: qsTr("New playlist") }
                        }
                        Repeater {
                            model: music.playlists
                            delegate: LiquidNavigationButton {
                                required property var modelData
                                Layout.fillWidth: true; text: "♫   " + modelData.name
                                checked: window.destination === "playlist" && window.selectedPlaylist === modelData.id
                                onClicked: { window.selectedPlaylist = modelData.id; music.selectPlaylist(modelData.id); window.destination = "playlist"; window.pageTitle = modelData.name }
                            }
                        }
                        Item { height: 24 }
                        LiquidActionButton { Layout.fillWidth: true; text: music.scanning ? qsTr("Scanning…") : qsTr("Import music folder"); enabled: !music.scanning; onClicked: folderDialog.open() }
                        LiquidSelect {
                            id: appearanceSelect
                            accentColor: AppTheme.accent
                            Layout.fillWidth: true; model: [qsTr("System"), qsTr("Light"), qsTr("Dark")]; materialForm: false
                            appearanceMode: AppTheme.appearanceMode; currentIndex: AppTheme.appearanceMode === "system" ? 0 : AppTheme.dark ? 2 : 1
                            onActivated: index => AppTheme.appearanceMode = ["system", "light", "dark"][index]
                        }
                    }
                }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: AppTheme.border }
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true
                color: AppTheme.window
                DiscoveryPage {
                    anchors.fill: parent; visible: window.destination === "new"; music: window.music
                    onImportRequested: folderDialog.open()
                    onFixtureRequested: title => { previewDialog.title = title; previewDialog.open() }
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
                        Label { text: window.destination === "artists" ? qsTr("Artists") : qsTr("Albums"); color: AppTheme.text; font.pixelSize: 32; font.weight: Font.Bold; Layout.topMargin: 24 }
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
            visible: music.errorMessage.length > 0 || music.scanning || music.providerStatus.length > 0
            Layout.fillWidth: true; implicitHeight: 34; color: AppTheme.card
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 24; anchors.rightMargin: 20
                Label { text: music.errorMessage || (music.scanning ? music.scanStatus : music.providerStatus); color: AppTheme.text; Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 12 }
                LiquidActionButton { iconOnly: true; visible: music.errorMessage.length > 0; text: "×"; implicitWidth: 30; implicitHeight: 26; onClicked: music.clearError() }
            }
        }
        PlayerBar { Layout.fillWidth: true; music: window.music; onQueueRequested: window.navigate("queue", qsTr("Play queue")); onNowPlayingRequested: window.destination = "now" }
    }
    KosWindowResizeHandles { targetWindow: window }
    FolderDialog { id: folderDialog; title: qsTr("Import music folder"); onAccepted: music.addLibraryFolder(selectedFolder.toString()) }
    LiquidDialog {
        id: previewDialog; anchors.centerIn: parent; width: 400; modal: true; standardButtons: Dialog.Ok
        contentItem: Label { text: qsTr("This is an original offline visual preview. It contains no playable audio. Import your music to start listening."); color: AppTheme.text; wrapMode: Text.WordWrap }
    }
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
