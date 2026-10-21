import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
Rectangle {
    id: bar
    required property var music
    signal queueRequested()
    signal nowPlayingRequested()
    height: 84
    color: AppTheme.dark ? "#202326" : "#eff0f1"
    Rectangle { width: parent.width; height: 1; color: AppTheme.border; opacity: .55 }
    function stamp(ms) { const s = Math.floor(Math.max(0, ms) / 1000); return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + s % 60 }
    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 14
        Artwork { source: bar.music.currentArtworkUrl; title: bar.music.currentTitle; Layout.preferredWidth: 48; Layout.preferredHeight: 48; radius: 6 }
        ColumnLayout {
            Layout.preferredWidth: Math.max(145, bar.width * .16); Layout.maximumWidth: 220; spacing: 4
            Label { text: bar.music.currentTitle || qsTr("Nothing playing"); Layout.fillWidth: true; elide: Text.ElideRight; color: AppTheme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
            Label { text: bar.music.currentArtist || qsTr("Choose a song to begin"); Layout.fillWidth: true; elide: Text.ElideRight; color: AppTheme.mutedText; font.pixelSize: 11 }
        }
        Item { Layout.fillWidth: true }
        ColumnLayout {
            Layout.preferredWidth: Math.min(430, bar.width * .37); spacing: 0
            RowLayout {
                Layout.alignment: Qt.AlignHCenter; spacing: 9
                LiquidActionButton { iconOnly: true; iconName: "shuffle"; implicitWidth: 30; implicitHeight: 30; flat: true; checked: bar.music.shuffle; onClicked: bar.music.shuffle = !bar.music.shuffle; Accessible.name: qsTr("Shuffle") }
                LiquidActionButton { iconOnly: true; iconName: "previous"; implicitWidth: 30; implicitHeight: 30; flat: true; enabled: bar.music.canGoPrevious; onClicked: bar.music.previous(); Accessible.name: qsTr("Previous") }
                LiquidActionButton { objectName: "reviewPlayerPlay"; iconOnly: true; iconName: bar.music.playbackState === "Playing" ? "pause" : "play"; iconSize: 18; implicitWidth: 36; implicitHeight: 32; enabled: bar.music.currentTrackId > 0; onClicked: bar.music.togglePlayPause(); Accessible.name: qsTr("Play or pause") }
                LiquidActionButton { iconOnly: true; iconName: "next"; implicitWidth: 30; implicitHeight: 30; flat: true; enabled: bar.music.canGoNext; onClicked: bar.music.next(); Accessible.name: qsTr("Next") }
                LiquidActionButton { iconOnly: true; iconName: "repeat"; implicitWidth: 30; implicitHeight: 30; flat: true; checked: bar.music.repeatMode !== "none"; onClicked: bar.music.repeatMode = bar.music.repeatMode === "none" ? "playlist" : bar.music.repeatMode === "playlist" ? "track" : "none"; Accessible.name: qsTr("Repeat mode"); ToolTip.text: bar.music.repeatMode; ToolTip.visible: hovered }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 7
                Label { text: bar.stamp(bar.music.positionMs); color: AppTheme.mutedText; font.pixelSize: 10; Layout.preferredWidth: 30 }
                LiquidSlider {
                    Layout.fillWidth: true; implicitHeight: 26; trackHeight: 4; thumbWidth: 22; thumbHeight: 16; materialForm: false
                    enabled: bar.music.seekable
                    property real preview: -1
                    value: preview >= 0 ? preview : bar.music.durationMs > 0 ? bar.music.positionMs / bar.music.durationMs : 0
                    accentColor: AppTheme.accent
                    onPreviewChanged: value => preview = value
                    onCommitRequested: value => { bar.music.seekFraction(value); preview = -1 }
                    onCanceled: preview = -1
                    Accessible.name: qsTr("Playback position")
                }
                Label { text: bar.music.durationMs > 0 ? bar.stamp(bar.music.durationMs) : "—:—"; color: AppTheme.mutedText; font.pixelSize: 10; Layout.preferredWidth: 30 }
            }
        }
        Item { Layout.fillWidth: true }
        VectorIcon { name: "volume"; size: 16; color: AppTheme.mutedText }
        LiquidSlider {
            Layout.preferredWidth: 74; implicitHeight: 26; trackHeight: 4; thumbWidth: 22; thumbHeight: 16; materialForm: false
            value: bar.music.volume; accentColor: AppTheme.accent
            onPreviewChanged: value => bar.music.volume = value
            onCommitRequested: value => bar.music.volume = value
            Accessible.name: qsTr("Volume")
        }
        LiquidActionButton { iconOnly: true; iconName: "queue"; implicitWidth: 30; implicitHeight: 30; flat: true; onClicked: bar.queueRequested(); Accessible.name: qsTr("Queue") }
        LiquidActionButton { iconOnly: true; iconName: "music"; implicitWidth: 30; implicitHeight: 30; flat: true; onClicked: bar.nowPlayingRequested(); Accessible.name: qsTr("Now playing") }
    }
}
