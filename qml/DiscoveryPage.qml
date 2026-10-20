import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
ScrollView {
    id: page
    required property var music
    signal importRequested()
    signal albumRequested(string filter, string title)
    signal fixtureRequested(string title)
    clip: true
    contentWidth: availableWidth
    ColumnLayout {
        width: page.availableWidth - 64; x: 32; spacing: 20
        Item { height: 10 }
        Label { text: qsTr("New"); color: AppTheme.text; font.pixelSize: 34; font.weight: Font.Bold }
        Rectangle { Layout.fillWidth: true; height: 1; color: AppTheme.border }
        RowLayout {
            Layout.fillWidth: true; spacing: 24
            Repeater {
                model: [
                    { label: "EDITOR’S SELECTION · OFFLINE PREVIEW", title: "A little closer", subtitle: "Space to slow down. Sounds to stay with.", first: "#cb7866", second: "#503b56" },
                    { label: "FRESH PERSPECTIVES · OFFLINE PREVIEW", title: "After the blue hour", subtitle: "A new view of your evening.", first: "#507ba1", second: "#1c294b" }
                ]
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 5
                    Label { text: modelData.label; color: AppTheme.mutedText; font.pixelSize: 10; font.weight: Font.DemiBold }
                    Label { text: modelData.title; color: AppTheme.text; font.pixelSize: 21; font.weight: Font.DemiBold }
                    Label { Layout.fillWidth: true; text: modelData.subtitle; color: AppTheme.mutedText; font.pixelSize: 12; elide: Text.ElideRight }
                    AlbumTile {
                        Layout.fillWidth: true; Layout.topMargin: 8
                        title: modelData.title; subtitle: qsTr("Original visual collection · no audio"); wide: true
                        first: modelData.first; second: modelData.second
                        onClicked: page.fixtureRequested(title)
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Label { text: qsTr("Made for a moment"); color: AppTheme.text; font.pixelSize: 22; font.weight: Font.Bold; Layout.fillWidth: true }
            Label { text: qsTr("Offline visual preview"); color: AppTheme.mutedText; font.pixelSize: 11 }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 20
            Repeater {
                model: [
                    {title:"Soft focus", subtitle:"Quiet / Ambient", a:"#86aca6", b:"#3b6269"},
                    {title:"City currents", subtitle:"Electronic / After dark", a:"#af6f8d", b:"#423960"},
                    {title:"Open horizons", subtitle:"Alternative / Discovery", a:"#d5ac70", b:"#856048"},
                    {title:"Morning light", subtitle:"Acoustic / Slow start", a:"#b5a4bb", b:"#7e758f"}
                ]
                delegate: AlbumTile {
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    title: modelData.title; subtitle: modelData.subtitle; first: modelData.a; second: modelData.b
                    onClicked: page.fixtureRequested(title)
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Label { text: qsTr("From your library"); color: AppTheme.text; font.pixelSize: 22; font.weight: Font.Bold; Layout.fillWidth: true }
            LiquidActionButton { text: qsTr("Import music"); onClicked: page.importRequested() }
        }
        Label {
            visible: page.music.albums.length === 0
            text: qsTr("Bring your own collection. Import a folder to see albums and start listening.")
            color: AppTheme.mutedText; wrapMode: Text.WordWrap; Layout.fillWidth: true; Layout.bottomMargin: 24
        }
        Repeater {
            model: page.music.albums.slice(0, 6)
            delegate: LiquidNavigationButton {
                required property var modelData
                Layout.fillWidth: true
                text: modelData.name + "  ·  " + modelData.subtitle + "  ·  " + modelData.count + " tracks"
                onClicked: page.albumRequested(modelData.filterValue, modelData.name)
            }
        }
        Item { height: 24 }
    }
}
