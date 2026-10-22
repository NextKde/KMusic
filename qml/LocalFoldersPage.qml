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
        Label { text: qsTr("Local Music"); color: AppTheme.mutedText; font.pixelSize: 13 }
        Label { text: qsTr("Music folders"); color: AppTheme.text; font.pixelSize: 26; font.weight: Font.Bold }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; color: AppTheme.mutedText
            text: qsTr("Folders registered on this computer. Importing indexes your audio files; it does not upload them to an online account.")
        }
        RowLayout {
            spacing: 12
            MusicActionButton { text: qsTr("Add music folder"); onClicked: page.importRequested() }
            MusicActionButton { text: page.music.scanning ? qsTr("Scanning…") : qsTr("Rescan"); enabled: !page.music.scanning && page.music.libraryFolders.length > 0; onClicked: page.music.rescanLibrary() }
        }
        Label { visible: page.music.libraryFolders.length === 0; text: qsTr("No music folders added yet."); color: AppTheme.mutedText }
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
            text: qsTr("Songs, albums and artists use imported file tags. Missing artwork uses the existing placeholder. This page lists registered roots, rather than browsing subfolders.")
        }
        Item { Layout.preferredHeight: page.bottomContentInset; Layout.fillWidth: true }
    }
}
