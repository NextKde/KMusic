import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
ColumnLayout {
    id: page
    required property var music
    property real bottomContentInset: 0
    property real topContentInset: 0
    property bool showHeading: true
    readonly property alias reviewList: list
    property var trackModel: music.libraryModel
    property string heading: qsTr("Songs")
    property bool onlineView: false
    property bool albumView: false
    property Component headerContent: null
    property string emptyMessage: page.queueView ? qsTr("Your queue is empty") : qsTr("No songs here yet")
    signal detailsRequested(int row)
    signal saveToPlaylistRequested(int row)
    property bool queueView: false
    property bool playlistView: false
    property double playlistId: -1
    signal importRequested()
    signal addToPlaylistRequested(double trackId)
    spacing: 14
    RowLayout {
        visible: page.showHeading
        Layout.fillWidth: true; Layout.topMargin: 24; Layout.leftMargin: 32; Layout.rightMargin: 32
        Label { text: page.heading; color: AppTheme.text; font.pixelSize: 32; font.weight: Font.Bold; Layout.fillWidth: true }
        MusicActionButton { visible: !page.queueView && !page.onlineView; text: qsTr("Import"); onClicked: page.importRequested() }
        MusicActionButton { visible: page.queueView; text: qsTr("Clear queue"); enabled: page.trackModel.count > 0; onClicked: page.music.clearQueue() }
    }
    Label { visible: page.showHeading; Layout.leftMargin: 32; text: page.trackModel.count === 1 ? qsTr("1 song") : qsTr("%1 songs").arg(page.trackModel.count); color: AppTheme.mutedText }
    Rectangle { visible: page.showHeading; Layout.fillWidth: true; height: 1; color: AppTheme.border; Layout.leftMargin: 32; Layout.rightMargin: 32 }
    ListView {
        id: list
        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
        header: Loader {
            width: list.width
            sourceComponent: page.headerContent
            height: item ? item.implicitHeight : page.topContentInset
        }
        model: page.trackModel
        leftMargin: 24; rightMargin: 24
        footer: Item { width: list.width; height: page.bottomContentInset }
        ScrollBar.vertical: ScrollBar {}
        delegate: ItemDelegate {
            id: row
            required property int index
            required property double trackId
            required property string title
            required property string artist
            required property string album
            required property string durationText
            required property string artworkUrl
            required property string providerId
            objectName: index === 0 ? (page.albumView ? "reviewAlbumFirstSong" : page.playlistView ? "reviewLocalPlaylistFirstSong" : "") : ""
            width: list.width - 48; x: 24; height: 62
            hoverEnabled: true
            onClicked: {
                if (page.albumView) page.music.playOnlineAlbumRow(index)
                else if (page.onlineView) page.music.playOnlineRow(index)
                else if (page.queueView) page.music.playQueueRow(index)
                else if (page.playlistView) page.music.playPlaylistRow(index)
                else page.music.playTrack(trackId)
            }
            background: Rectangle { radius: 6; color: row.hovered ? MusicColors.hoverFill : row.index % 2 ? MusicColors.rowFill : "transparent" }
            contentItem: RowLayout {
                spacing: 12
                Label { text: row.index + 1; color: AppTheme.mutedText; Layout.preferredWidth: 22; horizontalAlignment: Text.AlignHCenter }
                Artwork { source: row.artworkUrl; title: row.title; Layout.preferredWidth: 40; Layout.preferredHeight: 40; radius: 5 }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 3
                    Label { text: row.title; color: page.music.currentTrackId > 0 && (page.music.currentTrackId === row.trackId || ((page.onlineView || page.albumView) && row.providerId === page.music.currentProviderId)) ? MusicColors.sidebarAccent : AppTheme.text; Layout.fillWidth: true; elide: Text.ElideRight; font.weight: Font.Medium }
                    Label { text: row.artist; color: AppTheme.mutedText; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                }
                Label { text: row.album; color: AppTheme.mutedText; Layout.preferredWidth: Math.max(60, list.width * .17); elide: Text.ElideRight }
                Label { text: row.durationText; color: AppTheme.mutedText; Layout.preferredWidth: 45 }
                MusicActionButton { iconOnly: true;
                    objectName: page.albumView && row.index === 0 ? "reviewAlbumEnqueueFirst" : ""
                    text: page.queueView ? "−" : "+"; implicitWidth: 34; implicitHeight: 30
                    Accessible.name: page.queueView ? qsTr("Remove from queue") : qsTr("Add to queue")
                    onClicked: { if (page.queueView) page.music.removeQueueRow(row.index); else if (page.albumView) page.music.enqueueAlbumRow(row.index); else if (page.onlineView) page.music.enqueueOnlineRow(row.index); else page.music.enqueueTrack(row.trackId) }
                }
                MusicActionButton {
                    iconOnly: true; iconName: "playlist"; implicitWidth: 30; implicitHeight: 30
                    objectName: row.index === 0 ? (page.albumView ? "reviewSaveAlbumFirst" : "reviewSaveOnlineFirst") : ""
                    visible: page.onlineView || page.albumView
                    Accessible.name: qsTr("Save to local playlist")
                    onClicked: page.saveToPlaylistRequested(row.index)
                }
                MusicActionButton {
                    iconOnly: true
                    visible: !page.queueView && !page.albumView; text: "···"; implicitWidth: 34; implicitHeight: 30
                    Accessible.name: page.onlineView ? qsTr("Song details") : qsTr("Add to playlist"); onClicked: { if (page.onlineView) page.detailsRequested(row.index); else page.addToPlaylistRequested(row.trackId) }
                }
            }
        }
        Label {
            anchors.centerIn: parent; visible: list.count === 0
            text: page.emptyMessage; width: parent.width - 64; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
            color: AppTheme.mutedText; font.pixelSize: 18
        }
    }
}
