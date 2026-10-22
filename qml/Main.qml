import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Kos.Ui
ApplicationWindow {
    id: window
    required property var music
    width: 1100; height: 680; minimumWidth: 1024; minimumHeight: 640
    visible: true; title: "KMusic"; color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    property string destination: "new"
    property string lastContentDestination: "new"
    property string collectionReturnDestination: "new"
    property Item focusBeforeNow: null
    onDestinationChanged: {
        if (destination !== "now") lastContentDestination = destination
        else if (window.activeFocusItem && window.activeFocusItem !== nowPlaying)
            focusBeforeNow = window.activeFocusItem
    }
    function closeNowPlaying() {
        destination = lastContentDestination
        if (focusBeforeNow && focusBeforeNow.visible && focusBeforeNow.enabled)
            focusBeforeNow.forceActiveFocus(Qt.OtherFocusReason)
        else discoverNav.forceActiveFocus(Qt.OtherFocusReason)
    }
    property string pageTitle: qsTr("Songs")
    property double selectedPlaylist: -1
    readonly property bool sensitiveContentVisible: accountDialog.visible && (music.account.qrImage.length > 0 || music.account.authenticated)
    property int sensitiveContentRevision: 0
    onSensitiveContentVisibleChanged: if (sensitiveContentVisible) ++sensitiveContentRevision
    function openPlaylistPicker(source, rowOrId) { if (music.preparePlaylistTrack(source, rowOrId)) addDialog.open() }
    function reviewClosePlaylistPicker() { addDialog.reject() }
    function reviewPlaylistName(text) { newPlaylistName.text = text }
    function reviewOpenLocalPlaylist(row) {
        if (row < 0 || row >= music.playlists.length) return
        const entry = music.playlists[row]; window.selectedPlaylist = entry.id; music.selectPlaylist(entry.id)
        window.destination = "playlist"; window.pageTitle = entry.name
    }
    function openAccount() { accountDialog.open() }
    function reviewOnlineSearch(text) { music.onlineSearchKind = "song"; destination = "online"; onlinePage.queryText = text; music.searchOnline(text) }
    function openReviewSelect(name) { if (name === "quality") { destination = "online"; onlinePage.openQualityMenu() } else settingsMenu.popup() }
    function reviewMaterialAction(action, index) { destination = "now"; nowPlaying.reviewMaterialAction(action, index) }
    function materialReviewState() {
        const state = JSON.parse(nowPlaying.materialReviewState())
        state.homeButton = discover.homeOpticalState()
        state.playerControls = player.reviewState()
        state.navigation = { selected: discoverNav.checked, hovered: discoverNav.hovered, visualFocus: discoverNav.visualFocus }
        state.playerPanel = { sampling: player.sampling, backdropAvailable: playerBackdrop.available,
            source: playerBackdrop.sourceItem.objectName, x: player.x, y: player.y, width: player.width, height: player.height,
            radius: player.radius, bottomInset: window.playerContentInset }
        state.sidebarSampling = sidebarMaterial.sampling
        state.sidebarSource = sidebarBackdrop.sourceItem.objectName
        state.sidebarTint = sidebarMaterial.tintStrength
        state.appBackdropAvailable = appBackdrop.available
        state.underlay = "single real contentScene; original hidden, raw right proxy plus sampled sidebar"
        return JSON.stringify(state)
    }
    function reviewAlbumFilter(text) { albumPage.filterText = text }
    function reviewOnlineAlbum(row) { collectionReturnDestination = "new"; music.openDiscoveryAlbum(row); destination = "onlineAlbum" }
    function reviewCollectionSearch(text, kind) { destination = "online"; music.onlineSearchKind = kind; onlinePage.queryText = text; music.searchOnline(text) }
    function openCollection(row) { collectionReturnDestination = "online"; music.openOnlineCollection(row); destination = "onlineAlbum" }
    function reviewReleaseScroll(fraction) { return discover.scrollReleaseReview(fraction) }
    function reviewScroll(fraction) {
        const view = window.destination === "new" ? discover.contentItem : window.destination === "onlineAlbum" ? albumPage.reviewList : window.destination === "online" ? onlinePage.reviewList : songsPage.reviewList
        view.contentY = Math.max(0, view.contentHeight - view.height) * Math.max(0, Math.min(1, fraction))
        return JSON.stringify({ contentY: view.contentY, contentHeight: view.contentHeight, viewportHeight: view.height,
            bottomInset: window.playerContentInset })
    }
    function setReviewTheme(theme) { AppTheme.appearanceMode = theme }
    function toggleMaximized() { if (visibility === Window.Maximized) showNormal(); else showMaximized() }
    function toggleFullScreen() { if (visibility === Window.FullScreen) showNormal(); else showFullScreen() }
    function navigate(key, title) { destination = key; pageTitle = title || qsTr("Songs"); music.setSearch(""); music.setLibraryView("songs") }
    Component.onCompleted: { AppTheme.appearanceMode = "light" }
    Shortcut { sequence: "Ctrl+O"; onActivated: folderDialog.open() }
    Shortcut { sequence: "Space"; enabled: !nowPlaying.ownsControlFocus(window.activeFocusItem) && !(window.activeFocusItem instanceof TextInput) && !(window.activeFocusItem instanceof TextEdit); onActivated: music.togglePlayPause() }
    Shortcut { sequence: "Ctrl+F"; onActivated: { window.navigate("search", qsTr("Search")); search.forceActiveFocus() } }
    Connections {
        target: music
        function onRaiseRequested() { window.showNormal(); window.raise(); window.requestActivate() }
        function onPreparedPlaylistTrackSaved() { addDialog.close() }
    }
    readonly property real playerContentInset: player.height + 32 + (music.errorMessage.length > 0 || music.scanning ? 36 : 0)
    readonly property color shellColor: AppTheme.dark ? "#242426" : "#f2f2f4"
    readonly property color contentColor: AppTheme.dark ? "#1c1c1e" : "#ffffff"
    font.family: "Inter"; font.pixelSize: 13
    Item {
        id: appCanvas
        anchors.fill: parent
        Item {
            id: pageScene
            objectName: "musicPageScene"
            visible: window.destination !== "now"
            anchors.fill: parent
        Item {
            id: contentScene
            objectName: "realMusicContentScene"
            anchors.fill: parent; clip: true
        // A legal independent colour source for ordinary controls. It does not
        // contain consumers and never supplies desktop or clamped cover imagery.
        Rectangle {
            id: controlUnderlay
            x: 236; y: 0; width: parent.width - x; height: parent.height
            color: window.contentColor
        }
        LiquidBackdrop { id: appBackdrop; sourceItem: controlUnderlay; maximumTextureSize: 2048 }
        Rectangle {
            x: 236; y: 0; width: parent.width - x; height: parent.height
            color: window.contentColor
            Item {
                anchors.fill: parent; anchors.topMargin: 30
                DiscoveryPage {
                    id: discover
                    bottomContentInset: window.playerContentInset
                    sidebarUnderlap: 236
                    x: -236; y: 0; width: parent.width + 236; height: parent.height
                    visible: window.destination === "new"; music: window.music
                    onImportRequested: folderDialog.open()
                    onOnlineRequested: window.navigate("online", qsTr("Online search"))
                    onOnlineAlbumRequested: row => window.reviewOnlineAlbum(row)
                    onNowPlayingRequested: window.destination = "now"
                    onAlbumRequested: (filter, title) => { window.music.setLibraryView("album", filter); window.pageTitle = title; window.destination = "detail" }
                }
                SongsPage {
                    id: songsPage
                    anchors.fill: parent
                    visible: ["songs", "search", "detail", "queue", "playlist", "favorites", "recent"].indexOf(window.destination) >= 0
                    music: window.music; bottomContentInset: window.playerContentInset; heading: window.pageTitle
                    emptyMessage: recentView ? qsTr("Your playback history on this device is empty. Played songs will appear here.") : favoritesView ? qsTr("Your favorites on this device are empty. Add songs using the heart button.") : queueView ? qsTr("Your queue is empty") : qsTr("No songs here yet")
                    queueView: window.destination === "queue"; recentView: window.destination === "recent"; favoritesView: window.destination === "favorites"; playlistView: window.destination === "playlist"; playlistId: window.selectedPlaylist
                    trackModel: recentView ? music.recentModel : favoritesView ? music.favoritesModel : queueView ? music.queueModel : playlistView ? music.playlistTracksModel : music.libraryModel
                    onImportRequested: folderDialog.open()
                    onAddToPlaylistRequested: trackId => window.openPlaylistPicker("library", trackId)
                }
                ScrollView {
                    id: groupScroll
                    anchors.fill: parent; visible: window.destination === "albums" || window.destination === "artists"; contentWidth: availableWidth; clip: true
                    ColumnLayout {
                        width: groupScroll.availableWidth - 64; x: 32; spacing: 18
                        Label { text: window.destination === "artists" ? qsTr("Artists") : qsTr("Albums"); color: AppTheme.text; font.pixelSize: 26; font.weight: Font.Bold; Layout.topMargin: 24 }
                        Repeater {
                            model: window.destination === "artists" ? music.artists : music.albums
                            delegate: MusicNavigationButton {
                                required property var modelData
                                Layout.fillWidth: true; text: modelData.name + " · " + modelData.count + qsTr(" songs")
                                onClicked: { music.setLibraryView(window.destination === "artists" ? "artist" : "album", modelData.filterValue); window.pageTitle = modelData.name; window.destination = "detail" }
                            }
                        }
                        Label { visible: (window.destination === "artists" ? music.artists : music.albums).length === 0; text: qsTr("Import a music folder to get started."); color: AppTheme.mutedText }
                        Item { Layout.preferredHeight: window.playerContentInset; Layout.fillWidth: true }
                    }
                }
                OnlineAlbumPage { id: albumPage; anchors.fill: parent; visible: window.destination === "onlineAlbum"; music: window.music; bottomContentInset: window.playerContentInset; onBackRequested: window.destination = window.collectionReturnDestination; onSaveToPlaylistRequested: row => window.openPlaylistPicker("album", row) }
                OnlinePage { id: onlinePage; bottomContentInset: window.playerContentInset; anchors.fill: parent; visible: window.destination === "online"; music: window.music; onCollectionRequested: row => window.openCollection(row); onSaveToPlaylistRequested: row => window.openPlaylistPicker("online", row) }
            }
        }
        Rectangle {
            x: 252; y: parent.height - window.playerContentInset - 28
            width: parent.width - x - 16; height: 28
            visible: music.errorMessage.length > 0 || music.scanning
            color: window.shellColor
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 18
                Label { text: music.errorMessage || music.scanStatus; color: AppTheme.text; Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 11 }
                MusicActionButton { iconOnly: true; iconName: "close"; visible: music.errorMessage.length > 0; implicitWidth: 24; implicitHeight: 24; flat: true; onClicked: music.clearError() }
            }
        }
        }
        // One actual content instance; hide its direct paint so no clear tile
        // can bleed through the refracted copy in the sidebar.
        LiquidBackdrop {
            id: sidebarBackdrop
            sourceItem: contentScene; hideSource: true; registerAsDefault: false
            blur: .45; maximumTextureSize: 2560
        }
        // Display the content crop directly, without a full-page optical
        // surface or antialiased material boundary at the sidebar join.
        Item {
            x: 236; y: 0; width: parent.width - x; height: parent.height
            Rectangle { anchors.fill: parent; color: window.contentColor }
            ShaderEffectSource {
                anchors.fill: parent
                sourceItem: contentScene
                sourceRect: Qt.rect(236, 0, parent.width, parent.height)
                hideSource: true
                live: true
                recursive: false
                smooth: true
            }
        }
        // Back only the antialiased joining pixel so it cannot expose desktop.
        Rectangle {
            x: 235; y: 0; width: 1; height: parent.height
            color: window.shellColor
        }
        LiquidSurface {
            id: sidebarMaterial
            width: 236; height: parent.height; radius: 0
            backdrop: sidebarBackdrop
            tintColor: window.shellColor
            tintStrength: .95
            diffuseStrength: 0; readability: 0
            blurStrength: .15
            refractionStrength: 5; magnification: 1.025
            reflectionStrength: 0
        }
        ColumnLayout {
            id: sidebarShell
            x: 0; y: 35; width: 236; height: parent.height - y
            spacing: 0
            ScrollView {
                id: sidebar
                Layout.fillWidth: true; Layout.fillHeight: true
                contentWidth: availableWidth; clip: true
                ColumnLayout {
                    width: sidebar.availableWidth - 2 * MusicColors.sidebarPadding
                    x: MusicColors.sidebarPadding; spacing: MusicColors.sidebarRowGap
                    RowLayout {
                        Layout.leftMargin: MusicColors.sidebarControlInset; Layout.topMargin: 8
                        Layout.bottomMargin: MusicColors.sidebarGroupGap; spacing: 8
                        Image { source: MusicColors.sidebarIconSource("music"); Layout.preferredWidth: 20; Layout.preferredHeight: 20; sourceSize: Qt.size(40, 40) }
                        Label { text: "KMusic"; color: MusicColors.sidebarLabelPrimary; font.pixelSize: MusicColors.sidebarTitleSize; font.weight: Font.DemiBold }
                    }
                    LiquidTextField {
                        id: search; objectName: "reviewLibrarySearch"
                        readonly property bool onlineScope: ["new", "online", "onlineAlbum"].indexOf(window.destination) >= 0
                        backdrop: sidebarBackdrop; unfilteredBackdrop: true
                        textColor: MusicColors.sidebarLabelPrimary
                        mutedTextColor: MusicColors.sidebarLabelTertiary; shadowEnabled: false
                        Layout.fillWidth: true; Layout.bottomMargin: 12
                        implicitHeight: MusicColors.sidebarSearchHeight
                        materialForm: false; liquidFinish: true; liquidIntensity: "strong"
                        cornerRadius: height / 2
                        placeholderText: onlineScope ? qsTr("Search NetEase") : qsTr("Search local music")
                        font.pixelSize: MusicColors.sidebarSearchSize; font.weight: Font.Normal
                        leftPadding: MusicColors.sidebarControlInset + MusicColors.sidebarSearchIconSize + MusicColors.sidebarIconGap
                        rightPadding: MusicColors.sidebarControlInset
                        onOnlineScopeChanged: { clear(); music.setSearch("") }
                        onTextChanged: {
                            if (!onlineScope) {
                                if (text.length) { window.destination = "search"; window.pageTitle = qsTr("Search local music") }
                                music.setSearch(text)
                            }
                        }
                        onAccepted: {
                            if (onlineScope && text.trim().length) {
                                window.destination = "online"
                                onlinePage.queryText = text
                                music.searchOnline(text)
                            }
                        }
                        VectorIcon {
                            x: MusicColors.sidebarControlInset; anchors.verticalCenter: parent.verticalCenter
                            name: "search"; size: MusicColors.sidebarSearchIconSize
                            color: MusicColors.sidebarLabelSecondary
                        }
                    }
                    Label { text: qsTr("Online Music"); color: MusicColors.sidebarLabelPrimary; font.pixelSize: MusicColors.sidebarSearchSize; font.weight: Font.DemiBold; Layout.bottomMargin: 4; Layout.leftMargin: MusicColors.sidebarControlInset }
                    MusicNavigationButton { id: discoverNav; objectName: "reviewDiscoverNav"; Layout.fillWidth: true; iconName: "sparkle"; text: qsTr("Discover"); checked: window.destination === "new"; onClicked: window.navigate("new") }
                    MusicNavigationButton { Layout.fillWidth: true; iconName: "search"; text: qsTr("Search"); checked: window.destination === "online" || window.destination === "onlineAlbum"; onClicked: window.navigate("online", qsTr("Online search")) }
                    RowLayout {
                        Layout.fillWidth: true; Layout.topMargin: MusicColors.sidebarGroupGap; Layout.leftMargin: MusicColors.sidebarControlInset
                        Label { text: qsTr("Local Music"); color: MusicColors.sidebarLabelPrimary; font.pixelSize: MusicColors.sidebarSearchSize; font.weight: Font.DemiBold; Layout.fillWidth: true }
                        MusicActionButton {
                            id: localMenuButton
                            iconOnly: true; iconName: "more"; implicitWidth: 28; implicitHeight: 28; flat: true
                            Accessible.name: qsTr("Local music menu")
                            onClicked: localMusicMenu.popup()
                            Menu {
                                id: localMusicMenu
                                MenuItem {
                                    text: qsTr("Import music folder…"); enabled: !music.scanning
                                    onTriggered: { window.navigate("songs", qsTr("Local songs")); folderDialog.open() }
                                }
                                MenuItem {
                                    text: music.scanning ? qsTr("Scanning…") : qsTr("Rescan music folders")
                                    enabled: !music.scanning && music.libraryFolders.length > 0
                                    onTriggered: music.rescanLibrary()
                                }
                            }
                        }
                    }
                    Repeater {
                        model: [{key:"songs", label:qsTr("Songs"), icon:"music"}, {key:"albums", label:qsTr("Albums"), icon:"album"}, {key:"artists", label:qsTr("Artists"), icon:"artist"}]
                        delegate: MusicNavigationButton {
                            required property var modelData
                            Layout.fillWidth: true
                            text: modelData.label; iconName: modelData.icon
                            checked: window.destination === modelData.key || (modelData.key === "songs" && ["search", "detail"].indexOf(window.destination) >= 0)
                            onClicked: window.navigate(modelData.key, modelData.label)
                        }
                    }
                    Label { text: qsTr("On This Device"); color: MusicColors.sidebarLabelSecondary; font.pixelSize: MusicColors.sidebarCaptionSize; font.weight: Font.DemiBold; Layout.topMargin: MusicColors.sidebarGroupGap; Layout.bottomMargin: 4; Layout.leftMargin: MusicColors.sidebarControlInset }
                    MusicNavigationButton { objectName: "reviewFavoritesNav"; Layout.fillWidth: true; iconName: "heart"; iconSource: ""; text: qsTr("Favorites"); checked: window.destination === "favorites"; onClicked: window.navigate("favorites", qsTr("Favorites on this device")) }
                    MusicNavigationButton { objectName: "reviewRecentNav"; Layout.fillWidth: true; iconName: "repeat"; iconSource: ""; text: qsTr("Recently played"); checked: window.destination === "recent"; onClicked: window.navigate("recent", qsTr("Recently played on this device")) }
                    RowLayout {
                        Layout.fillWidth: true; Layout.topMargin: MusicColors.sidebarGroupGap; Layout.leftMargin: MusicColors.sidebarControlInset
                        Label { text: qsTr("On-device Playlists"); color: MusicColors.sidebarLabelSecondary; font.pixelSize: MusicColors.sidebarCaptionSize; font.weight: Font.DemiBold; Layout.fillWidth: true }
                        MusicActionButton { iconOnly: true; iconName: "plus"; iconColor: MusicColors.sidebarAccent; implicitWidth: 28; implicitHeight: 28; flat: true; onClicked: playlistDialog.open(); Accessible.name: qsTr("New playlist") }
                    }
                    Repeater {
                        model: music.playlists
                        delegate: MusicNavigationButton {
                            required property var modelData
                            Layout.fillWidth: true; text: modelData.name; iconName: "playlist"
                            checked: window.destination === "playlist" && window.selectedPlaylist === modelData.id
                            onClicked: { window.selectedPlaylist = modelData.id; music.selectPlaylist(modelData.id); window.destination = "playlist"; window.pageTitle = modelData.name }
                        }
                    }
                    Item { implicitHeight: MusicColors.sidebarGroupGap }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: MusicColors.sidebarPadding
                spacing: 8
                MusicNavigationButton { Layout.fillWidth: true; iconName: "queue"; text: qsTr("Play queue"); checked: window.destination === "queue"; onClicked: window.navigate("queue", qsTr("Play queue")) }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Button {
                        id: accountButton
                        objectName: "reviewAccountButton"
                        Layout.fillWidth: true; implicitHeight: 44
                        hoverEnabled: true
                        Accessible.name: music.account.authenticated ? qsTr("Account: %1").arg(music.account.nickname) : qsTr("Sign in to NetEase")
                        onClicked: accountDialog.open()
                        background: Rectangle {
                            radius: 8
                            color: accountButton.down ? AppTheme.withAlpha(MusicColors.text, .10) : accountButton.hovered ? MusicColors.hoverFill : "transparent"
                            border.width: accountButton.visualFocus ? 2 : 0
                            border.color: MusicColors.sidebarAccent
                        }
                        contentItem: RowLayout {
                            spacing: 8
                            Rectangle {
                                id: avatar
                                Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16
                                color: AppTheme.dark ? "#48484a" : "#d4d4d8"
                                Image {
                                    anchors.centerIn: parent; width: 24; height: 24
                                    source: MusicColors.sidebarIconSource("person", AppTheme.dark ? "#b0b0b5" : "#8e8e93")
                                    visible: !profileAvatar.visible || profileAvatar.status !== Image.Ready
                                }
                                Image {
                                    id: profileAvatar
                                    anchors.fill: parent
                                    visible: music.account.authenticated && source.toString().length > 0
                                    source: music.account.authenticated ? music.account.avatarUrl : ""
                                    asynchronous: true; fillMode: Image.PreserveAspectCrop
                                    layer.enabled: true
                                    layer.effect: OpacityMask { maskSource: Rectangle { width: avatar.width; height: avatar.height; radius: width / 2 } }
                                }
                            }
                            Label {
                                Layout.fillWidth: true
                                text: music.account.authenticated ? music.account.nickname || qsTr("NetEase account") : qsTr("Sign In")
                                color: MusicColors.sidebarLabelPrimary; font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                        }
                    }
                    MusicActionButton {
                        id: settingsButton
                        iconOnly: true; iconName: "settings"; implicitWidth: 28; implicitHeight: 28; flat: true
                        Accessible.name: qsTr("Settings")
                        onClicked: settingsMenu.popup()
                        Menu {
                            id: settingsMenu
                            Menu {
                                title: qsTr("Appearance")
                                MenuItem { text: qsTr("System appearance"); checkable: true; checked: AppTheme.appearanceMode === "system"; onTriggered: AppTheme.appearanceMode = "system" }
                                MenuItem { text: qsTr("Light appearance"); checkable: true; checked: AppTheme.appearanceMode === "light"; onTriggered: AppTheme.appearanceMode = "light" }
                                MenuItem { text: qsTr("Dark appearance"); checkable: true; checked: AppTheme.appearanceMode === "dark"; onTriggered: AppTheme.appearanceMode = "dark" }
                            }
                        }
                    }
                }
            }
        }

        }
        LiquidBackdrop { id: playerBackdrop; sourceItem: pageScene; registerAsDefault: false; blur: .19; maximumTextureSize: 2560 }
        PlayerBar { id: player; visible: window.destination !== "now"; anchors.bottom: parent.bottom; anchors.bottomMargin: 16
            width: Math.min(820, parent.width - 236 - 32); x: 236 + (parent.width - 236 - width) / 2
            backdrop: playerBackdrop; music: window.music; onQueueRequested: window.navigate("queue", qsTr("Play queue")); onNowPlayingRequested: window.destination = "now" }
        NowPlaying {
            id: nowPlaying; anchors.fill: parent
            visible: window.destination === "now"; music: window.music
            onCloseRequested: window.closeNowPlaying()
        }
        WindowChrome { width: parent.width; targetWindow: window }
    }
    AccountDialog { id: accountDialog; account: music.account }
    KosWindowResizeHandles { targetWindow: window }
    FolderDialog { id: folderDialog; title: qsTr("Import music folder"); onAccepted: music.addLibraryFolder(selectedFolder.toString()) }
    LiquidDialog {
        id: playlistDialog; anchors.centerIn: parent; width: 360; modal: true; title: qsTr("New playlist"); standardButtons: Dialog.Ok | Dialog.Cancel
        contentItem: LiquidTextField { id: playlistName; placeholderText: qsTr("Playlist name"); materialForm: false; liquidFinish: true }
        onAccepted: { if (playlistName.text.trim()) music.createPlaylist(playlistName.text.trim()); playlistName.text = "" }
    }
    LiquidDialog {
        id: addDialog; anchors.centerIn: parent; width: 360; modal: true; title: qsTr("Save to local playlist"); standardButtons: Dialog.Close
        onClosed: music.clearPreparedPlaylistTrack()
        contentItem: ColumnLayout {
            Label { text: music.preparedPlaylistTitle; color: AppTheme.text; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
            RowLayout {
                Layout.fillWidth: true
                LiquidTextField { id: newPlaylistName; materialForm: true; placeholderText: qsTr("New playlist name"); Layout.fillWidth: true }
                MusicActionButton { objectName: "reviewCreateLocalPlaylist"; text: qsTr("Create"); enabled: newPlaylistName.text.trim().length > 0; onClicked: { music.createPlaylist(newPlaylistName.text.trim()); newPlaylistName.text = "" } }
            }
            Label { visible: music.playlists.length === 0; text: qsTr("Create a playlist above, then choose it to save this song."); color: AppTheme.text; wrapMode: Text.WordWrap }
            Repeater {
                model: music.playlists
                delegate: MusicNavigationButton {
                    required property var modelData
                    required property int index
                    objectName: index === 0 ? "reviewSavePlaylistFirst" : ""
                    Layout.fillWidth: true; text: modelData.name
                    onClicked: music.savePreparedPlaylistTrack(modelData.id)
                }
            }
        }
    }
}
