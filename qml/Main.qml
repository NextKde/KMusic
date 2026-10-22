import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Kos.Ui
import "MusicSourceCatalog.mjs" as SourceCatalog
ApplicationWindow {
    id: window
    required property var music
    width: 1100; height: 680; minimumWidth: 1024; minimumHeight: 640
    visible: true; title: "KMusic"; color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    property string navigationArea: "discover"
    property string onlineProvider: "netease"
    function openPrimary(area) {
        if (area === "discover" || area === "personal") {
            selectSource(onlineProvider)
            navigationArea = area
            if (area === "personal") destination = "personalHome"
        } else if (area === "local") {
            selectSource("local"); navigationArea = area; destination = "localHome"
        } else { navigationArea = area; destination = area === "media" ? "mediaHome" : "settingsHome" }
    }
    property string selectedSource: "netease"
    property string selectedSourceEntry: "discover"
    property var sourceSearchDrafts: ({})
    property bool restoringSourceSearch: false
    function rememberSourceSearch(provider, query) {
        const next = Object.assign({}, sourceSearchDrafts)
        next[provider] = query
        sourceSearchDrafts = next
    }
    function savedSourceSearch(provider) { return sourceSearchDrafts[provider] || "" }
    function submitSourceSearch() {
        if (selectedSource === "netease" && search.text.trim().length) {
            selectedSourceEntry = "search"
            onlinePage.queryText = search.text
            destination = "online"
            music.searchOnline(search.text)
        } else if (selectedSource === "local") {
            selectedSourceEntry = "songs"
            destination = "search"; pageTitle = qsTr("Search local music")
            music.setSearch(search.text)
        }
    }
    property var sourcePrototypeEntry: ({})
    property var demoMediaAliases: ({})
    readonly property bool chineseNavigation: Qt.locale().name.startsWith("zh")
    readonly property var activeSource: SourceCatalog.source(selectedSource)
    function sourceLabel(item) { return SourceCatalog.label(item, chineseNavigation) }
    function openSourceEntry(entry) {
        selectedSourceEntry = entry.id
        if (entry.status === "connected") navigate(entry.route, sourceLabel(entry))
        else { sourcePrototypeEntry = entry; destination = "sourceDemo"; pageTitle = sourceLabel(entry) }
    }
    function selectSource(id) {
        restoringSourceSearch = true
        if (selectedSource === "netease" || selectedSource === "local") rememberSourceSearch(selectedSource, search.text)
        selectedSource = id
        if (id === "netease" || id === "bilibili") { onlineProvider = id; navigationArea = "discover" }
        else navigationArea = id === "local" ? "local" : "media"
        const sections = SourceCatalog.sections(id)
        if (sections.length && sections[0].entries.length) openSourceEntry(sections[0].entries[0])
        search.text = savedSourceSearch(id)
        if (id === "netease") onlinePage.queryText = search.text
        music.setSearch(id === "local" ? search.text : "")
        restoringSourceSearch = false
    }
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
    function reviewOnlineSearch(text) { window.selectSource("netease"); music.onlineSearchKind = "song"; destination = "online"; onlinePage.queryText = text; music.searchOnline(text) }
    function openReviewSelect(name) { if (name === "quality") { destination = "online"; onlinePage.openQualityMenu() } else settingsMenu.popup() }
    function reviewMaterialAction(action, index) { destination = "now"; nowPlaying.reviewMaterialAction(action, index) }
    function materialReviewState() {
        const state = JSON.parse(nowPlaying.materialReviewState())
        state.homeButton = discover.homeOpticalState()
        state.playerControls = player.reviewState()
        state.navigation = { source: window.selectedSource, entry: window.selectedSourceEntry }
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
    function reviewOnlineAlbum(row) { window.selectSource("netease"); collectionReturnDestination = "new"; music.openDiscoveryAlbum(row); destination = "onlineAlbum" }
    function reviewCollectionSearch(text, kind) { window.selectSource("netease"); destination = "online"; music.onlineSearchKind = kind; onlinePage.queryText = text; music.searchOnline(text) }
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
    function navigate(key, title) {
        destination = key; pageTitle = title || qsTr("Songs")
        music.setSearch(selectedSource === "local" ? savedSourceSearch("local") : "")
        music.setLibraryView("songs")
    }
    Component.onCompleted: { AppTheme.appearanceMode = "light" }
    Shortcut { sequence: "Ctrl+O"; onActivated: { window.selectSource("local"); folderDialog.open() } }
    Shortcut { sequence: "Space"; enabled: !nowPlaying.ownsControlFocus(window.activeFocusItem) && !(window.activeFocusItem instanceof TextInput) && !(window.activeFocusItem instanceof TextEdit); onActivated: music.togglePlayPause() }
    Shortcut { sequence: "Ctrl+F"; onActivated: { if (search.enabled) { search.forceActiveFocus(); search.selectAll() } } }
    Connections {
        target: music
        function onRaiseRequested() { window.showNormal(); window.raise(); window.requestActivate() }
        function onPreparedPlaylistTrackSaved() { addDialog.close() }
    }
    Connections {
        target: music.account
        function onSessionChanged() {
            // The draft belongs to the former account context; never carry it
            // into the new session or into another source's account page.
            window.restoringSourceSearch = true
            window.rememberSourceSearch("netease", "")
            onlinePage.queryText = ""
            if (window.selectedSource === "netease") search.clear()
            window.restoringSourceSearch = false
        }
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
            RowLayout {
                id: onlineHeader
                visible: window.navigationArea === "discover" || window.navigationArea === "personal"
                x: 32; y: 34; spacing: 10
                Repeater {
                    model: [{id:"netease", name:"网易云音乐"}, {id:"bilibili", name:"哔哩哔哩"}]
                    delegate: MusicActionButton {
                        required property var modelData
                        text: modelData.name; checkable: true; checked: window.onlineProvider === modelData.id
                        onClicked: { const area = window.navigationArea; window.onlineProvider = modelData.id; window.openPrimary(area) }
                    }
                }
            }
            Item {
                anchors.fill: parent; anchors.topMargin: onlineHeader.visible ? 76 : 30
                NavigationHomePage {
                    anchors.fill: parent
                    visible: ["personalHome", "localHome", "mediaHome", "settingsHome"].indexOf(window.destination) >= 0
                    title: window.destination === "personalHome" ? "个人" : window.destination === "localHome" ? "本地音乐" : window.destination === "mediaHome" ? "媒体源" : "设置"
                    bottomContentInset: window.playerContentInset
                    groups: window.destination === "personalHome" ? [{title: "我的音乐", entries: SourceCatalog.sections(window.onlineProvider)[1].entries}]
                        : window.destination === "localHome" ? [
                            {title: "音乐库", entries: SourceCatalog.sections("local")[0].entries.concat([{id:"folders", zh:"音乐文件夹", en:"Music folders", route:"folders", status:"connected"}])},
                            {title: "本机收藏", entries: [{id:"favorites", zh:"喜欢的音乐"}, {id:"recent", zh:"最近播放"}, {id:"newPlaylist", zh:"新建歌单"}].concat(music.playlists.map(p => ({id:"playlist", playlistId:p.id, zh:p.name}))) }]
                        : window.destination === "mediaHome" ? [{title: "添加媒体源", entries: [{id:"navidrome", zh:"Navidrome / OpenSubsonic"}, {id:"jellyfin", zh:"Jellyfin"}, {id:"webdav", zh:"WebDAV"}]}]
                        : [{title:"外观", entries:[{id:"system", zh:"跟随系统"}, {id:"light", zh:"浅色"}, {id:"dark", zh:"深色"}]}]
                    onEntryRequested: entry => {
                        if (window.destination === "personalHome") window.openSourceEntry(entry)
                        else if (window.destination === "mediaHome") window.selectSource(entry.id)
                        else if (window.destination === "settingsHome") AppTheme.appearanceMode = entry.id
                        else if (entry.id === "newPlaylist") playlistDialog.open()
                        else if (entry.id === "playlist") { window.selectedPlaylist = entry.playlistId; music.selectPlaylist(entry.playlistId); window.destination = "playlist"; window.pageTitle = entry.zh }
                        else if (entry.route) window.openSourceEntry(entry)
                        else window.navigate(entry.id, entry.zh)
                    }
                }
                DiscoveryPage {
                    id: discover
                    bottomContentInset: window.playerContentInset
                    sidebarUnderlap: 236
                    x: -236; y: 0; width: parent.width + 236; height: parent.height
                    visible: window.destination === "new"; music: window.music
                    onImportRequested: { window.selectSource("local"); folderDialog.open() }
                    onOnlineRequested: { window.selectSource("netease"); window.openSourceEntry(SourceCatalog.sections("netease")[0].entries[1]) }
                    onOnlineAlbumRequested: row => window.reviewOnlineAlbum(row)
                    onNowPlayingRequested: window.destination = "now"
                    onAlbumRequested: (filter, title) => { window.music.setLibraryView("album", filter); window.pageTitle = title; window.destination = "detail" }
                }
                SongsPage {
                    id: songsPage
                    anchors.fill: parent
                    visible: ["songs", "search", "detail", "queue", "playlist", "favorites", "recent"].indexOf(window.destination) >= 0
                    music: window.music; bottomContentInset: window.playerContentInset; heading: window.pageTitle
                    scopeDescription: recentView ? qsTr("Playback recorded by KMusic on this device, across sources. This is separate from platform account history.")
                        : favoritesView ? qsTr("Favorites saved by KMusic on this device, across sources. This does not change likes in a platform account.")
                        : playlistView ? qsTr("A playlist saved by KMusic on this device. Platform and server playlists are managed in their own source sections.")
                        : queueView ? qsTr("The current playback queue can contain tracks from different sources.")
                        : qsTr("Imported local audio files. Albums, artists and artwork come from file metadata when available.")
                    emptyMessage: recentView ? qsTr("Your playback history on this device is empty. Played songs will appear here.") : favoritesView ? qsTr("Your favorites on this device are empty. Add songs using the heart button.") : queueView ? qsTr("Your queue is empty") : playlistView ? qsTr("This device playlist is empty. Add tracks from a song list.") : qsTr("No local songs match. Import a music folder or change the local search.")
                    queueView: window.destination === "queue"; recentView: window.destination === "recent"; favoritesView: window.destination === "favorites"; playlistView: window.destination === "playlist"; playlistId: window.selectedPlaylist
                    trackModel: recentView ? music.recentModel : favoritesView ? music.favoritesModel : queueView ? music.queueModel : playlistView ? music.playlistTracksModel : music.libraryModel
                    onImportRequested: { window.selectSource("local"); folderDialog.open() }
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
                LocalFoldersPage {
                    anchors.fill: parent; visible: window.destination === "folders"
                    music: window.music; bottomContentInset: window.playerContentInset
                    onImportRequested: folderDialog.open()
                }
                SourceDemoPage {
                    anchors.fill: parent; visible: window.destination === "sourceDemo"
                    sourceId: window.selectedSource
                    instanceName: window.demoMediaAliases[window.selectedSource] || ""
                    entryId: window.selectedSourceEntry
                    requiresLogin: window.sourcePrototypeEntry.login === true
                    authenticated: window.selectedSource === "netease" && music.account.authenticated
                    sourceName: window.sourceLabel(window.activeSource)
                    entryName: window.sourcePrototypeEntry.en ? window.sourceLabel(window.sourcePrototypeEntry) : ""
                    connectionStatus: window.activeSource.status
                    bottomContentInset: window.playerContentInset
                    onAccountRequested: accountDialog.open()
                    onConnectionRequested: {
                        sourceConnectionDialog.sourceId = window.selectedSource
                        sourceConnectionDialog.sourceName = window.sourceLabel(window.activeSource)
                        sourceConnectionDialog.open()
                    }
                }
                OnlinePage { id: onlinePage; bottomContentInset: window.playerContentInset; anchors.fill: parent; visible: window.destination === "online"; music: window.music; onCollectionRequested: row => window.openCollection(row); onSaveToPlaylistRequested: row => window.openPlaylistPicker("online", row)
                    onQueryTextChanged: {
                        if (window.selectedSource === "netease" && !window.restoringSourceSearch) {
                            window.rememberSourceSearch("netease", queryText)
                            if (!search.activeFocus) search.text = queryText
                        }
                    }
                }
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
                        readonly property bool onlineScope: window.selectedSource === "netease"
                        enabled: window.selectedSource === "netease" || window.selectedSource === "local"
                        backdrop: sidebarBackdrop; unfilteredBackdrop: true
                        textColor: MusicColors.sidebarLabelPrimary
                        mutedTextColor: MusicColors.sidebarLabelTertiary; shadowEnabled: false
                        Layout.fillWidth: true; Layout.bottomMargin: 12
                        implicitHeight: MusicColors.sidebarSearchHeight
                        materialForm: false; liquidFinish: true; liquidIntensity: "strong"
                        cornerRadius: height / 2
                        placeholderText: !enabled ? qsTr("Search unavailable · demo") : onlineScope ? qsTr("Search NetEase") : qsTr("Search local music")
                        font.pixelSize: MusicColors.sidebarSearchSize; font.weight: Font.Normal
                        leftPadding: MusicColors.sidebarControlInset + MusicColors.sidebarSearchIconSize + MusicColors.sidebarIconGap
                        rightPadding: MusicColors.sidebarControlInset
                        onTextChanged: {
                            if (window.restoringSourceSearch || !enabled) return
                            window.rememberSourceSearch(window.selectedSource, text)
                            if (window.selectedSource === "local") {
                                window.selectedSourceEntry = "songs"
                                if (text.length) { window.destination = "search"; window.pageTitle = qsTr("Search local music") }
                                music.setSearch(text)
                            }
                        }
                        onAccepted: window.submitSourceSearch()
                        VectorIcon {
                            x: MusicColors.sidebarControlInset; anchors.verticalCenter: parent.verticalCenter
                            name: "search"; size: MusicColors.sidebarSearchIconSize
                            color: MusicColors.sidebarLabelSecondary
                        }
                    }
                    Label { text: "Online Music"; color: MusicColors.sidebarLabelSecondary; font.pixelSize: MusicColors.sidebarCaptionSize; font.weight: Font.DemiBold; Layout.topMargin: MusicColors.sidebarGroupGap; Layout.leftMargin: MusicColors.sidebarControlInset }
                    MusicNavigationButton { id: discoverNav; Layout.fillWidth: true; text: "Discover"; iconName: "music"; checked: window.navigationArea === "discover"; onClicked: window.openPrimary("discover") }
                    MusicNavigationButton { Layout.fillWidth: true; text: "个人"; iconName: "person"; checked: window.navigationArea === "personal"; onClicked: window.openPrimary("personal") }
                    Label { text: "Local & Sources"; color: MusicColors.sidebarLabelSecondary; font.pixelSize: MusicColors.sidebarCaptionSize; font.weight: Font.DemiBold; Layout.topMargin: MusicColors.sidebarGroupGap; Layout.leftMargin: MusicColors.sidebarControlInset }
                    MusicNavigationButton { Layout.fillWidth: true; text: "本地音乐"; iconName: "folder"; checked: window.navigationArea === "local"; onClicked: window.openPrimary("local") }
                    MusicNavigationButton { Layout.fillWidth: true; text: "媒体源"; iconName: "album"; checked: window.navigationArea === "media"; onClicked: window.openPrimary("media") }
                    MusicNavigationButton { Layout.fillWidth: true; Layout.topMargin: MusicColors.sidebarGroupGap; text: "设置"; iconName: "settings"; checked: window.navigationArea === "settings"; onClicked: window.openPrimary("settings") }
                    Item { implicitHeight: MusicColors.sidebarGroupGap }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: MusicColors.sidebarPadding
                spacing: 8
                visible: false
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    MusicActionButton {
                        id: settingsButton
                        visible: false
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
    SourceConnectionDialog {
        id: sourceConnectionDialog
        onUseExample: alias => {
            const aliases = Object.assign({}, window.demoMediaAliases)
            aliases[sourceId] = alias
            window.demoMediaAliases = aliases
        }
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
