import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
Rectangle {
    id: bar
    required property var music
    signal queueRequested()
    signal nowPlayingRequested()
    height: 100
    color: AppTheme.windowRaised
    Rectangle { width: parent.width; height: 1; color: AppTheme.border }
    function stamp(ms) { const s = Math.floor(Math.max(0, ms) / 1000); return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + s % 60 }
    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 24; anchors.rightMargin: 24; spacing: 20
        Artwork { source: bar.music.currentArtworkUrl; title: bar.music.currentTitle; Layout.preferredWidth: 56; Layout.preferredHeight: 56 }
        ColumnLayout {
            Layout.preferredWidth: Math.max(120, bar.width * .14); spacing: 5
            Label { text: bar.music.currentTitle || qsTr("Choose something to play"); Layout.fillWidth: true; elide: Text.ElideRight; color: AppTheme.text; font.weight: Font.DemiBold }
            Label { text: bar.music.currentArtist || qsTr("Your music, your moment"); Layout.fillWidth: true; elide: Text.ElideRight; color: AppTheme.mutedText; font.pixelSize: 12 }
        }
        ColumnLayout {
            Layout.fillWidth: true; Layout.maximumWidth: 500; spacing: 0
            RowLayout {
                Layout.alignment: Qt.AlignHCenter; spacing: 12
                LiquidActionButton { iconOnly: true; text: "⇄"; implicitWidth: 32; flat: true; checkable: true; checked: bar.music.shuffle; onClicked: bar.music.shuffle = !bar.music.shuffle; Accessible.name: qsTr("Shuffle") }
                LiquidActionButton { iconOnly: true; text: "◀◀"; implicitWidth: 36; flat: true; enabled: bar.music.canGoPrevious; onClicked: bar.music.previous(); Accessible.name: qsTr("Previous") }
                LiquidActionButton { iconOnly: true; text: bar.music.playbackState === "Playing" ? "Ⅱ" : "▶"; implicitWidth: 44; enabled: bar.music.currentTrackId > 0; onClicked: bar.music.togglePlayPause(); Accessible.name: qsTr("Play or pause") }
                LiquidActionButton { iconOnly: true; text: "▶▶"; implicitWidth: 36; flat: true; enabled: bar.music.canGoNext; onClicked: bar.music.next(); Accessible.name: qsTr("Next") }
                LiquidActionButton { iconOnly: true; text: bar.music.repeatMode === "track" ? "↻¹" : "↻"; implicitWidth: 32; flat: true; checked: bar.music.repeatMode !== "none"; onClicked: bar.music.repeatMode = bar.music.repeatMode === "none" ? "playlist" : bar.music.repeatMode === "playlist" ? "track" : "none"; Accessible.name: qsTr("Repeat mode") }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 4
                Label { text: bar.stamp(bar.music.positionMs); color: AppTheme.mutedText; font.pixelSize: 10; Layout.preferredWidth: 30 }
                LiquidSlider {
                    id: seek
                    Layout.fillWidth: true; implicitHeight: 30; materialForm: false
                    enabled: bar.music.seekable
                    property real preview: -1
                    value: preview >= 0 ? preview : bar.music.durationMs > 0 ? bar.music.positionMs / bar.music.durationMs : 0
                    accentColor: AppTheme.accent
                    onPreviewChanged: value => preview = value
                    onCommitRequested: value => { bar.music.seekFraction(value); preview = -1 }
                    onCanceled: preview = -1
                }
                Label { text: bar.stamp(bar.music.durationMs); color: AppTheme.mutedText; font.pixelSize: 10; Layout.preferredWidth: 30 }
            }
        }
        Item { Layout.fillWidth: true }
        Label { text: "♪"; color: AppTheme.mutedText }
        LiquidSlider {
            Layout.preferredWidth: 90; implicitHeight: 30; materialForm: false
            value: bar.music.volume; accentColor: AppTheme.accent
            onPreviewChanged: value => bar.music.volume = value
            onCommitRequested: value => bar.music.volume = value
            Accessible.name: qsTr("Volume")
        }
        LiquidActionButton { iconOnly: true; text: "≡"; implicitWidth: 34; flat: true; onClicked: bar.queueRequested(); Accessible.name: qsTr("Queue") }
        LiquidActionButton { iconOnly: true; text: "♫"; implicitWidth: 34; flat: true; onClicked: bar.nowPlayingRequested(); Accessible.name: qsTr("Now playing") }
    }
}
