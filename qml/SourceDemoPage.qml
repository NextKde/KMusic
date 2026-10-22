import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui

ScrollView {
    id: page
    property string sourceId: ""
    property string entryId: ""
    property string sourceName: ""
    property string entryName: ""
    property string connectionStatus: "prototype"
    property bool requiresLogin: false
    property bool authenticated: false
    property real bottomContentInset: 0
    signal accountRequested()
    contentWidth: availableWidth
    clip: true
    function neteaseDescription() {
        switch (entryId) {
        case "daily": return qsTr("Daily recommendations belong to this NetEase account. They are different from the anonymous new-album feed.")
        case "liked": return qsTr("Songs liked in your NetEase account. This is separate from KMusic favorites stored on this device.")
        case "created": return qsTr("Playlists created by your NetEase account. Device playlists do not appear here.")
        case "collected": return qsTr("Playlists collected by your NetEase account. These are separate from playlists you created.")
        case "albums": return qsTr("Albums collected in your NetEase account, rather than album groups from imported files.")
        case "artists": return qsTr("Artists followed by your NetEase account, rather than artists extracted from local file tags.")
        case "history": return qsTr("Recently played songs from your NetEase account. This is neither the listening chart nor KMusic playback history on this device.")
        default: return ""
        }
    }
    ColumnLayout {
        width: page.availableWidth - 64; x: 32; spacing: 16
        Item { implicitHeight: 24 }
        Label { text: page.sourceName; color: AppTheme.mutedText; font.pixelSize: 13 }
        Label { Layout.fillWidth: true; text: page.entryName; color: AppTheme.text; font.pixelSize: 24; font.weight: Font.Bold; wrapMode: Text.WordWrap }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: page.sourceId === "netease" && page.requiresLogin
                ? page.authenticated ? qsTr("Account signed in · collection adapter not connected") : qsTr("Sign in to view this account section")
                : qsTr("Navigation demo · not connected")
            color: AppTheme.text; font.pixelSize: 15; font.weight: Font.DemiBold
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: page.sourceId === "netease" ? page.neteaseDescription() : qsTr("This source has its own library and account scope.")
            color: AppTheme.mutedText; font.pixelSize: 14
        }
        MusicActionButton {
            visible: page.sourceId === "netease" && page.requiresLogin && !page.authenticated
            text: qsTr("Sign in to NetEase")
            onClicked: page.accountRequested()
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: qsTr("Menu preview only. Account collections have not been fetched, and no recommendations, playlists or playback results are being fabricated. Signing in does not yet connect these collection pages.")
            color: AppTheme.mutedText; font.pixelSize: 13
        }
        Item { implicitHeight: page.bottomContentInset + 16 }
    }
}
