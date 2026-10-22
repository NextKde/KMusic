import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
import "UiLanguage.mjs" as Language

ColumnLayout {
    id: page
    required property var music
    property real bottomContentInset: 0
    property string section: "songs"
    property string detailTitle: ""
    property string returnSection: "albums"
    property double playlistId: -1
    signal importRequested()
    signal clearSearchRequested()
    signal addToPlaylistRequested(double trackId)
    readonly property bool songView: ["songs", "detail", "playlist", "favorites", "recent"].indexOf(section) >= 0
    readonly property var displayedModel: section === "playlist" ? music.playlistTracksModel : section === "favorites" ? music.favoritesModel : section === "recent" ? music.recentModel : music.libraryModel
    spacing: 12
    function openSection(key) {
        section = key
        detailTitle = ""
        music.setLibraryView("songs")
    }
    function searchLibrary() { openSection("songs") }
    function playVisible() {
        if (!displayedModel.count) return
        if (section === "playlist") music.playPlaylistRow(0)
        else if (section === "favorites") music.playFavoriteRow(0)
        else if (section === "recent") music.playRecentRow(0)
        else music.playTrack(displayedModel.trackIdAt(0))
    }
    RowLayout {
        Layout.fillWidth: true; Layout.leftMargin: 32; Layout.rightMargin: 32
        Label { text: Language.text("On this computer", "此电脑上的音乐"); font.pixelSize: 16; font.weight: Font.DemiBold; color: AppTheme.text; Layout.fillWidth: true }
        MusicActionButton { text: Language.text("Import folder", "导入文件夹"); enabled: page.music.ready; onClicked: page.importRequested() }
    }
    RowLayout {
        Layout.fillWidth: true; Layout.leftMargin: 32; Layout.rightMargin: 32; spacing: 6
        Repeater {
            model: [ {id:"songs", label:Language.text("Songs", "歌曲")}, {id:"albums", label:Language.text("Albums", "专辑")}, {id:"artists", label:Language.text("Artists", "艺术家")}, {id:"playlists", label:Language.text("Playlists", "歌单")}, {id:"folders", label:Language.text("Folders", "文件夹")} ]
            delegate: MusicActionButton {
                required property var modelData
                text: modelData.label
                checked: page.section === modelData.id || (page.section === "detail" && page.returnSection === modelData.id) || (["playlist", "favorites", "recent"].indexOf(page.section) >= 0 && modelData.id === "playlists")
                onClicked: page.openSection(modelData.id)
            }
        }
        Item { Layout.fillWidth: true }
    }
    Label {
        Layout.leftMargin: 32; Layout.rightMargin: 32; Layout.fillWidth: true
        visible: page.music.scanning || page.music.librarySearch.length > 0
        text: page.music.scanning ? page.music.scanStatus : Language.text("Library search: ", "曲库搜索：") + page.music.librarySearch
        color: AppTheme.mutedText; font.pixelSize: 12; wrapMode: Text.WordWrap
    }
    RowLayout {
        visible: page.songView
        Layout.fillWidth: true; Layout.leftMargin: 32; Layout.rightMargin: 32
        MusicActionButton { visible: page.section !== "songs"; text: Language.text("Back", "返回"); onClicked: page.openSection(page.section === "detail" ? page.returnSection : "playlists") }
        Label {
            Layout.fillWidth: true; elide: Text.ElideRight; color: AppTheme.mutedText
            text: (page.detailTitle ? page.detailTitle + " · " : "") + page.displayedModel.count + Language.text(" songs", " 首歌曲")
        }
        MusicActionButton { text: Language.text("Clear search", "清除搜索"); visible: page.music.librarySearch.length > 0; onClicked: page.clearSearchRequested() }
        MusicActionButton { text: Language.text("Play", "播放"); iconName: "mediaPlay"; enabled: page.displayedModel.count > 0; onClicked: page.playVisible() }
    }
    Label {
        visible: ["playlist", "favorites", "recent"].indexOf(page.section) >= 0
        Layout.leftMargin: 32; Layout.rightMargin: 32; Layout.fillWidth: true; wrapMode: Text.WordWrap
        text: Language.text("Saved on this device. May include online tracks; separate from your platform account.", "保存在本机，可包含在线歌曲，与平台账号数据分开。")
        color: AppTheme.mutedText; font.pixelSize: 12
    }
    SongsPage {
        Layout.fillWidth: true; Layout.fillHeight: true; visible: page.songView
        music: page.music; showHeading: false; trackModel: page.displayedModel
        bottomContentInset: page.bottomContentInset
        playlistView: page.section === "playlist"; playlistId: page.playlistId
        favoritesView: page.section === "favorites"; recentView: page.section === "recent"
        emptyMessage: page.music.scanning ? Language.text("Scanning your music folders…", "正在扫描音乐文件夹…")
            : page.section !== "songs" ? Language.text("No songs here yet.", "暂无歌曲。")
            : page.music.librarySearch.length ? Language.text("No matching songs. Try another search.", "没有匹配的歌曲，请更换关键词。")
            : Language.text("Your music starts here. Import a folder to build your library.", "从导入音乐文件夹开始，建立你的曲库。")
        onAddToPlaylistRequested: trackId => page.addToPlaylistRequested(trackId)
        onImportRequested: page.importRequested()
    }
    ScrollView {
        id: groupsScroll
        visible: page.section === "albums" || page.section === "artists"
        Layout.fillWidth: true; Layout.fillHeight: true; contentWidth: availableWidth; clip: true
        ColumnLayout {
            x: 32; width: groupsScroll.availableWidth - 64; spacing: 16
            Label { visible: groupTiles.count === 0; Layout.fillWidth: true; wrapMode: Text.WordWrap; text: Language.text("No matching items. Import music or clear the library search.", "暂无匹配项目，请导入音乐或清除曲库搜索。"); color: AppTheme.mutedText }
            GridLayout {
                Layout.fillWidth: true; columns: Math.max(2, Math.floor(width / 170)); columnSpacing: 18; rowSpacing: 22
                Repeater {
                    id: groupTiles
                    model: page.section === "artists" ? page.music.artists : page.music.albums
                    delegate: AlbumTile {
                        required property var modelData
                        Layout.fillWidth: true; Layout.preferredWidth: 155; Layout.preferredHeight: width + 44
                        title: modelData.name; subtitle: modelData.count + Language.text(" songs", " 首歌曲"); artwork: modelData.artworkUrl || ""
                        onClicked: {
                            page.returnSection = page.section
                            page.music.setLibraryView(page.section === "artists" ? "artist" : "album", modelData.filterValue)
                            page.detailTitle = modelData.name; page.section = "detail"
                        }
                    }
                }
            }
            Item { Layout.preferredHeight: page.bottomContentInset }
        }
    }
    ScrollView {
        id: playlistsScroll
        visible: page.section === "playlists"
        Layout.fillWidth: true; Layout.fillHeight: true; contentWidth: availableWidth; clip: true
        ColumnLayout {
            x: 32; width: playlistsScroll.availableWidth - 64; spacing: 16
            RowLayout {
                MusicActionButton { text: Language.text("Favorites", "喜欢的音乐"); onClicked: { page.section = "favorites"; page.detailTitle = text } }
                MusicActionButton { text: Language.text("Recently Played", "最近播放"); onClicked: { page.section = "recent"; page.detailTitle = text } }
                Item { Layout.fillWidth: true }
                MusicActionButton { text: Language.text("New playlist", "新建歌单"); onClicked: { playlistEditor.editId = -1; playlistName.text = ""; playlistEditor.open() } }
            }
            Label { text: Language.text("Your playlists on this device", "本机歌单"); color: AppTheme.text; font.pixelSize: 18; font.weight: Font.DemiBold }
            Label { visible: !page.music.playlists.length; Layout.fillWidth: true; wrapMode: Text.WordWrap; text: Language.text("Create a playlist, then add songs from the song menu.", "创建歌单后，可从歌曲菜单添加歌曲。"); color: AppTheme.mutedText }
            Repeater {
                model: page.music.playlists
                delegate: RowLayout {
                    id: playlistRow
                    required property var modelData
                    Layout.fillWidth: true
                    MusicNavigationButton { Layout.fillWidth: true; text: playlistRow.modelData.name; onClicked: { page.playlistId = playlistRow.modelData.id; page.music.selectPlaylist(page.playlistId); page.detailTitle = playlistRow.modelData.name; page.section = "playlist" } }
                    MusicActionButton { text: Language.text("Rename", "重命名"); onClicked: { playlistEditor.editId = playlistRow.modelData.id; playlistName.text = playlistRow.modelData.name; playlistEditor.open() } }
                    MusicActionButton { text: Language.text("Remove", "移除"); onClicked: { removePlaylistDialog.editId = playlistRow.modelData.id; removePlaylistDialog.playlistTitle = playlistRow.modelData.name; removePlaylistDialog.open() } }
                }
            }
            Item { Layout.preferredHeight: page.bottomContentInset }
        }
    }
    LocalFoldersPage {
        Layout.fillWidth: true; Layout.fillHeight: true; visible: page.section === "folders"
        showHeading: false; music: page.music; bottomContentInset: page.bottomContentInset
        onImportRequested: page.importRequested()
    }
    LiquidDialog {
        id: playlistEditor
        property double editId: -1
        parent: Overlay.overlay; anchors.centerIn: parent; width: 360; modal: true
        title: editId < 0 ? Language.text("New playlist", "新建歌单") : Language.text("Rename playlist", "重命名歌单")
        standardButtons: Dialog.Ok | Dialog.Cancel
        contentItem: LiquidTextField { id: playlistName; placeholderText: Language.text("Playlist name", "歌单名称"); maximumLength: 128 }
        onOpened: { standardButton(Dialog.Ok).enabled = Qt.binding(() => playlistName.text.trim().length > 0); playlistName.forceActiveFocus() }
        onAccepted: { if (editId < 0) page.music.createPlaylist(playlistName.text); else page.music.renamePlaylist(editId, playlistName.text) }
    }
    LiquidDialog {
        id: removePlaylistDialog
        property double editId: -1
        property string playlistTitle: ""
        parent: Overlay.overlay; anchors.centerIn: parent; width: 380; modal: true
        title: Language.text("Remove playlist?", "移除歌单？"); standardButtons: Dialog.Ok | Dialog.Cancel
        contentItem: Label { text: removePlaylistDialog.playlistTitle + "\n\n" + Language.text("Only the playlist is removed. Your audio files are kept.", "仅移除歌单，保留音频文件。"); wrapMode: Text.WordWrap; color: AppTheme.text }
        onAccepted: page.music.removePlaylist(editId)
    }
}
