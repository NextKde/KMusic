import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
Item {
    id: page
    required property var music
    property real bottomContentInset: 0
    signal collectionRequested(int row)
    signal saveToPlaylistRequested(int row)
    readonly property var reviewList: music.onlineSearchKind === "song" ? songContent.reviewList : collections
    property alias queryText: query.text
    function openQualityMenu() { qualitySelect.openMenu() }
    readonly property bool canSubmitSearch: query.text.trim().length > 0 && !music.onlineSearching
    function submitSearch() {
        if (!canSubmitSearch) return
        music.searchOnline(query.text.trim())
    }
    Item {
        id: searchScrollScene
        anchors.fill: parent
        Rectangle { anchors.fill: parent; color: AppTheme.dark ? "#1c1c1e" : "#ffffff" }
    SongsPage {
        id: songContent
        anchors.fill: parent
        visible: page.music.onlineSearchKind === "song"
        showHeading: false; topContentInset: fixedHeader.height + 12
        music: page.music; bottomContentInset: page.bottomContentInset; trackModel: page.music.onlineModel; onlineView: true
        onSaveToPlaylistRequested: row => page.saveToPlaylistRequested(row)
        onDetailsRequested: row => { page.music.requestOnlineDetail(row); details.open() }
    }
    CollectionList {
        id: collections
        anchors.fill: parent; visible: page.music.onlineSearchKind !== "song"
        rows: page.music.onlineCollections; topContentInset: fixedHeader.height + 12
        bottomContentInset: page.bottomContentInset
        emptyMessage: page.music.onlineSearching ? qsTr("Searching…") : page.music.onlineError || qsTr("No results. Try another search.")
        onActivated: row => page.collectionRequested(row)
    }
    }
    // Independent sibling source: no header controls, no recursive sampling.
    LiquidBackdrop { id: headerBackdrop; sourceItem: searchScrollScene; registerAsDefault: false; blur: .18 }
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
            RowLayout {
                Layout.fillWidth: true
                Label { text: qsTr("Online search"); color: AppTheme.text; font.pixelSize: 26; font.weight: Font.Bold; Layout.fillWidth: true }
                MusicSelect {
                    model: [qsTr("Songs"), qsTr("Playlists"), qsTr("Albums"), qsTr("Artists")]; materialForm: true
                    currentIndex: page.music.onlineSearchKind === "playlist" ? 1 : page.music.onlineSearchKind === "album" ? 2 : page.music.onlineSearchKind === "artist" ? 3 : 0
                    onActivated: index => { page.music.onlineSearchKind = ["song", "playlist", "album", "artist"][index]; page.music.searchOnline(query.text) }
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                MusicTextField {
                    searchField: true
                    id: query; objectName: "reviewOnlineQuery"
                    Layout.fillWidth: true; materialForm: true
                    placeholderText: qsTr("Search NetEase")
                    onAccepted: page.submitSearch()
                }
                MusicActionButton { text: page.music.onlineSearching ? qsTr("Searching…") : qsTr("Search"); enabled: page.canSubmitSearch; onClicked: page.submitSearch() }
                MusicSelect {
                    id: qualitySelect
                    visible: page.music.onlineSearchKind === "song"
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
