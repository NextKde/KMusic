import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
ColumnLayout {
    id: page
    required property var music
    property real bottomContentInset: 0
    property alias queryText: query.text
    function openQualityMenu() { qualitySelect.openMenu() }
    spacing: 12
    RowLayout {
        Layout.fillWidth: true; Layout.leftMargin: 32; Layout.rightMargin: 32; Layout.topMargin: 24
        LiquidTextField {
            shadowEnabled: true; shadowOpacity: .06
            id: query
            Layout.fillWidth: true; materialForm: false; liquidFinish: true
            placeholderText: qsTr("Search songs on NetEase")
            onAccepted: page.music.searchOnline(text)
        }
        MusicActionButton { text: page.music.onlineSearching ? qsTr("Searching…") : qsTr("Search"); enabled: query.text.trim().length > 0 && !page.music.onlineSearching; onClicked: page.music.searchOnline(query.text) }
        MusicSelect {
            id: qualitySelect
            model: ["Standard", "320k", "Lossless"]; materialForm: false; appearanceMode: AppTheme.appearanceMode
            currentIndex: page.music.onlineQuality === "320k" ? 1 : page.music.onlineQuality === "flac" ? 2 : 0
            onActivated: index => page.music.onlineQuality = ["128k", "320k", "flac"][index]
        }
    }
    Label {
        Layout.leftMargin: 32; Layout.rightMargin: 32; Layout.fillWidth: true
        text: page.music.onlineError || qsTr("NetEase · playback may be restricted to a preview or require an account")
        color: page.music.onlineError.length ? AppTheme.destructive : AppTheme.mutedText
        wrapMode: Text.WordWrap; font.pixelSize: 12
    }
    SongsPage {
        Layout.fillWidth: true; Layout.fillHeight: true
        music: page.music; bottomContentInset: page.bottomContentInset; trackModel: page.music.onlineModel; onlineView: true
        heading: qsTr("Online search")
        onDetailsRequested: row => { page.music.requestOnlineDetail(row); details.open() }
    }
    LiquidDialog {
        id: details
        anchors.centerIn: parent; width: 440; modal: true; title: qsTr("Song details"); standardButtons: Dialog.Close
        contentItem: ColumnLayout {
            spacing: 14
            Artwork { Layout.preferredWidth: 160; Layout.preferredHeight: 160; source: page.music.onlineDetail.artwork || ""; title: page.music.onlineDetail.title || "" }
            Label { text: page.music.onlineDetail.loading ? qsTr("Loading details…") : page.music.onlineDetail.error || page.music.onlineDetail.title || ""; color: AppTheme.text; font.pixelSize: 22; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Label { text: page.music.onlineDetail.artist || ""; color: AppTheme.mutedText; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Label { text: page.music.onlineDetail.album || ""; color: AppTheme.mutedText; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Label { text: "NetEase"; color: AppTheme.mutedText; font.pixelSize: 11 }
        }
    }
}
