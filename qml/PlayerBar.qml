import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
LiquidCard {
    id: bar
    required property var music
    signal queueRequested()
    signal nowPlayingRequested()
    height: 84; radius: height / 2; padding: 14
    shadowEnabled: true; shadowOpacity: AppTheme.dark ? .22 : .14
    tintColor: AppTheme.dark ? "#282c32" : "#f8f9fa"
    tintStrength: AppTheme.dark ? .20 : .22
    readability: .12; blurStrength: .25
    refractionStrength: 5; magnification: 1.035; reflectionStrength: .55
    function reviewState() {
        return { sampling: bar.sampling, seekValue: seekSlider.value, volume: volumeSlider.value,
            playHovered: playAction.hovered, playDown: playAction.down, playVisualFocus: playAction.visualFocus,
            playContentScale: playAction.scale, playLensExpansion: playAction.opticalExpansion,
            playRefraction: playAction.opticalRefraction, playMagnification: playAction.opticalMagnification }
    }
    function stamp(ms) { const s = Math.floor(Math.max(0, ms) / 1000); return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + s % 60 }
    RowLayout {
        anchors.fill: parent; spacing: 10
        Artwork { source: bar.music.currentArtworkUrl; title: bar.music.currentTitle; Layout.preferredWidth: 44; Layout.preferredHeight: 44; radius: 6 }
        ColumnLayout {
            Layout.preferredWidth: bar.width >= 800 ? 140 : 108; Layout.maximumWidth: 140; spacing: 4
            Label { text: bar.music.currentTitle || qsTr("Nothing playing"); Layout.fillWidth: true; elide: Text.ElideRight; color: AppTheme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
            Label { text: bar.music.currentArtist || qsTr("Choose a song to begin"); Layout.fillWidth: true; elide: Text.ElideRight; color: AppTheme.mutedText; font.pixelSize: 11 }
        }
        ColumnLayout {
            Layout.fillWidth: true; Layout.minimumWidth: 220; spacing: 0
            RowLayout {
                Layout.alignment: Qt.AlignHCenter; spacing: 6
                MusicActionButton { backdrop: null; iconOnly: true; iconName: "shuffle"; implicitWidth: 26; implicitHeight: 28; flat: true; checked: bar.music.shuffle; onClicked: bar.music.shuffle = !bar.music.shuffle; Accessible.name: qsTr("Shuffle") }
                MusicActionButton { backdrop: null; iconOnly: true; iconName: "previous"; implicitWidth: 26; implicitHeight: 28; flat: true; enabled: bar.music.canGoPrevious; onClicked: bar.music.previous(); Accessible.name: qsTr("Previous") }
                MusicActionButton { id: playAction; backdrop: null; objectName: "reviewPlayerPlay"; iconOnly: true; iconName: bar.music.playbackState === "Playing" ? "pause" : "play"; iconSize: 18; implicitWidth: 34; implicitHeight: 32; enabled: bar.music.currentTrackId > 0; onClicked: bar.music.togglePlayPause(); Accessible.name: qsTr("Play or pause") }
                MusicActionButton { backdrop: null; iconOnly: true; iconName: "next"; implicitWidth: 26; implicitHeight: 28; flat: true; enabled: bar.music.canGoNext; onClicked: bar.music.next(); Accessible.name: qsTr("Next") }
                MusicActionButton { backdrop: null; iconOnly: true; iconName: "repeat"; implicitWidth: 26; implicitHeight: 28; flat: true; checked: bar.music.repeatMode !== "none"; onClicked: bar.music.repeatMode = bar.music.repeatMode === "none" ? "playlist" : bar.music.repeatMode === "playlist" ? "track" : "none"; Accessible.name: qsTr("Repeat mode"); ToolTip.text: bar.music.repeatMode; ToolTip.visible: hovered }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 7
                Label { text: bar.stamp(bar.music.positionMs); color: AppTheme.mutedText; font.pixelSize: 10; Layout.preferredWidth: 30 }
                LiquidSlider {
                    id: seekSlider; objectName: "reviewPlayerSeek"
                    Layout.fillWidth: true; implicitHeight: 26; trackHeight: 4; thumbWidth: 22; thumbHeight: 16; materialForm: false
                    enabled: bar.music.seekable
                    property real preview: -1
                    value: preview >= 0 ? preview : bar.music.durationMs > 0 ? bar.music.positionMs / bar.music.durationMs : 0
                    accentColor: MusicColors.sliderFill
                    onPreviewChanged: value => preview = value
                    onCommitRequested: value => { bar.music.seekFraction(value); preview = -1 }
                    onCanceled: preview = -1
                    Accessible.name: qsTr("Playback position")
                }
                Label { text: bar.music.durationMs > 0 ? bar.stamp(bar.music.durationMs) : "—:—"; color: AppTheme.mutedText; font.pixelSize: 10; Layout.preferredWidth: 30 }
            }
        }
        VectorIcon { name: "volume"; size: 16; color: AppTheme.mutedText }
        LiquidSlider {
            id: volumeSlider; objectName: "reviewPlayerVolume"
            Layout.preferredWidth: 56; implicitHeight: 26; trackHeight: 4; thumbWidth: 22; thumbHeight: 16; materialForm: false
            value: bar.music.volume; accentColor: MusicColors.sliderFill
            onPreviewChanged: value => bar.music.volume = value
            onCommitRequested: value => bar.music.volume = value
            Accessible.name: qsTr("Volume")
        }
        MusicActionButton { backdrop: null; iconOnly: true; iconName: "queue"; implicitWidth: 26; implicitHeight: 28; flat: true; onClicked: bar.queueRequested(); Accessible.name: qsTr("Queue") }
        MusicActionButton { backdrop: null; iconOnly: true; iconName: "music"; implicitWidth: 26; implicitHeight: 28; flat: true; onClicked: bar.nowPlayingRequested(); Accessible.name: qsTr("Now playing") }
    }
}
