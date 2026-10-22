import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui

LiquidDialog {
    id: dialog
    property string sourceId: ""
    property string sourceName: ""
    signal useExample(string alias)
    anchors.centerIn: parent
    width: Math.min(440, parent ? parent.width - 32 : 440)
    modal: true
    title: qsTr("Media source · connection preview")
    standardButtons: Dialog.Cancel
    onOpened: aliasField.text = sourceName + " · Demo"
    contentItem: ColumnLayout {
        spacing: 16
        Label { Layout.fillWidth: true; text: dialog.sourceName; color: AppTheme.text; font.pixelSize: 17; font.weight: Font.DemiBold }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: dialog.sourceId === "webdav" ? qsTr("A remote file source starts with folders and audio files. Music categories require a separate index.") : qsTr("A music server provides its own library, user account and available categories.")
            color: AppTheme.mutedText
        }
        Label { text: qsTr("Display name for this example"); color: AppTheme.text }
        LiquidTextField { id: aliasField; Layout.fillWidth: true; materialForm: true; maximumLength: 60 }
        Label { text: qsTr("Example address · read only"); color: AppTheme.text }
        LiquidTextField {
            Layout.fillWidth: true; materialForm: true; readOnly: true
            text: dialog.sourceId === "webdav" ? "https://files.example.invalid/music/" : "https://music.example.invalid/"
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: qsTr("This preview does not connect, save credentials or fetch a library. The example name lasts only for this app session.")
            color: AppTheme.mutedText
        }
        MusicActionButton {
            text: qsTr("Use example name")
            enabled: aliasField.text.trim().length > 0
            onClicked: { dialog.useExample(aliasField.text.trim()); dialog.close() }
        }
    }
}
