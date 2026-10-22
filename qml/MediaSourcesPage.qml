import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
import "UiLanguage.mjs" as Language

ScrollView {
    id: page
    required property var music
    readonly property var server: music.mediaServer
    property real bottomContentInset: 0
    property string view: "albums"
    contentWidth: availableWidth; clip: true
    ColumnLayout {
        x: 32; width: page.availableWidth - 64; spacing: 16
        Label { Layout.topMargin: 20; text: "Navidrome / OpenSubsonic"; color: AppTheme.text; font.pixelSize: 23; font.weight: Font.Bold }
        Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: page.server.connected ? page.server.server + " · " + page.server.username : Language.text("Connect your personal music server.", "连接你的个人音乐服务器。"); color: AppTheme.mutedText }
        RowLayout {
            MusicActionButton { text: page.server.connected ? Language.text("Change server", "更换服务器") : Language.text("Connect", "连接"); enabled: !page.server.busy; onClicked: connection.open() }
            MusicActionButton { text: Language.text("Disconnect", "断开连接"); visible: page.server.connected || page.server.server.length > 0; onClicked: page.server.disconnectServer() }
        }
        Label { visible: page.server.message.length > 0; text: page.server.message; Layout.fillWidth: true; wrapMode: Text.WordWrap; color: AppTheme.mutedText }
        BusyIndicator { running: page.server.busy; visible: running; Layout.alignment: Qt.AlignHCenter }
        RowLayout {
            visible: page.server.connected; Layout.fillWidth: true
            MusicActionButton { text: Language.text("Albums", "专辑"); checked: page.view === "albums"; enabled: !page.server.busy; onClicked: { page.view = "albums"; page.server.browseAlbums() } }
            LiquidTextField { id: query; Layout.fillWidth: true; materialForm: true; placeholderText: Language.text("Search this server", "搜索当前服务器"); onAccepted: searchButton.clicked() }
            MusicActionButton { id: searchButton; text: Language.text("Search", "搜索"); enabled: !page.server.busy; onClicked: { page.view = "search"; page.server.search(query.text) } }
        }
        Flow {
            visible: page.server.connected && page.view === "albums"; Layout.fillWidth: true; spacing: 16
            Repeater {
                model: page.server.albums
                delegate: Column {
                    required property var modelData
                    width: 150; spacing: 6
                    Artwork { width: 150; height: 150; radius: 8; source: modelData.artwork; title: modelData.title
                        TapHandler { enabled: !page.server.busy; onTapped: { page.view = "songs"; page.server.openAlbum(modelData.id) } }
                    }
                    MusicActionButton { width: 150; text: modelData.title; flat: true; enabled: !page.server.busy; onClicked: { page.view = "songs"; page.server.openAlbum(modelData.id) } }
                    Label { width: parent.width; text: modelData.artist; color: AppTheme.mutedText; elide: Text.ElideRight; font.pixelSize: 12 }
                }
            }
        }
        ColumnLayout {
            visible: page.server.connected && page.view !== "albums"; Layout.fillWidth: true; spacing: 2
            Repeater {
                model: page.server.songs
                delegate: RowLayout {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true; Layout.minimumHeight: 52; spacing: 10
                    Artwork { Layout.preferredWidth: 40; Layout.preferredHeight: 40; radius: 5; source: modelData.artwork; title: modelData.title }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Label { Layout.fillWidth: true; text: modelData.title; elide: Text.ElideRight; color: AppTheme.text }
                        Label { Layout.fillWidth: true; text: modelData.artist + " · " + modelData.album; elide: Text.ElideRight; color: AppTheme.mutedText; font.pixelSize: 12 }
                    }
                    MusicActionButton { iconOnly: true; iconName: "mediaPlay"; Accessible.name: Language.text("Play", "播放"); onClicked: page.music.playMediaSong(index) }
                    MusicActionButton { text: "+"; Accessible.name: Language.text("Add to queue", "加入队列"); onClicked: page.music.playMediaSong(index, true) }
                }
            }
        }
        Label { visible: page.server.connected && !page.server.busy && !page.server.message.length && (page.view === "albums" ? page.server.albums.length === 0 : page.server.songs.length === 0); text: Language.text("No music found.", "未找到音乐。"); color: AppTheme.mutedText }
        MusicActionButton { visible: page.server.connected && page.server.more; enabled: !page.server.busy; text: Language.text("Load more", "加载更多"); onClicked: page.view === "albums" ? page.server.browseAlbums(true) : page.server.search(query.text, true) }
        Item { Layout.preferredHeight: page.bottomContentInset + 24 }
    }
    LiquidDialog {
        id: connection
        parent: Overlay.overlay; anchors.centerIn: parent; width: 440; modal: true; dim: true
        title: Language.text("Connect music server", "连接音乐服务器"); standardButtons: Dialog.Cancel
        onOpened: { address.text = page.server.server; username.text = page.server.username; password.text = "" }
        onClosed: password.text = ""
        contentItem: ColumnLayout {
            spacing: 12
            Label { text: Language.text("Server address", "服务器地址"); color: AppTheme.text }
            LiquidTextField { id: address; Layout.fillWidth: true; materialForm: true; placeholderText: "https://music.example.com" }
            Label { text: Language.text("Username", "用户名"); color: AppTheme.text }
            LiquidTextField { id: username; Layout.fillWidth: true; materialForm: true }
            Label { text: Language.text("Password", "密码"); color: AppTheme.text }
            LiquidTextField { id: password; Layout.fillWidth: true; materialForm: true; echoMode: TextInput.Password }
            RowLayout {
                Label { Layout.fillWidth: true; text: Language.text("Remember securely", "安全保存登录信息"); color: AppTheme.text }
                LiquidGlassSwitch { id: remember; materialForm: true; checked: true }
            }
            Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: AppTheme.mutedText; font.pixelSize: 12; text: Language.text("Use HTTPS for remote servers. HTTP connections are not encrypted.", "远程服务器请使用 HTTPS，HTTP 连接不加密。") }
            MusicActionButton { Layout.alignment: Qt.AlignHCenter; text: Language.text("Connect", "连接"); enabled: address.text.trim().length > 0 && username.text.trim().length > 0 && password.text.length > 0; onClicked: { page.view = "albums"; page.server.connectServer(address.text, username.text, password.text, remember.checked); connection.close() } }
        }
    }
}
