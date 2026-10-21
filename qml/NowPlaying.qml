import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Kos.Ui
Item {
    id: page
    required property var music
    signal closeRequested()
    onVisibleChanged: if (visible) forceActiveFocus(Qt.OtherFocusReason)
    Keys.onEscapePressed: event => { page.closeRequested(); event.accepted = true }
    property int presentationMode: 0
    readonly property color foreground: "#f5f7fa"
    readonly property color secondary: "#b9c5d2"
    function clock(milliseconds) {
        const seconds = Math.max(0, Math.floor(milliseconds / 1000))
        return Math.floor(seconds / 60) + ":" + (seconds % 60 < 10 ? "0" : "") + seconds % 60
    }
    clip: true
    function ownsControlFocus(item) {
        for (let node = item; node; node = node.parent)
            if (node === lyricsSwitch || node === modeSelector) return true
        return false
    }
    // Fixed, opt-in review paths drive the same states as the real controls.
    // They do not claim pointer/keyboard event delivery or interaction acceptance.
    function reviewMaterialAction(action, index) {
        if (action === "switchPress") lyricsSwitch._beginPress()
        else if (action === "switchRelease") { lyricsSwitch._endPress(); lyricsSwitch.toggle() }
        else if (action === "switchCancel") lyricsSwitch._endPress()
        else if (action === "switchHover") lyricsSwitch._setHovered(index !== 0)
        else if (action === "switchFocus") lyricsSwitch.forceActiveFocus()
        else if (action === "segmentPress") modeSelector._beginPress(index)
        else if (action === "segmentRelease") { modeSelector._endPress(); modeSelector.select(index) }
        else if (action === "segmentCancel") modeSelector._endPress()
        else if (action === "segmentFocus") { modeSelector._beginPress(presentationMode); modeSelector._endPress() }
    }
    function materialReviewState() {
        return JSON.stringify({ lyricsEnabled: music.lyricsEnabled, mode: presentationMode,
            switchPressed: lyricsSwitch._pressed, switchHovered: lyricsSwitch._hovered,
            switchExpansion: lyricsSwitch._expansion, switchThumbX: lyricsSwitch._thumbX,
            switchStretch: lyricsSwitch._stretch, switchFocus: lyricsSwitch.activeFocus,
            switchSampling: lyricsSwitch.sampling, segmentPressed: modeSelector._pressedIndex,
            segmentVisual: modeSelector._visualIndex, segmentPending: modeSelector._pendingIndex,
            lensX: modeSelector._lensPosition, segmentSampling: modeSelector.sampling })
    }
    Connections {
        target: page.music
        function onLyricsEnabledChanged() { if (!page.music.lyricsEnabled) page.presentationMode = 0 }
    }
    Item {
        id: ambientScene
        anchors.fill: parent
        Rectangle { anchors.fill: parent; color: "#192432" }
        Image { id: ambientCover; anchors.fill: parent; source: page.music.currentArtworkUrl; asynchronous: true; sourceSize: Qt.size(800, 800); fillMode: Image.PreserveAspectCrop; visible: false }
        MultiEffect { anchors.fill: parent; source: ambientCover; visible: ambientCover.status === Image.Ready; blurEnabled: true; blurMax: 64; blur: 1; saturation: -.2; opacity: .50; autoPaddingEnabled: false }
        Rectangle { anchors.fill: parent; color: "#45111b2a" }
    }
    LiquidBackdrop { id: ambientBackdrop; sourceItem: ambientScene; registerAsDefault: false }
    MusicActionButton { surfaceColor: "#33485f"; textColor: page.foreground;
        x: 28; y: 40; implicitWidth: 34; implicitHeight: 34
        materialForm: false; backdrop: ambientBackdrop
        iconOnly: true; iconName: "close"; iconColor: page.foreground
        onClicked: page.closeRequested(); Accessible.name: qsTr("Close now playing")
    }
    LiquidCard {
        anchors.right: parent.right; anchors.rightMargin: 32; y: 40
        width: 180; height: 36; radius: 18; padding: 8
        backdrop: ambientBackdrop; tintColor: "#8393a6"; tintStrength: .18; readability: 0; blurStrength: 0
        RowLayout {
            anchors.fill: parent; spacing: 9
            VectorIcon { name: "volume"; color: page.foreground; size: 16 }
            LiquidSlider {
                Layout.fillWidth: true; Layout.fillHeight: true
                value: page.music.volume; accentColor: page.foreground; trackColor: "#668c9bab"
                trackHeight: 3; thumbWidth: 20; thumbHeight: 12; appearanceMode: "dark"
                onPreviewChanged: value => page.music.volume = value
                onCommitRequested: value => page.music.volume = value
                Accessible.name: qsTr("Volume")
            }
        }
    }
    RowLayout {
        id: contentRow
        anchors.fill: parent; anchors.leftMargin: 52; anchors.rightMargin: 52; anchors.topMargin: 92; anchors.bottomMargin: 30
        spacing: 64
        ColumnLayout {
            id: playbackColumn
            Layout.preferredWidth: Math.min(380, page.width * .38); Layout.maximumWidth: 380
            Layout.minimumWidth: 270; Layout.fillHeight: true
            spacing: 12
            Artwork {
                readonly property real coverExtent: Math.min(playbackColumn.width, Math.max(180, contentRow.height - 230))
                Layout.preferredWidth: coverExtent; Layout.preferredHeight: coverExtent
                Layout.alignment: Qt.AlignHCenter
                source: page.music.currentArtworkUrl; title: page.music.currentTitle; radius: 9
            }
            Item { Layout.fillHeight: true; Layout.maximumHeight: 16 }
            RowLayout {
                Layout.fillWidth: true
                Label { text: page.music.currentTitle || qsTr("Nothing playing"); color: page.foreground; font.pixelSize: 22; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                MusicActionButton {
                    objectName: "reviewCurrentFavorite"; flat: true; iconOnly: true; iconName: "heart"; iconFilled: page.music.currentFavorite
                    iconColor: page.music.currentFavorite ? MusicColors.sidebarAccent : page.foreground
                    implicitWidth: 30; implicitHeight: 30; enabled: page.music.currentTrackId > 0
                    Accessible.name: page.music.currentFavorite ? qsTr("Remove local favorite") : qsTr("Add local favorite")
                    ToolTip.text: Accessible.name; ToolTip.visible: hovered
                    onClicked: page.music.toggleTrackFavorite("current", 0)
                }
            }
            Label { text: page.music.currentArtist + (page.music.currentAlbum ? " — " + page.music.currentAlbum : ""); color: page.secondary; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                LiquidSlider {
                    id: immersiveSeek; objectName: "reviewImmersiveSeek"
                    Layout.fillWidth: true; implicitHeight: 24
                    property real previewValue: -1
                    value: previewValue >= 0 ? previewValue : page.music.durationMs > 0 ? page.music.positionMs / page.music.durationMs : 0
                    enabled: page.music.seekable
                    accentColor: page.foreground; trackColor: "#668c9bab"; appearanceMode: "dark"
                    trackHeight: 3; thumbWidth: 12; thumbHeight: 12; showThumb: _hovered || _pressed
                    onPreviewChanged: value => previewValue = value
                    onCommitRequested: value => { page.music.seekFraction(value); previewValue = -1 }
                    onCanceled: previewValue = -1
                    Accessible.name: qsTr("Playback position")
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: page.clock(page.music.positionMs); color: page.secondary; font.pixelSize: 10 }
                    Item { Layout.fillWidth: true }
                    Label { text: page.music.durationMs > 0 ? "−" + page.clock(page.music.durationMs - page.music.positionMs) : "—"; color: page.secondary; font.pixelSize: 10 }
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 14
                MusicActionButton { surfaceColor: "#33485f"; textColor: page.foreground; flat: true; iconOnly: true; iconName: "shuffle"; iconColor: checked ? "#ffffff" : page.secondary; checked: page.music.shuffle; onClicked: page.music.shuffle = !page.music.shuffle; Accessible.name: qsTr("Shuffle") }
                Item { Layout.fillWidth: true }
                MusicActionButton { surfaceColor: "#33485f"; textColor: page.foreground; flat: true; iconOnly: true; iconName: "mediaPrevious"; iconFilled: true; iconSize: 28; iconColor: page.foreground; enabled: page.music.canGoPrevious; onClicked: page.music.previous(); Accessible.name: qsTr("Previous") }
                MusicActionButton { surfaceColor: "#33485f"; textColor: page.foreground; objectName: "reviewImmersivePlay"; flat: true; iconOnly: true; implicitWidth: 54; implicitHeight: 48; iconName: page.music.playbackState === "Playing" ? "mediaPause" : "mediaPlay"; iconFilled: true; iconSize: 32; iconColor: page.foreground; enabled: page.music.currentTrackId > 0; onClicked: page.music.togglePlayPause(); Accessible.name: qsTr("Play or pause") }
                MusicActionButton { surfaceColor: "#33485f"; textColor: page.foreground; flat: true; iconOnly: true; iconName: "mediaNext"; iconFilled: true; iconSize: 28; iconColor: page.foreground; enabled: page.music.canGoNext; onClicked: page.music.next(); Accessible.name: qsTr("Next") }
                Item { Layout.fillWidth: true }
                MusicActionButton { surfaceColor: "#33485f"; textColor: page.foreground; flat: true; iconOnly: true; iconName: "repeat"; iconColor: checked ? "#ffffff" : page.secondary; checked: page.music.repeatMode !== "none"; onClicked: page.music.repeatMode = page.music.repeatMode === "none" ? "playlist" : page.music.repeatMode === "playlist" ? "track" : "none"; Accessible.name: qsTr("Repeat mode"); ToolTip.text: page.music.repeatMode; ToolTip.visible: hovered }
            }
            Label { Layout.fillWidth: true; elide: Text.ElideRight; text: page.music.providerStatus; color: page.secondary; font.pixelSize: 11; ToolTip.text: text; ToolTip.visible: statusHover.hovered; HoverHandler { id: statusHover } }
        }
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumWidth: 240; spacing: 18
            RowLayout {
                Layout.fillWidth: true
                LiquidSegmentedControl {
                    id: modeSelector
                    Layout.fillWidth: true
                    materialForm: true
                    backgroundColor: "#25354a"; selectionColor: "#475c74"
                    textColor: page.foreground; mutedTextColor: page.secondary
                    labels: [qsTr("Up next"), qsTr("Lyrics")]
                    currentIndex: page.presentationMode
                    onSelectionRequested: index => { if (index === 1) page.music.lyricsEnabled = true; page.presentationMode = index }
                }
                LiquidGlassSwitch {
                    id: lyricsSwitch
                    visible: page.presentationMode === 1
                    materialForm: true; darkAppearance: true
                    checked: page.music.lyricsEnabled
                    accentColor: "#6885a3"
                    Accessible.name: qsTr("Enable lyrics")
                    onToggled: checked => page.music.lyricsEnabled = checked
                }
            }
            Label { visible: page.presentationMode === 0; text: qsTr("Queue · %1 remaining").arg(Math.max(0, page.music.queueModel.count - page.music.queueIndex - 1)); color: page.foreground; font.pixelSize: 14; font.weight: Font.DemiBold }
            ListView {
                id: upcoming
                visible: page.presentationMode === 0
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                model: page.music.queueModel
                ScrollBar.vertical: ScrollBar {}
                delegate: ItemDelegate {
                    id: queueRow
                    required property int index
                    objectName: index === page.music.queueIndex + 1 ? "reviewNextQueued" : ""
                    required property string title
                    required property string artist
                    required property string album
                    required property string artworkUrl
                    width: upcoming.width; height: index > page.music.queueIndex ? 60 : 0
                    visible: height > 0
                    hoverEnabled: true
                    onClicked: page.music.playQueueRow(index)
                    background: Rectangle { color: queueRow.hovered ? "#19ffffff" : "transparent"; radius: 5 }
                    contentItem: RowLayout {
                        spacing: 10
                        Artwork { source: queueRow.artworkUrl; title: queueRow.title; Layout.preferredWidth: 42; Layout.preferredHeight: 42; radius: 4 }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 4
                            Label { text: queueRow.title; Layout.fillWidth: true; elide: Text.ElideRight; color: page.foreground; font.pixelSize: 13 }
                            Label { text: queueRow.artist + (queueRow.album ? " — " + queueRow.album : ""); Layout.fillWidth: true; elide: Text.ElideRight; color: page.secondary; font.pixelSize: 11 }
                        }
                        MusicActionButton { surfaceColor: "#33485f"; textColor: page.foreground; flat: true; iconOnly: true; iconName: "close"; iconSize: 13; iconColor: page.secondary; implicitWidth: 28; onClicked: page.music.removeQueueRow(queueRow.index); Accessible.name: qsTr("Remove from queue") }
                    }
                }
                Label { anchors.centerIn: parent; visible: page.music.queueModel.count <= page.music.queueIndex + 1; width: parent.width - 32; text: qsTr("No more songs queued. Add music from an album or search."); wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; color: page.secondary }
            }
            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true; visible: page.presentationMode === 1
                clip: true; model: page.music.lyrics; currentIndex: page.music.currentLyricIndex
                highlightRangeMode: ListView.ApplyRange; preferredHighlightBegin: height * .4; preferredHighlightEnd: height * .6
                delegate: Label {
                    required property var modelData; required property int index
                    width: ListView.view.width; padding: 12
                    text: modelData.text || ""; wrapMode: Text.WordWrap; font.pixelSize: index === page.music.currentLyricIndex ? 25 : 20
                    color: index === page.music.currentLyricIndex ? page.foreground : page.secondary; font.weight: Font.DemiBold
                }
                ColumnLayout {
                    anchors.centerIn: parent; width: parent.width - 32; visible: parent.count === 0; spacing: 12
                    Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; text: !page.music.lyricsEnabled ? qsTr("Lyrics off") : page.music.lyricsLoading ? qsTr("Loading lyrics…") : page.music.lyricsError || qsTr("Lyrics unavailable"); color: page.secondary }
                    MusicActionButton { surfaceColor: "#33485f"; textColor: page.foreground; Layout.alignment: Qt.AlignHCenter; text: qsTr("Retry lyrics"); visible: page.music.lyricsEnabled && !page.music.lyricsLoading && page.music.currentTrackId > 0; onClicked: page.music.reloadLyrics() }
                }
            }
        }
    }
}
