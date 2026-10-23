import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
import "UiLanguage.mjs" as Language
ListView {
    id: collections
    property var rows: []
    property real topContentInset: 0
    property real bottomContentInset: 0
    property Component headerContent: null
    property string firstControlName: "reviewCollectionFirst"
    property string emptyMessage: ""
    signal activated(int row)
    clip: true
    model: collections.rows
    header: Loader { width: collections.width; sourceComponent: collections.headerContent; height: item ? item.implicitHeight : collections.topContentInset }
    footer: Item { width: collections.width; height: collections.bottomContentInset }
    ScrollBar.vertical: ScrollBar {}
    delegate: ItemDelegate {
        id: resultRow
        required property var modelData
        required property int index
        objectName: index === 0 ? collections.firstControlName : ""
        x: 24; width: collections.width - 48; height: 82; hoverEnabled: true
        onClicked: collections.activated(index)
        background: Rectangle { radius: 6; color: resultRow.hovered ? MusicColors.hoverFill : "transparent" }
        contentItem: RowLayout {
            spacing: 14
            Artwork { Layout.preferredWidth: 58; Layout.preferredHeight: 58; source: resultRow.modelData.artwork || ""; title: resultRow.modelData.title; radius: 6 }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 6
                Label { Layout.fillWidth: true; textFormat: Text.PlainText; text: resultRow.modelData.title; color: AppTheme.text; font.pixelSize: 14; elide: Text.ElideRight }
                Label { Layout.fillWidth: true; textFormat: Text.PlainText; text: resultRow.modelData.kind === "playlist" ? Language.text("Playlist · %1", "歌单 · %1").arg(resultRow.modelData.artist) : resultRow.modelData.kind === "artist" ? Language.text("Artist", "歌手") + (resultRow.modelData.artist ? " · " + resultRow.modelData.artist : "") : Language.text("Album · %1", "专辑 · %1").arg(resultRow.modelData.artist); color: AppTheme.mutedText; font.pixelSize: 12; elide: Text.ElideRight }
            }
            Label { text: resultRow.modelData.totalCount > 0 ? (resultRow.modelData.totalCount === 1 ? Language.text("1 song", "1 首歌曲") : Language.text("%1 songs", "%1 首歌曲").arg(resultRow.modelData.totalCount)) : ""; color: AppTheme.mutedText; font.pixelSize: 11 }
            VectorIcon { name: "back"; rotation: 180; color: AppTheme.mutedText; size: 16 }
        }
    }
    Label { x: 32; y: Math.min(parent.height - implicitHeight - 20, (collections.headerItem ? collections.headerItem.height : 0) + 32); visible: collections.count === 0; text: collections.emptyMessage; width: parent.width - 64; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; color: AppTheme.mutedText }
}

