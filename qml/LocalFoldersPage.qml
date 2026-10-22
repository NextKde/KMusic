import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
import "UiLanguage.mjs" as Language

ScrollView {
    id: page
    property bool showHeading: true
    required property var music
    property real bottomContentInset: 0
    signal importRequested()
    contentWidth: availableWidth
    clip: true
    ColumnLayout {
        width: page.availableWidth - 64; x: 32; spacing: 16
        Item { implicitHeight: 24 }
        Label { text: Language.text("Local Music", "本地音乐"); color: AppTheme.mutedText; font.pixelSize: 13 }
        Label { visible: page.showHeading; text: Language.text("Music folders", "音乐文件夹"); color: AppTheme.text; font.pixelSize: 26; font.weight: Font.Bold }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; color: AppTheme.mutedText
            text: Language.text("Folders registered on this computer. Importing indexes your audio files; it does not upload them to an online account.", "管理此电脑上的音乐文件夹。导入仅建立文件索引，不会上传到在线账号。")
        }
        RowLayout {
            spacing: 12
            MusicActionButton { text: Language.text("Add music folder", "添加音乐文件夹"); enabled: page.music.ready; onClicked: page.importRequested() }
            MusicActionButton { text: page.music.scanning ? Language.text("Scanning…", "正在扫描…") : Language.text("Rescan", "重新扫描"); enabled: !page.music.scanning && page.music.libraryFolders.length > 0; onClicked: page.music.rescanLibrary() }
        }
        Label { visible: page.music.libraryFolders.length === 0; text: Language.text("No music folders added yet.", "尚未添加音乐文件夹。"); color: AppTheme.mutedText }
        Repeater {
            model: page.music.libraryFolders
            delegate: ColumnLayout {
                id: folderRow
                required property string modelData
                Layout.fillWidth: true; spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    Label { Layout.fillWidth: true; text: folderRow.modelData; wrapMode: Text.WrapAnywhere; color: AppTheme.text; font.pixelSize: 14 }
                    MusicActionButton {
                        text: Language.text("Remove", "移除"); enabled: !page.music.scanning
                        onClicked: { removeFolder.path = folderRow.modelData; removeFolder.open() }
                    }
                }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: AppTheme.border }
            }
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; color: AppTheme.mutedText; font.pixelSize: 13
            text: Language.text("Songs, albums and artists use imported file tags. Missing artwork uses the existing placeholder. This page lists registered roots, rather than browsing subfolders.", "歌曲、专辑和艺术家信息来自文件标签，缺失封面时显示占位图。此处列出已添加的根文件夹。")
        }
        Label {
            visible: page.music.scanning; Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: page.music.scanStatus; color: AppTheme.mutedText
        }
        Label {
            visible: page.music.scanWarnings.length > 0; Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: Language.text("Some files could not be imported:\n", "部分文件无法导入：\n") + page.music.scanWarnings.join("\n")
            color: AppTheme.mutedText; font.pixelSize: 12
        }
        Item { Layout.preferredHeight: page.bottomContentInset; Layout.fillWidth: true }
    }
    LiquidDialog {
        id: removeFolder
        property string path: ""
        parent: Overlay.overlay; anchors.centerIn: parent; width: 420; modal: true
        title: Language.text("Remove music folder?", "移除音乐文件夹？")
        standardButtons: Dialog.Ok | Dialog.Cancel
        contentItem: Label {
            text: removeFolder.path + "\n\n" + Language.text("Removes its songs from this library and device playlists. Files on disk are not deleted.", "从曲库和本机歌单中移除此文件夹的歌曲，不删除磁盘文件。")
            color: AppTheme.text; wrapMode: Text.WrapAnywhere
        }
        onAccepted: page.music.removeLibraryFolder(path)
    }

}
