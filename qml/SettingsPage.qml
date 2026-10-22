import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
import "UiLanguage.mjs" as Language

ScrollView {
    id: page
    required property var music
    required property var preferences
    property real bottomContentInset: 0
    signal importRequested()
    signal foldersRequested()
    signal accountRequested()
    signal clearSearchRequested()
    contentWidth: availableWidth
    clip: true
    component Heading: Label {
        Layout.fillWidth: true
        Layout.topMargin: 22
        Layout.bottomMargin: 6
        font.pixelSize: 19; font.weight: Font.Bold; color: AppTheme.text
    }
    component Note: Label {
        Layout.fillWidth: true; wrapMode: Text.WordWrap
        font.pixelSize: 12; color: AppTheme.mutedText
    }
    component SettingRow: RowLayout {
        property string label
        property string description: ""
        Layout.fillWidth: true; Layout.minimumHeight: 46; spacing: 20
        ColumnLayout {
            Layout.fillWidth: true; spacing: 4
            Label { text: parent.parent.label; color: AppTheme.text; font.pixelSize: 14; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Note { text: parent.parent.description; visible: text.length > 0 }
        }
    }
    ColumnLayout {
        width: page.availableWidth - 64; x: 32; spacing: 8
        Heading { text: Language.text("General & Appearance", "通用与外观") }
        SettingRow {
            label: Language.text("Language", "语言")
            Label { text: Language.text("Follow system · English", "跟随系统 · 中文"); color: AppTheme.mutedText }
        }
        SettingRow {
            label: Language.text("Appearance", "外观")
            MusicSelect {
                materialForm: true
                model: [Language.text("System", "跟随系统"), Language.text("Light", "浅色"), Language.text("Dark", "深色")]
                currentIndex: Math.max(0, ["system", "light", "dark"].indexOf(AppTheme.appearanceMode))
                onActivated: index => AppTheme.appearanceMode = ["system", "light", "dark"][index]
            }
        }
        SettingRow {
            label: Language.text("Reduce motion", "减少动画")
            LiquidGlassSwitch { materialForm: true; checked: AppTheme.reduceMotion; onToggled: checked => AppTheme.reduceMotion = checked }
        }
        SettingRow {
            label: Language.text("Remember window size", "记住窗口大小")
            LiquidGlassSwitch { materialForm: true; checked: page.preferences.rememberWindowSize; onToggled: checked => page.preferences.rememberWindowSize = checked }
        }
        Heading { text: Language.text("Playback", "播放") }
        SettingRow {
            label: Language.text("Preferred online quality", "首选在线音质")
            description: Language.text("Actual quality depends on the source and your account permissions.", "实际音质取决于来源和账号权限。")
            MusicSelect {
                materialForm: true
                readonly property var qualities: ["128k", "320k", "flac", "flac24bit"]
                model: ["128 kbps", "320 kbps", Language.text("Lossless", "无损"), "Hi-Res"]
                currentIndex: Math.max(0, qualities.indexOf(page.music.onlineQuality))
                onActivated: index => page.music.onlineQuality = qualities[index]
            }
        }
        Note { text: Language.text("Restoring the last track and startup autoplay are not available yet.", "暂未接入上次播放恢复和启动自动播放。") }
        Heading { text: Language.text("Lyrics", "歌词") }
        SettingRow {
            label: Language.text("Font size", "字体大小")
            MusicSelect {
                materialForm: true; model: ["21", "25", "29", "33"]
                currentIndex: Math.max(0, [21,25,29,33].indexOf(page.preferences.lyricFontSize))
                onActivated: index => page.preferences.lyricFontSize = [21,25,29,33][index]
            }
        }
        SettingRow {
            label: Language.text("Alignment", "对齐方式")
            MusicSelect {
                materialForm: true; model: [Language.text("Left", "左对齐"), Language.text("Center", "居中")]
                currentIndex: page.preferences.centerLyrics ? 1 : 0
                onActivated: index => page.preferences.centerLyrics = index === 1
            }
        }
        SettingRow {
            label: Language.text("Blur inactive lines", "模糊非当前歌词")
            LiquidGlassSwitch { materialForm: true; checked: page.preferences.lyricBlur; onToggled: checked => page.preferences.lyricBlur = checked }
        }
        SettingRow {
            label: Language.text("Smooth lyric scrolling", "平滑滚动歌词")
            description: Language.text("Reduce motion takes priority when enabled.", "开启减少动画时优先遵循减少动画设置。")
            LiquidGlassSwitch { materialForm: true; checked: page.preferences.smoothLyrics; onToggled: checked => page.preferences.smoothLyrics = checked }
        }
        Heading { text: Language.text("Local Music", "本地音乐") }
        SettingRow {
            label: Language.text("Music folders", "音乐文件夹")
            description: Language.text("Registered folders: ", "已添加文件夹：") + page.music.libraryFolders.length
            MusicActionButton { text: Language.text("Manage", "管理"); onClicked: page.foldersRequested() }
            MusicActionButton { text: Language.text("Add", "添加"); enabled: page.music.ready && !page.music.scanning; onClicked: page.importRequested() }
        }
        SettingRow {
            label: Language.text("Refresh library", "刷新曲库")
            description: page.music.scanning ? page.music.scanStatus : Language.text("Read tags and artwork from your music files again.", "重新读取音乐文件的标签和封面。")
            MusicActionButton { text: Language.text("Rescan", "重新扫描"); enabled: page.music.ready && !page.music.scanning && page.music.libraryFolders.length > 0; onClicked: page.music.rescanLibrary() }
        }
        Heading { text: Language.text("Accounts & Media Sources", "账号与媒体源") }
        SettingRow {
            label: Language.text("NetEase Cloud Music", "网易云音乐")
            description: page.music.account.authenticated ? page.music.account.nickname : Language.text("Not signed in", "未登录")
            MusicActionButton { text: page.music.account.authenticated ? Language.text("Manage account", "管理账号") : Language.text("Sign in", "登录"); onClicked: page.accountRequested() }
        }
        Note { text: Language.text("Bilibili and media servers are not connected yet.", "B站和媒体服务器尚未接入。") }
        Heading { text: Language.text("Storage", "存储") }
        SettingRow {
            label: Language.text("Search history", "搜索历史")
            description: Language.text("Saved on this device, separately for each source.", "保存在本机，各来源分别记录。")
            MusicActionButton { text: Language.text("Clear", "清空"); onClicked: clearHistory.open() }
        }
        Note { text: Language.text("Cache usage and cache cleanup controls are not available yet.", "缓存占用统计和清理功能暂未接入设置。") }
        Heading { text: Language.text("About", "关于") }
        SettingRow {
            label: "KMusic"
            Label { text: Qt.application.version; color: AppTheme.mutedText }
        }
        RowLayout {
            MusicActionButton { text: Language.text("Project", "项目主页"); onClicked: Qt.openUrlExternally("https://github.com/NextKde/KMusic") }
            MusicActionButton { text: Language.text("License", "许可证"); onClicked: Qt.openUrlExternally("https://github.com/NextKde/KMusic/blob/codex/music-development/LICENSE") }
        }
        Item { Layout.preferredHeight: page.bottomContentInset + 24 }
    }
    LiquidDialog {
        id: clearHistory
        parent: Overlay.overlay; anchors.centerIn: parent; width: 380
        modal: true; dim: true; standardButtons: Dialog.Ok | Dialog.Cancel
        title: Language.text("Clear search history?", "清空搜索历史？")
        contentItem: Label { text: Language.text("Clears local and online search history on this device. Music and playlists are kept.", "清空此设备的本地及在线搜索历史，保留音乐和歌单。"); wrapMode: Text.WordWrap; color: AppTheme.text }
        onAccepted: page.clearSearchRequested()
    }
}
