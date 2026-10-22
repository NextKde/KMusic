import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Kos.Ui
import "UiLanguage.mjs" as Language
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
    property var sourcePrototypeEntry: ({})
    property var demoMediaAliases: ({})
    readonly property bool chineseNavigation: Language.chinese()
    readonly property var activeSource: SourceCatalog.source(selectedSource)
    function sourceLabel(item) { return SourceCatalog.label(item, chineseNavigation) || item.zh || item.en || "" }
    function openSourceEntry(entry) {
        selectedSourceEntry = entry.id
        if (entry.status === "connected") navigate(entry.route, sourceLabel(entry))
        else { sourcePrototypeEntry = entry; destination = "sourceDemo"; pageTitle = sourceLabel(entry) }
    }
    function selectSource(id) {
        restoringSourceSearch = true
        selectedSource = id
        if (id === "netease" || id === "bilibili") { onlineProvider = id; navigationArea = "discover" }
        else navigationArea = id === "local" ? "local" : "media"
        const sections = SourceCatalog.sections(id)
        if (sections.length && sections[0].entries.length) openSourceEntry(sections[0].entries[0])
        if (id === "netease") onlinePage.queryText = savedSourceSearch(id)
        music.setSearch(id === "local" ? savedSourceSearch(id) : "")
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
    property string pageTitle: Language.text("Songs", "歌曲")
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
        destination = key; pageTitle = title || Language.text("Songs", "歌曲")
        music.setSearch(selectedSource === "local" ? savedSourceSearch("local") : "")
        music.setLibraryView("songs")
    }
    Component.onCompleted: { AppTheme.appearanceMode = "light" }
    Shortcut { sequence: "Ctrl+O"; onActivated: { window.selectSource("local"); folderDialog.open() } }
    Shortcut { sequence: "Space"; enabled: !nowPlaying.ownsControlFocus(window.activeFocusItem) && !(window.activeFocusItem instanceof TextInput) && !(window.activeFocusItem instanceof TextEdit); onActivated: music.togglePlayPause() }
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
                    model: [{id:"netease", name:Language.text("NetEase Cloud Music", "网易云音乐")}, {id:"bilibili", name:Language.text("Bilibili", "哔哩哔哩")}]
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
                    title: window.destination === "personalHome" ? Language.text("Personal", "个人") : window.destination === "localHome" ? Language.text("Local Music", "本地音乐") : window.destination === "mediaHome" ? Language.text("Media Sources", "媒体源") : Language.text("Settings", "设置")
                    bottomContentInset: window.playerContentInset
                    groups: window.destination === "personalHome" ? [{title: Language.text("My Music", "我的音乐"), entries: SourceCatalog.sections(window.onlineProvider)[1].entries}]
                        : window.destination === "localHome" ? [
                            {title: Language.text("Music Library", "音乐库"), entries: SourceCatalog.sections("local")[0].entries.concat([{id:"folders", zh:Language.text("Music folders", "音乐文件夹"), en:"Music folders", route:"folders", status:"connected"}])},
                            {title: Language.text("On This Device", "本机收藏"), entries: [{id:"favorites", zh:Language.text("Favorites", "喜欢的音乐")}, {id:"recent", zh:Language.text("Recently Played", "最近播放")}, {id:"newPlaylist", zh:Language.text("New Playlist", "新建歌单")}].concat(music.playlists.map(p => ({id:"playlist", playlistId:p.id, zh:p.name}))) }]
                        : window.destination === "mediaHome" ? [{title: Language.text("Add Media Source", "添加媒体源"), entries: [{id:"navidrome", zh:"Navidrome / OpenSubsonic"}, {id:"jellyfin", zh:"Jellyfin"}, {id:"webdav", zh:"WebDAV"}]}]
                        : [{title:Language.text("Appearance", "外观"), entries:[{id:"system", zh:Language.text("System", "跟随系统")}, {id:"light", zh:Language.text("Light", "浅色")}, {id:"dark", zh:Language.text("Dark", "深色")}]}]
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
                    scopeDescription: recentView ? Language.text("Playback recorded by KMusic on this device, across sources. This is separate from platform account history.", "KMusic 在本机记录的播放历史，与平台账号历史分别保存。")
                        : favoritesView ? Language.text("Favorites saved by KMusic on this device, across sources. This does not change likes in a platform account.", "保存在本机的喜欢，不会修改平台账号的喜欢。")
                        : playlistView ? Language.text("A playlist saved by KMusic on this device. Platform and server playlists are managed in their own source sections.", "保存在本机的歌单。平台和服务器歌单在各自来源中管理。")
                        : queueView ? Language.text("The current playback queue can contain tracks from different sources.", "当前播放队列可包含不同来源的歌曲。")
                        : Language.text("Imported local audio files. Albums, artists and artwork come from file metadata when available.", "已导入的本地音频，专辑、艺术家和封面信息来自文件标签。")
                    emptyMessage: recentView ? Language.text("Your playback history on this device is empty. Played songs will appear here.", "暂无本机播放历史，播放过的歌曲会出现在这里。") : favoritesView ? Language.text("Your favorites on this device are empty. Add songs using the heart button.", "暂无本机喜欢的歌曲，可通过爱心按钮添加。") : queueView ? Language.text("Your queue is empty", "播放队列为空") : playlistView ? Language.text("This device playlist is empty. Add tracks from a song list.", "歌单为空，可从歌曲列表添加。") : Language.text("No local songs match. Import a music folder or change the local search.", "暂无本地歌曲，请导入音乐文件夹。")
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
                        Label { text: window.destination === "artists" ? Language.text("Artists", "艺术家") : Language.text("Albums", "专辑"); color: AppTheme.text; font.pixelSize: 26; font.weight: Font.Bold; Layout.topMargin: 24 }
                        Repeater {
                            model: window.destination === "artists" ? music.artists : music.albums
                            delegate: MusicNavigationButton {
                                required property var modelData
                                Layout.fillWidth: true; text: modelData.name + " · " + modelData.count + Language.text(" songs", " 首歌曲")
                                onClicked: { music.setLibraryView(window.destination === "artists" ? "artist" : "album", modelData.filterValue); window.pageTitle = modelData.name; window.destination = "detail" }
                            }
                        }
                        Label { visible: (window.destination === "artists" ? music.artists : music.albums).length === 0; text: Language.text("Import a music folder to get started.", "导入音乐文件夹以开始使用。"); color: AppTheme.mutedText }
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
                    Label { text: Language.text("Online Music", "在线音乐"); color: MusicColors.sidebarLabelSecondary; font.pixelSize: MusicColors.sidebarCaptionSize; font.weight: Font.DemiBold; Layout.topMargin: MusicColors.sidebarGroupGap; Layout.leftMargin: MusicColors.sidebarControlInset }
                    MusicNavigationButton { id: discoverNav; Layout.fillWidth: true; text: Language.text("Discover", "发现"); iconName: "music"; checked: window.navigationArea === "discover"; onClicked: window.openPrimary("discover") }
                    MusicNavigationButton { Layout.fillWidth: true; text: Language.text("Personal", "个人"); iconName: "person"; checked: window.navigationArea === "personal"; onClicked: window.openPrimary("personal") }
                    Label { text: Language.text("Local & Sources", "本地与媒体源"); color: MusicColors.sidebarLabelSecondary; font.pixelSize: MusicColors.sidebarCaptionSize; font.weight: Font.DemiBold; Layout.topMargin: MusicColors.sidebarGroupGap; Layout.leftMargin: MusicColors.sidebarControlInset }
                    MusicNavigationButton { Layout.fillWidth: true; text: Language.text("Local Music", "本地音乐"); iconName: "folder"; checked: window.navigationArea === "local"; onClicked: window.openPrimary("local") }
                    MusicNavigationButton { Layout.fillWidth: true; text: Language.text("Media Sources", "媒体源"); iconName: "album"; checked: window.navigationArea === "media"; onClicked: window.openPrimary("media") }
                    MusicNavigationButton { Layout.fillWidth: true; Layout.topMargin: MusicColors.sidebarGroupGap; text: Language.text("Settings", "设置"); iconName: "settings"; checked: window.navigationArea === "settings"; onClicked: window.openPrimary("settings") }
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
                        Accessible.name: Language.text("Settings", "设置")
                        onClicked: settingsMenu.popup()
                        Menu {
                            id: settingsMenu
                            Menu {
                                title: Language.text("Appearance", "外观")
                                MenuItem { text: Language.text("System", "跟随系统"); checkable: true; checked: AppTheme.appearanceMode === "system"; onTriggered: AppTheme.appearanceMode = "system" }
                                MenuItem { text: Language.text("Light appearance", "浅色模式"); checkable: true; checked: AppTheme.appearanceMode === "light"; onTriggered: AppTheme.appearanceMode = "light" }
                                MenuItem { text: Language.text("Dark appearance", "深色模式"); checkable: true; checked: AppTheme.appearanceMode === "dark"; onTriggered: AppTheme.appearanceMode = "dark" }
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
            backdrop: playerBackdrop; music: window.music; onQueueRequested: window.navigate("queue", Language.text("Play queue", "播放队列")); onNowPlayingRequested: window.destination = "now" }
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
    FolderDialog { id: folderDialog; title: Language.text("Import music folder", "导入音乐文件夹"); onAccepted: music.addLibraryFolder(selectedFolder.toString()) }
    LiquidDialog {
        id: playlistDialog; anchors.centerIn: parent; width: 360; modal: true; title: Language.text("New Playlist", "新建歌单"); standardButtons: Dialog.Ok | Dialog.Cancel
        contentItem: LiquidTextField { id: playlistName; placeholderText: Language.text("Playlist name", "歌单名称"); materialForm: false; liquidFinish: true }
        onAccepted: { if (playlistName.text.trim()) music.createPlaylist(playlistName.text.trim()); playlistName.text = "" }
    }
    LiquidDialog {
        id: addDialog; anchors.centerIn: parent; width: 360; modal: true; title: Language.text("Save to local playlist", "保存到本机歌单"); standardButtons: Dialog.Close
        onClosed: music.clearPreparedPlaylistTrack()
        contentItem: ColumnLayout {
            Label { text: music.preparedPlaylistTitle; color: AppTheme.text; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
            RowLayout {
                Layout.fillWidth: true
                LiquidTextField { id: newPlaylistName; materialForm: true; placeholderText: Language.text("New playlist name", "新歌单名称"); Layout.fillWidth: true }
                MusicActionButton { objectName: "reviewCreateLocalPlaylist"; text: Language.text("Create", "创建"); enabled: newPlaylistName.text.trim().length > 0; onClicked: { music.createPlaylist(newPlaylistName.text.trim()); newPlaylistName.text = "" } }
            }
            Label { visible: music.playlists.length === 0; text: Language.text("Create a playlist above, then choose it to save this song.", "先创建歌单，再选择歌单保存歌曲。"); color: AppTheme.text; wrapMode: Text.WordWrap }
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
