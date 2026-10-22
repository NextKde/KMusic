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
    title: qsTr("媒体源 · 连接示意")
    standardButtons: Dialog.Cancel
    onOpened: aliasField.text = sourceName + " · 示例"
    contentItem: ColumnLayout {
        spacing: 16
        Label { Layout.fillWidth: true; text: dialog.sourceName; color: AppTheme.text; font.pixelSize: 17; font.weight: Font.DemiBold }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: dialog.sourceId === "webdav" ? qsTr("远程文件来源提供文件夹和音频文件，音乐分类需要另外建立索引。") : qsTr("音乐服务器提供自己的音乐库、账号和分类。")
            color: AppTheme.mutedText
        }
        Label { text: qsTr("示例显示名称"); color: AppTheme.text }
        LiquidTextField { id: aliasField; Layout.fillWidth: true; materialForm: true; maximumLength: 60 }
        Label { text: qsTr("示例地址（只读）"); color: AppTheme.text }
        LiquidTextField {
            Layout.fillWidth: true; materialForm: true; readOnly: true
            text: dialog.sourceId === "webdav" ? "https://files.example.invalid/music/" : "https://music.example.invalid/"
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: qsTr("此示意不会连接服务器、保存凭据或获取音乐库。示例名称仅在本次运行中保留。")
            color: AppTheme.mutedText
        }
        MusicActionButton {
            text: qsTr("使用示例名称")
            enabled: aliasField.text.trim().length > 0
            onClicked: { dialog.useExample(aliasField.text.trim()); dialog.close() }
        }
    }
}
