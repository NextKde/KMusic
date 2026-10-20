import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
ColumnLayout {
    id: page
    required property var music
    property int presentationMode: 0
    spacing: 20
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
    RowLayout {
        Layout.fillWidth: true; Layout.leftMargin: 36; Layout.rightMargin: 36; Layout.topMargin: 22
        spacing: 16
        LiquidSegmentedControl {
            id: modeSelector
            Layout.preferredWidth: 220
            materialForm: false
            labels: [qsTr("Overview"), qsTr("Lyrics")]
            currentIndex: page.presentationMode
            onSelectionRequested: function(index) {
                if (index === 1) page.music.lyricsEnabled = true
                page.presentationMode = index
            }
        }
        Item { Layout.fillWidth: true }
        Label { text: qsTr("Lyrics"); color: AppTheme.text; font.pixelSize: 13 }
        LiquidGlassSwitch {
            id: lyricsSwitch
            materialForm: false
            accentColor: AppTheme.accent
            checked: page.music.lyricsEnabled
            Accessible.name: qsTr("Show lyrics")
            onToggled: checked => page.music.lyricsEnabled = checked
        }
    }
    RowLayout {
        id: contentRow
        Layout.fillWidth: true; Layout.fillHeight: true
        spacing: 44
        ColumnLayout {
            visible: page.presentationMode === 0
            readonly property real coverSize: Math.max(160, Math.min(320, page.width * .36, contentRow.height - 140))
            Layout.minimumWidth: 0; Layout.preferredWidth: coverSize; Layout.maximumWidth: coverSize
            Layout.alignment: Qt.AlignVCenter; Layout.leftMargin: 36; spacing: 18
            Artwork { Layout.fillWidth: true; Layout.preferredHeight: parent.coverSize; source: page.music.currentArtworkUrl; title: page.music.currentTitle; radius: 12 }
            Label { text: page.music.currentTitle || qsTr("Nothing playing"); color: AppTheme.text; font.pixelSize: 24; font.weight: Font.Bold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Label { text: page.music.currentArtist; color: AppTheme.mutedText; font.pixelSize: 18; Layout.fillWidth: true; elide: Text.ElideRight }
        }
        ListView {
            Layout.minimumWidth: 0; Layout.preferredWidth: page.width * .5; Layout.fillWidth: true; Layout.fillHeight: true; Layout.leftMargin: page.presentationMode === 1 ? 36 : 0; Layout.topMargin: 16; Layout.bottomMargin: 40; Layout.rightMargin: 36
            clip: true; model: page.music.lyrics; currentIndex: page.music.currentLyricIndex
            highlightRangeMode: ListView.ApplyRange; preferredHighlightBegin: height * .4; preferredHighlightEnd: height * .6
            delegate: Label {
                required property var modelData
                required property int index
                width: ListView.view.width; padding: 12
                text: modelData.text || ""; wrapMode: Text.WordWrap; font.pixelSize: index === page.music.currentLyricIndex ? 26 : 21
                color: index === page.music.currentLyricIndex ? AppTheme.text : AppTheme.mutedText
                font.weight: Font.DemiBold
            }
            Label {
                anchors.centerIn: parent; visible: parent.count === 0
                text: !page.music.lyricsEnabled ? qsTr("Lyrics off") : page.music.lyricsLoading ? qsTr("Loading lyrics…") : qsTr("Lyrics unavailable")
                color: AppTheme.mutedText
            }
        }
    }
}
