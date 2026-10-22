import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
import "UiLanguage.mjs" as Language

ScrollView {
    id: page
    property string title: ""
    property var groups: []
    property real bottomContentInset: 0
    signal entryRequested(var entry)
    contentWidth: availableWidth
    clip: true
    ColumnLayout {
        x: 32; width: page.availableWidth - 64; spacing: 20
        Label { Layout.topMargin: 24; text: page.title; color: AppTheme.text; font.pixelSize: 28; font.weight: Font.Bold }
        Repeater {
            model: page.groups
            delegate: ColumnLayout {
                id: group
                required property var modelData
                Layout.fillWidth: true; spacing: 8
                Label { Layout.topMargin: 12; text: group.modelData.title; color: AppTheme.mutedText; font.pixelSize: 14; font.weight: Font.DemiBold }
                Repeater {
                    model: group.modelData.entries
                    delegate: MusicNavigationButton {
                        required property var modelData
                        Layout.fillWidth: true; checkable: false
                        text: Language.chinese() ? modelData.zh || modelData.en : modelData.en || modelData.zh
                        onClicked: page.entryRequested(modelData)
                    }
                }
            }
        }
        Item { Layout.preferredHeight: page.bottomContentInset; Layout.fillWidth: true }
    }
}
