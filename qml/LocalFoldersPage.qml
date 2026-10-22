import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui

ScrollView {
    id: page
    required property var music
    property real bottomContentInset: 0
    signal importRequested()
    contentWidth: availableWidth
    clip: true
    ColumnLayout {
        width: page.availableWidth - 64; x: 32; spacing: 16
        Item { implicitHeight: 24 }
        Label { text: qsTr("本地音乐"); color: AppTheme.mutedText; font.pixelSize: 13 }
        Label { text: qsTr("音乐文件夹"); color: AppTheme.text; font.pixelSize: 26; font.weight: Font.Bold }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; color: AppTheme.mutedText
            text: qsTr("管理此电脑上的音乐文件夹。导入仅建立文件索引，不会上传到在线账号。")
        }
        RowLayout {
            spacing: 12
            MusicActionButton { text: qsTr("添加音乐文件夹"); onClicked: page.importRequested() }
            MusicActionButton { text: page.music.scanning ? qsTr("正在扫描…") : qsTr("重新扫描"); enabled: !page.music.scanning && page.music.libraryFolders.length > 0; onClicked: page.music.rescanLibrary() }
        }
        Label { visible: page.music.libraryFolders.length === 0; text: qsTr("尚未添加音乐文件夹。"); color: AppTheme.mutedText }
        Repeater {
            model: page.music.libraryFolders
            delegate: ColumnLayout {
                required property string modelData
                Layout.fillWidth: true; spacing: 12
                Label { Layout.fillWidth: true; text: modelData; wrapMode: Text.WrapAnywhere; color: AppTheme.text; font.pixelSize: 14 }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: AppTheme.border }
            }
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; color: AppTheme.mutedText; font.pixelSize: 13
            text: qsTr("歌曲、专辑和艺术家信息来自文件标签，缺失封面时显示占位图。此处列出已添加的根文件夹。")
        }
        Item { Layout.preferredHeight: page.bottomContentInset; Layout.fillWidth: true }
    }
}
