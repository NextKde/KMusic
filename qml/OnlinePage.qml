import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
Item {
    id: page
    required property var music
    property real bottomContentInset: 0
    property alias queryText: query.text
    function openQualityMenu() { qualitySelect.openMenu() }
    SongsPage {
        id: songContent
        anchors.fill: parent
        showHeading: false; topContentInset: fixedHeader.height + 12
        music: page.music; bottomContentInset: page.bottomContentInset; trackModel: page.music.onlineModel; onlineView: true
        onDetailsRequested: row => { page.music.requestOnlineDetail(row); details.open() }
    }
    // Independent sibling source: no header controls, no recursive sampling.
    LiquidBackdrop { id: headerBackdrop; sourceItem: songContent; registerAsDefault: false; blur: .18 }
    Item {
        id: fixedHeader
        width: parent.width; height: 140
        LiquidSurface {
            anchors.fill: parent; radius: 0; backdrop: headerBackdrop
            tintColor: AppTheme.dark ? "#1c1c1e" : "#ffffff"; tintStrength: .82
            readability: 0; blurStrength: .12; refractionStrength: 2; reflectionStrength: .22
        }
        ColumnLayout {
            anchors.fill: parent; anchors.leftMargin: 32; anchors.rightMargin: 32; anchors.topMargin: 18; anchors.bottomMargin: 10; spacing: 9
            Label { text: qsTr("Online search"); color: AppTheme.text; font.pixelSize: 26; font.weight: Font.Bold }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                LiquidTextField {
                    id: query
                    Layout.fillWidth: true; materialForm: true
                    placeholderText: qsTr("Search songs on NetEase")
                    onAccepted: page.music.searchOnline(text)
                }
                MusicActionButton { text: page.music.onlineSearching ? qsTr("Searching…") : qsTr("Search"); enabled: query.text.trim().length > 0 && !page.music.onlineSearching; onClicked: page.music.searchOnline(query.text) }
                MusicSelect {
                    id: qualitySelect
                    model: ["Standard", "320k", "Lossless"]; materialForm: true; appearanceMode: AppTheme.appearanceMode
                    currentIndex: page.music.onlineQuality === "320k" ? 1 : page.music.onlineQuality === "flac" ? 2 : 0
                    onActivated: index => page.music.onlineQuality = ["128k", "320k", "flac"][index]
                }
            }
            Label {
                Layout.fillWidth: true
                text: page.music.onlineError || qsTr("NetEase · playback may be restricted to a preview or require an account")
                color: page.music.onlineError.length ? AppTheme.destructive : AppTheme.mutedText
                elide: Text.ElideRight; font.pixelSize: 11
            }
        }
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
