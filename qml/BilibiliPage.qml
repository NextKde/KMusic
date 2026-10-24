import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
import "UiLanguage.mjs" as Language
Item {
    id: page
    required property var backend
    property real bottomContentInset: 100
    property alias queryText: query.text
    signal discoverRequested()
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 28; spacing: 14
        RowLayout {
            Layout.fillWidth: true
            MusicActionButton { text: Language.text("Discover", "发现"); onClicked: page.discoverRequested() }
            MusicTextField {
                id: query; objectName: "bilibiliSearchInput"; Layout.fillWidth: true
                searchField: true; materialForm: true; maximumLength: 200
                placeholderText: Language.text("Search videos or paste a BV link", "搜索视频，或粘贴 BV 链接")
                onAccepted: page.backend.search(text)
            }
            MusicActionButton { text: Language.text("Search", "搜索"); enabled: !page.backend.busy && query.text.trim().length > 0; onClicked: page.backend.search(query.text) }
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: page.backend.error || (page.backend.busy ? Language.text("Searching…", "正在搜索…") : Language.text("Video audio · select a video to play, or choose a part.", "视频音频 · 选择视频播放，也可以选择分 P。"))
            color: page.backend.error ? AppTheme.destructive : AppTheme.mutedText
            textFormat: Text.PlainText
        }
        ListView {
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 6
            model: page.backend.results
            ScrollBar.vertical: ScrollBar {}
            footer: Item { width: parent.width; height: page.bottomContentInset + 48
                MusicActionButton { anchors.horizontalCenter: parent.horizontalCenter; visible: page.backend.hasMore; enabled: !page.backend.busy; text: Language.text("Load more", "加载更多"); onClicked: page.backend.loadMore() }
            }
            delegate: RowLayout {
                required property var modelData
                required property int index
                width: ListView.view.width - 12; height: 66; spacing: 12
                Artwork { Layout.preferredWidth: 80; Layout.preferredHeight: 54; source: modelData.artwork; title: modelData.title }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 4
                    Label { Layout.fillWidth: true; text: modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; color: AppTheme.text; font.weight: Font.Medium }
                    Label { Layout.fillWidth: true; text: modelData.creator; textFormat: Text.PlainText; elide: Text.ElideRight; color: AppTheme.mutedText }
                }
                MusicActionButton { text: Language.text("Parts", "分 P"); onClicked: { page.backend.openParts(index); partsDialog.open() } }
                MusicActionButton { text: Language.text("Play", "播放"); onClicked: page.backend.play(index) }
            }
        }
    }
    LiquidDialog {
        id: partsDialog; parent: Overlay.overlay; anchors.centerIn: parent
        title: Language.text("Video parts", "视频分 P"); width: 520; height: 400; modal: true; standardButtons: Dialog.Close
        contentItem: ListView {
            clip: true; model: page.backend.parts; spacing: 6
            delegate: MusicActionButton {
                required property var modelData
                required property int index
                width: ListView.view.width
                text: (index + 1) + ". " + modelData.title
                onClicked: { page.backend.playPart(index); partsDialog.close() }
            }
        }
    }
}
