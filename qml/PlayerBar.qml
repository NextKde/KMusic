import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
LiquidCard {
    id: bar
    required property var music
    property real lastCommittedSeek: -1
    signal queueRequested()
    signal nowPlayingRequested()
    height: 52; radius: height / 2; padding: 8
    shadowEnabled: true; shadowOpacity: AppTheme.dark ? .22 : .14
    tintColor: AppTheme.dark ? "#282c32" : "#f8f9fa"
    tintStrength: AppTheme.dark ? .20 : .22
    readability: .12; blurStrength: 0
    refractionStrength: 5; magnification: 1.035; reflectionStrength: .55
    function reviewState() {
        return { sampling: bar.sampling, seekValue: seekSlider.value, volume: volumeSlider.value,
            playHovered: playAction.hovered, playDown: playAction.down, playVisualFocus: playAction.visualFocus,
            playContentScale: playAction.scale, playLensExpansion: playAction.opticalExpansion,
            playRefraction: playAction.opticalRefraction, playMagnification: playAction.opticalMagnification,
            lastCommittedSeek: lastCommittedSeek, seekable: bar.music.seekable, volumePopup: volumePopup.opened }
    }
    RowLayout {
        anchors.fill: parent; spacing: 12
        RowLayout {
            Layout.preferredWidth: 164; Layout.maximumWidth: 164
            Layout.alignment: Qt.AlignVCenter; spacing: 5
            MusicActionButton { backdrop: null; iconOnly: true; iconName: "shuffle"; implicitWidth: 24; implicitHeight: 26; flat: true; checked: bar.music.shuffle; onClicked: bar.music.shuffle = !bar.music.shuffle; Accessible.name: qsTr("Shuffle") }
            MusicActionButton { backdrop: null; iconOnly: true; iconName: "mediaPrevious"; iconFilled: true; iconSize: 20; iconColor: AppTheme.text; implicitWidth: 28; implicitHeight: 26; flat: true; enabled: bar.music.canGoPrevious; onClicked: bar.music.previous(); Accessible.name: qsTr("Previous") }
            MusicActionButton { id: playAction; backdrop: null; objectName: "reviewPlayerPlay"; iconOnly: true; iconName: bar.music.playbackState === "Playing" ? "mediaPause" : "mediaPlay"; iconFilled: true; iconSize: 20; iconColor: AppTheme.text; implicitWidth: 30; implicitHeight: 28; flat: true; enabled: bar.music.currentTrackId > 0; onClicked: bar.music.togglePlayPause(); Accessible.name: qsTr("Play or pause") }
            MusicActionButton { backdrop: null; iconOnly: true; iconName: "mediaNext"; iconFilled: true; iconSize: 20; iconColor: AppTheme.text; implicitWidth: 28; implicitHeight: 26; flat: true; enabled: bar.music.canGoNext; onClicked: bar.music.next(); Accessible.name: qsTr("Next") }
            MusicActionButton { backdrop: null; iconOnly: true; iconName: "repeat"; implicitWidth: 24; implicitHeight: 26; flat: true; checked: bar.music.repeatMode !== "none"; onClicked: bar.music.repeatMode = bar.music.repeatMode === "none" ? "playlist" : bar.music.repeatMode === "playlist" ? "track" : "none"; Accessible.name: qsTr("Repeat mode"); ToolTip.text: bar.music.repeatMode; ToolTip.visible: hovered }
        }
        Item {
            Layout.fillWidth: true; Layout.minimumWidth: 180; Layout.fillHeight: true
            RowLayout {
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                height: 30; spacing: 8
                TapHandler { onTapped: bar.nowPlayingRequested() }
                Artwork { source: bar.music.currentArtworkUrl; title: bar.music.currentTitle; Layout.preferredWidth: 30; Layout.preferredHeight: 30; radius: 4 }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Label { text: bar.music.currentTitle || qsTr("Nothing playing"); Layout.fillWidth: true; elide: Text.ElideRight; color: AppTheme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
                    Label { text: bar.music.currentArtist ? bar.music.currentArtist + (bar.music.currentAlbum ? " — " + bar.music.currentAlbum : "") : qsTr("Choose a song to begin"); Layout.fillWidth: true; elide: Text.ElideRight; color: AppTheme.mutedText; font.pixelSize: 11 }
                }
            }
            LiquidSlider {
                id: seekSlider; objectName: "reviewPlayerSeek"
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.bottomMargin: -3
                height: 10; trackHeight: 1.5; thumbWidth: 8; thumbHeight: 8; showThumb: _hovered || _pressed; materialForm: false
                enabled: bar.music.seekable
                property real previewValue: -1
                value: previewValue >= 0 ? previewValue : bar.music.durationMs > 0 ? bar.music.positionMs / bar.music.durationMs : 0
                accentColor: MusicColors.sliderFill
                onPreviewChanged: value => previewValue = value
                onCommitRequested: value => { bar.lastCommittedSeek = value; bar.music.seekFraction(value); previewValue = -1 }
                onCanceled: previewValue = -1
                Accessible.name: qsTr("Playback position")
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignVCenter; spacing: 8
            Rectangle {
                visible: bar.music.playbackSession.availability === "preview"
                Layout.preferredWidth: 40; Layout.preferredHeight: 20; radius: 10
                color: AppTheme.withAlpha(AppTheme.text, .45)
                Label { anchors.centerIn: parent; text: qsTr("Preview"); color: AppTheme.dark ? "#202326" : "#ffffff"; font.pixelSize: 9; font.weight: Font.DemiBold }
                ToolTip.text: bar.music.providerStatus; ToolTip.visible: badgeHover.hovered
                HoverHandler { id: badgeHover }
            }
            MusicActionButton { backdrop: null; iconOnly: true; iconName: "queueList"; iconColor: AppTheme.text; iconSize: 18; implicitWidth: 26; implicitHeight: 26; flat: true; onClicked: bar.queueRequested(); Accessible.name: qsTr("Queue") }
            MusicActionButton { id: volumeAction; objectName: "reviewPlayerVolumeButton"; backdrop: null; iconOnly: true; iconName: "volume"; iconColor: AppTheme.text; iconSize: 18; implicitWidth: 26; implicitHeight: 26; flat: true; onClicked: volumePopup.opened ? volumePopup.close() : volumePopup.open(); Accessible.name: qsTr("Volume") }
        }
    }
    Popup {
        id: volumePopup
        focus: true
        x: bar.width - width - 12; y: -height - 10
        width: 170; height: 48; padding: 12
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        background: LiquidCard { radius: 24; shadowEnabled: true; backdrop: bar.backdrop; tintColor: bar.tintColor; tintStrength: .45; readability: .35 }
        contentItem: LiquidSlider {
            id: volumeSlider; objectName: "reviewPlayerVolume"
            trackHeight: 4; thumbWidth: 22; thumbHeight: 16; materialForm: false
            value: bar.music.volume; accentColor: MusicColors.sliderFill
            onPreviewChanged: value => bar.music.volume = value
            onCommitRequested: value => bar.music.volume = value
            Accessible.name: qsTr("Volume")
        }
    }
}
