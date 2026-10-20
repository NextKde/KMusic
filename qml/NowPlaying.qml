import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
RowLayout {
    id: page
    required property var music
    spacing: 44
    ColumnLayout {
        Layout.preferredWidth: Math.min(360, page.width * .43); Layout.leftMargin: 40; spacing: 22
        Artwork { Layout.fillWidth: true; Layout.preferredHeight: width; source: page.music.currentArtworkUrl; title: page.music.currentTitle; radius: 12 }
        Label { text: page.music.currentTitle || qsTr("Nothing playing"); color: AppTheme.text; font.pixelSize: 24; font.weight: Font.Bold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        Label { text: page.music.currentArtist; color: AppTheme.mutedText; font.pixelSize: 18 }
    }
    ListView {
        Layout.fillWidth: true; Layout.fillHeight: true; Layout.topMargin: 50; Layout.bottomMargin: 40; Layout.rightMargin: 36
        clip: true; model: page.music.lyrics; currentIndex: page.music.currentLyricIndex
        highlightRangeMode: ListView.ApplyRange; preferredHighlightBegin: height * .4; preferredHighlightEnd: height * .6
        delegate: Label {
            required property var modelData
            required property int index
            width: ListView.view.width; padding: 12
            text: modelData.text || ""; wrapMode: Text.WordWrap; font.pixelSize: index === page.music.currentLyricIndex ? 26 : 21
            color: index === page.music.currentLyricIndex ? AppTheme.text : AppTheme.mutedText
            font.weight: Font.DemiBold
        }
        Label { anchors.centerIn: parent; visible: parent.count === 0; text: page.music.lyricsLoading ? qsTr("Loading lyrics…") : qsTr("Lyrics unavailable"); color: AppTheme.mutedText }
    }
}
