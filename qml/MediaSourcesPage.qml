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
    readonly property bool canSubmitSearch: server.connected && !server.busy && query.text.trim().length > 0
    function submitSearch() {
        if (!canSubmitSearch) return
        view = "search"
        server.search(query.text.trim())
    }
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
            MusicTextField { searchField: true; id: query; Layout.fillWidth: true; materialForm: true; placeholderText: Language.text("Search this server", "搜索当前服务器"); onAccepted: page.submitSearch() }
            MusicActionButton { id: searchButton; text: Language.text("Search", "搜索"); enabled: page.canSubmitSearch; onClicked: page.submitSearch() }
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
        parent: Overlay.overlay; anchors.centerIn: parent
        width: Math.min(420, parent.width - 40)
        modal: true; dim: true
        title: Language.text("Connect music server", "连接音乐服务器")
        standardButtons: Dialog.NoButton
        padding: 20
        header: Label {
            text: connection.title; color: AppTheme.text
            font.pixelSize: 18; font.weight: Font.DemiBold
            leftPadding: 20; rightPadding: 20; topPadding: 20; bottomPadding: 8
        }
        onOpened: { address.text = page.server.server; username.text = page.server.username; password.text = "" }
        onClosed: password.text = ""
        component Field: MusicTextField {
            Layout.fillWidth: true
            implicitHeight: 36; font.pixelSize: 13
            materialForm: true; cornerRadius: 8
            glassColor: AppTheme.dark ? "#39393e" : "#f0f0f3"
            outlineColor: activeFocus ? AppTheme.withAlpha(AppTheme.text, .24) : "transparent"
        }
        component FieldLabel: Label {
            color: AppTheme.mutedText; font.pixelSize: 12; font.weight: Font.Medium
        }
        contentItem: ColumnLayout {
            spacing: 16
            ColumnLayout {
                Layout.fillWidth: true; spacing: 6
                FieldLabel { text: Language.text("Server address", "服务器地址") }
                Field { id: address; placeholderText: "https://music.example.com"; inputMethodHints: Qt.ImhUrlCharactersOnly; Accessible.name: Language.text("Server address", "服务器地址") }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 6
                FieldLabel { text: Language.text("Username", "用户名") }
                Field { id: username; placeholderText: Language.text("Your server username", "服务器用户名"); Accessible.name: Language.text("Username", "用户名") }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 6
                FieldLabel { text: Language.text("Password", "密码") }
                Field { id: password; placeholderText: Language.text("Enter password", "输入密码"); echoMode: TextInput.Password; Accessible.name: Language.text("Password", "密码") }
            }
            RowLayout {
                Layout.fillWidth: true
                Label { Layout.fillWidth: true; font.pixelSize: 13; text: Language.text("Remember securely", "安全保存登录信息"); color: AppTheme.text }
                LiquidGlassSwitch { id: remember; materialForm: true; checked: true; Accessible.name: Language.text("Remember securely", "安全保存登录信息") }
            }
            Label {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                color: AppTheme.mutedText; font.pixelSize: 12
                text: Language.text("Use HTTPS for an encrypted connection.", "使用 HTTPS 地址可加密连接。")
            }
        }
        footer: Item {
            implicitHeight: 60
            RowLayout {
                anchors.centerIn: parent; spacing: 10
                MusicActionButton {
                    text: Language.text("Cancel", "取消")
                    onClicked: connection.reject()
                }
                MusicActionButton {
                    text: Language.text("Connect", "连接")
                    enabled: address.text.trim().length > 0 && username.text.trim().length > 0 && password.text.length > 0
                    surfaceColor: AppTheme.dark ? "#ededf0" : "#303036"
                    textColor: AppTheme.dark ? "#202024" : "#ffffff"
                    onClicked: {
                        page.view = "albums"
                        page.server.connectServer(address.text, username.text, password.text, remember.checked)
                        connection.close()
                    }
                }
            }
        }
    }
}
