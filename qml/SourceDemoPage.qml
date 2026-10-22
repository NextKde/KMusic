import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui

Item {
    id: page
    property string sourceName: ""
    property string entryName: ""
    property string connectionStatus: "prototype"
    ColumnLayout {
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 32; spacing: 16
        Label { text: page.sourceName; color: AppTheme.mutedText; font.pixelSize: 13 }
        Label { text: page.entryName; color: AppTheme.text; font.pixelSize: 24; font.weight: Font.Bold }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: qsTr("Navigation demo · this section is not connected yet. No account content or playable results are being simulated.")
            color: AppTheme.mutedText; font.pixelSize: 14
        }
    }
}
