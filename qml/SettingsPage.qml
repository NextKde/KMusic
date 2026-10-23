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
    signal clearSearchRequested()
    onVisibleChanged: if (visible) music.refreshAudioCache()
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
        Heading { text: Language.text("Appearance", "外观") }
        SettingRow {
            label: Language.text("Language", "语言")
            MusicSelect {
                materialForm: true
                model: [Language.text("Follow system", "跟随系统"), "English", "简体中文"]
                currentIndex: Math.max(0, ["system", "en", "zh_CN"].indexOf(languagePreferences.selection))
                onActivated: index => languagePreferences.selection = ["system", "en", "zh_CN"][index]
            }
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
            label: Language.text("NetEase streaming quality", "网易云播放音质")
            description: Language.text("Subject to track availability and your NetEase account permissions.", "实际音质取决于歌曲和网易云账号权限。")
            MusicSelect {
                materialForm: true
                readonly property var qualities: ["128k", "320k", "flac", "flac24bit"]
                model: ["128 kbps", "320 kbps", Language.text("Lossless", "无损"), "Hi-Res"]
                currentIndex: Math.max(0, qualities.indexOf(page.music.onlineQuality))
                onActivated: index => page.music.onlineQuality = qualities[index]
            }
        }
        SettingRow {
            label: Language.text("Restore last playback", "恢复上次播放")
            description: Language.text("Restore the queue, track and position on next launch, without playing automatically.", "下次启动恢复队列、歌曲和进度，默认不自动播放。")
            LiquidGlassSwitch { materialForm: true; checked: page.music.restorePlayback; onToggled: checked => page.music.restorePlayback = checked }
        }
        SettingRow {
            label: Language.text("Play automatically on startup", "启动时自动播放")
            LiquidGlassSwitch { materialForm: true; enabled: page.music.restorePlayback; checked: page.music.startupAutoplay; onToggled: checked => page.music.startupAutoplay = checked }
        }
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
        Heading { text: Language.text("Storage", "存储") }
        SettingRow {
            label: Language.text("Search history", "搜索历史")
            description: Language.text("Saved on this device, separately for each source.", "保存在本机，各来源分别记录。")
            MusicActionButton { text: Language.text("Clear", "清空"); onClicked: clearHistory.open() }
        }
        SettingRow {
            label: Language.text("Completed audio cache", "已完成的音频缓存")
            description: (page.music.audioCacheBytes / 1048576).toFixed(1) + " MB · " + Language.text("Local music, artwork and playlists are kept.", "保留本地音乐、封面和歌单。")
            MusicActionButton { text: Language.text("Clear", "清理"); enabled: page.music.audioCacheBytes > 0; onClicked: clearCache.open() }
        }
        Note { text: page.music.cacheCleanupMessage; visible: text.length > 0 }
        Heading { text: Language.text("About", "关于") }
        SettingRow {
            label: "KMusic"
            Label { text: Qt.application.version; color: AppTheme.mutedText }
        }
        RowLayout {
            MusicActionButton { text: Language.text("Project", "项目主页"); onClicked: Qt.openUrlExternally("https://github.com/NextKde/KMusic") }
            MusicActionButton { text: Language.text("License", "许可证"); onClicked: Qt.openUrlExternally("https://github.com/NextKde/KMusic/blob/main/LICENSE") }
        }
        Item { Layout.preferredHeight: page.bottomContentInset + 24 }
    }
    LiquidDialog {
        id: clearCache
        parent: Overlay.overlay; anchors.centerIn: parent; width: 380
        modal: true; dim: true; standardButtons: Dialog.Ok | Dialog.Cancel
        title: Language.text("Clear audio cache?", "清理音频缓存？")
        contentItem: Label { text: Language.text("Only completed audio cache is removed. Active files and downloads are kept; songs may need to download again.", "仅删除已完成的音频缓存，保留正在使用和下载中的文件；之后播放可能需要重新下载。"); wrapMode: Text.WordWrap; color: AppTheme.text }
        onAccepted: page.music.clearAudioCache()
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
