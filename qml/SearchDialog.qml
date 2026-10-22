import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Kos.Ui
import "UiLanguage.mjs" as Language
import "SearchHistory.mjs" as SearchHistory

LiquidDialog {
    id: dialog
    property string sourceId: "netease"
    property string initialQuery: ""
    readonly property var history: readHistory()[sourceId] || []
    signal searchRequested(string query)
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(480, parent ? parent.width - 64 : 480)
    modal: true; dim: true
    title: sourceId === "local" ? Language.text("Search local music", "搜索本地音乐") : Language.text("Search music", "搜索音乐")
    standardButtons: Dialog.Close
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    onOpened: { query.text = initialQuery; query.forceActiveFocus(); query.selectAll() }
    Settings {
        id: saved
        category: "SearchHistory"
        property string entriesJson: "{}"
    }
    function clearAllHistory() { saved.entriesJson = "{}"; saved.sync() }
    function readHistory() { return SearchHistory.read(saved.entriesJson) }
    function storeHistory(items) {
        const all = readHistory()
        all[sourceId] = items
        saved.entriesJson = JSON.stringify(all)
        saved.sync()
    }
    function submit(text) {
        const value = text.trim().slice(0, 200)
        if (!value || (sourceId !== "local" && sourceId !== "netease")) return
        storeHistory([value].concat(history.filter(item => typeof item === "string" && item.toLowerCase() !== value.toLowerCase())).slice(0, 20))
        searchRequested(value)
        close()
    }
    contentItem: ColumnLayout {
        spacing: 14
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            MusicTextField {
                searchField: true
                id: query
                Layout.fillWidth: true; implicitHeight: 36
                materialForm: false; liquidFinish: true; liquidIntensity: "strong"
                backdrop: dialog.contentBackdrop
                placeholderText: Language.text("Songs, artists or albums", "歌曲、艺术家或专辑")
                maximumLength: 200; font.pixelSize: 13
                onAccepted: dialog.submit(text)
            }
            MusicActionButton { materialForm: false; liquidIntensity: "strong"; backdrop: dialog.contentBackdrop; text: Language.text("Search", "搜索"); enabled: query.text.trim().length > 0; onClicked: dialog.submit(query.text) }
        }
        RowLayout {
            Layout.fillWidth: true
            Label { text: Language.text("Recent searches", "最近搜索"); color: AppTheme.mutedText; font.pixelSize: 13; Layout.fillWidth: true }
            MusicActionButton { text: Language.text("Clear", "清空"); visible: dialog.history.length > 0; implicitHeight: 28; onClicked: dialog.storeHistory([]) }
        }
        Label { visible: dialog.history.length === 0; text: Language.text("No search history yet.", "暂无搜索历史。"); color: AppTheme.mutedText; font.pixelSize: 13 }
        ListView {
            Layout.fillWidth: true; Layout.preferredHeight: Math.min(count, 6) * 36
            visible: count > 0; clip: true
            model: dialog.history
            ScrollBar.vertical: ScrollBar {}
            delegate: RowLayout {
                required property string modelData
                required property int index
                width: ListView.view.width; height: 36
                MusicNavigationButton {
                    Layout.fillWidth: true; text: modelData
                    onClicked: dialog.submit(modelData)
                }
                MusicActionButton {
                    text: "×"; implicitWidth: 28; implicitHeight: 28
                    Accessible.name: Language.text("Remove search", "移除搜索记录")
                    onClicked: dialog.storeHistory(dialog.history.filter((_, row) => row !== index))
                }
            }
        }
    }
}
