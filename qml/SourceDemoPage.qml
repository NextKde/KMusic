import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui

ScrollView {
    id: page
    property string sourceId: ""
    property string entryId: ""
    property string sourceName: ""
    property string instanceName: ""
    readonly property bool mediaSource: ["navidrome", "jellyfin", "webdav"].indexOf(sourceId) >= 0
    property string entryName: ""
    property string connectionStatus: "prototype"
    property bool requiresLogin: false
    property bool authenticated: false
    property real bottomContentInset: 0
    property string prototypeContentKind: "video"
    property string prototypeQuery: ""
    property string submittedPrototypeQuery: ""
    onSourceIdChanged: { prototypeQuery = ""; submittedPrototypeQuery = ""; prototypeContentKind = "video" }
    onEntryIdChanged: { prototypeQuery = ""; submittedPrototypeQuery = "" }
    signal accountRequested()
    signal connectionRequested()
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
    function biliDescription() {
        switch (entryId) {
        case "recommend": return qsTr("Recommended videos belong to Bilibili. They are not a list of music albums or daily songs from NetEase.")
        case "search": return qsTr("Choose videos, uploaders or collections. This preview search stays inside Bilibili and does not call the NetEase or local music search.")
        case "uploaders": return qsTr("An uploader is a Bilibili creator. Uploaders are not automatically music artists and their uploads are not automatically albums.")
        case "collections": return qsTr("Collections group Bilibili videos. They keep their video identities and are not converted into NetEase playlists.")
        case "favorites": return qsTr("Favorite folders belong to a Bilibili account. They are separate from NetEase likes and favorites stored on this device.")
        case "history": return qsTr("Watch history belongs to a Bilibili account. It is separate from music playback history recorded by KMusic.")
        default: return ""
        }
    }
    function mediaDescription() {
        if (sourceId === "webdav") return qsTr("WebDAV exposes folders and files. It does not provide artist, album, recommendation or account-favorite categories by itself.")
        if (sourceId === "navidrome") return qsTr("Navidrome / OpenSubsonic is a personal music server. Albums, artists, playlists and favorites belong to that server and its user; available categories depend on the connection.")
        return qsTr("Jellyfin provides server media libraries. KMusic would select a music library within that server, with its own account and library scope.")
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
            text: page.sourceId === "netease" ? page.neteaseDescription() : page.sourceId === "bilibili" ? page.biliDescription() : page.mediaSource ? page.mediaDescription() : qsTr("This source has its own library and account scope.")
            color: AppTheme.mutedText; font.pixelSize: 14
        }
        ColumnLayout {
            visible: page.mediaSource
            Layout.fillWidth: true; spacing: 12
            Label { text: qsTr("Source connection"); color: AppTheme.text; font.pixelSize: 17; font.weight: Font.DemiBold }
            Label {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                text: page.instanceName.length > 0 ? qsTr("%1 · example only, not connected").arg(page.instanceName) : qsTr("No server is connected. Select an example to preview the connection menu.")
                color: AppTheme.mutedText
            }
            MusicActionButton { text: qsTr("Preview connection"); onClicked: page.connectionRequested() }
            Label {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                text: page.sourceId === "webdav" ? qsTr("Browse: folders → files. Search would stay in this file source after indexing.") : qsTr("Browse: server → music library → albums / artists / playlists. Search would stay inside this server.")
                color: AppTheme.mutedText
            }
        }
        ColumnLayout {
            visible: page.sourceId === "bilibili" && page.entryId === "search"
            Layout.fillWidth: true; spacing: 12
            Label { text: qsTr("Bilibili search · interactive preview"); color: AppTheme.text; font.pixelSize: 17; font.weight: Font.DemiBold }
            Flow {
                Layout.fillWidth: true; spacing: 8
                Repeater {
                    model: [{id:"video", title:qsTr("Videos")}, {id:"uploader", title:qsTr("Uploaders")}, {id:"collection", title:qsTr("Collections")}]
                    delegate: MusicActionButton {
                        required property var modelData
                        text: modelData.title; checkable: true
                        checked: page.prototypeContentKind === modelData.id
                        onClicked: { page.prototypeContentKind = modelData.id; page.submittedPrototypeQuery = "" }
                    }
                }
            }
            LiquidTextField {
                Layout.fillWidth: true
                materialForm: true
                text: page.prototypeQuery
                placeholderText: qsTr("Search Bilibili · demo only")
                onTextEdited: page.prototypeQuery = text
                onAccepted: page.submittedPrototypeQuery = text.trim()
            }
            MusicActionButton {
                text: qsTr("Preview scoped search")
                enabled: page.prototypeQuery.trim().length > 0
                onClicked: page.submittedPrototypeQuery = page.prototypeQuery.trim()
            }
            Label {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                visible: page.submittedPrototypeQuery.length > 0
                text: qsTr("Bilibili / %1 / %2 · demo only; no request sent and no results fabricated.").arg(page.prototypeContentKind).arg(page.submittedPrototypeQuery)
                color: AppTheme.mutedText
            }
        }
        MusicActionButton {
            visible: page.sourceId === "netease" && page.requiresLogin && !page.authenticated
            text: qsTr("Sign in to NetEase")
            onClicked: page.accountRequested()
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: page.sourceId === "bilibili"
                ? qsTr("Bilibili integration is not available in this build. No Bilibili session, favorites, history or video playback is being simulated; NetEase sign-in cannot sign you into Bilibili.")
                : page.mediaSource ? qsTr("Media source adapters are not connected in this build. Example connections do not contain a real server, account or music library.")
                : qsTr("Menu preview only. Account collections have not been fetched, and no recommendations, playlists or playback results are being fabricated. Signing in does not yet connect these collection pages.")
            color: AppTheme.mutedText; font.pixelSize: 13
        }
        Item { implicitHeight: page.bottomContentInset + 16 }
    }
}
