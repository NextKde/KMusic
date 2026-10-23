import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Kos.Ui
import "UiLanguage.mjs" as Language
Item {
    id: page
    required property var music
    property int lyricFontSize: 25
    property bool centerLyrics: false
    property bool lyricBlur: true
    property bool smoothLyrics: true
    signal closeRequested()
    onVisibleChanged: if (visible) {
        presentationMode = 1
        music.lyricsEnabled = true
        forceActiveFocus(Qt.OtherFocusReason)
    }
    Keys.onEscapePressed: event => { page.closeRequested(); event.accepted = true }
    property int presentationMode: 1
    readonly property color foreground: "#f5f7fa"
    readonly property color secondary: "#b9c5d2"
    function clock(milliseconds) {
        const seconds = Math.max(0, Math.floor(milliseconds / 1000))
        return Math.floor(seconds / 60) + ":" + (seconds % 60 < 10 ? "0" : "") + seconds % 60
    }
    clip: true
    function ownsControlFocus(item) {
        for (let node = item; node; node = node.parent)
            if (node === modeButtons) return true
        return false
    }
    function reviewMaterialAction(action, index) {
        if (action === "segmentRelease") page.presentationMode = index === 0 ? 0 : 1
    }
    function materialReviewState() {
        return JSON.stringify({ lyricsEnabled: music.lyricsEnabled, mode: presentationMode })
    }
    Connections {
        target: page.music
        function onReadyChanged() { if (page.visible && page.music.ready) page.music.lyricsEnabled = true }
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
        x: 16; y: 16; implicitWidth: 34; implicitHeight: 34
        materialForm: false; backdrop: ambientBackdrop
        iconOnly: true; iconName: "close"; iconColor: page.foreground
        onClicked: page.closeRequested(); Accessible.name: Language.text("Close now playing", "关闭正在播放")
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
                Accessible.name: Language.text("Volume", "音量")
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
                Label { text: page.music.currentTitle || Language.text("Nothing playing", "暂无播放"); color: page.foreground; font.pixelSize: 22; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                MusicActionButton {
                    objectName: "reviewCurrentFavorite"; flat: true; iconOnly: true; iconName: "heart"; iconFilled: page.music.currentFavorite
                    iconColor: page.music.currentFavorite ? MusicColors.sidebarAccent : page.foreground
                    implicitWidth: 30; implicitHeight: 30; enabled: page.music.currentTrackId > 0
                    Accessible.name: page.music.currentFavorite ? Language.text("Remove local favorite", "取消本机收藏") : Language.text("Add local favorite", "加入本机收藏")
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
                    Accessible.name: Language.text("Playback position", "播放进度")
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
                MusicActionButton { surfaceColor: "#33485f"; textColor: page.foreground; flat: true; iconOnly: true; iconName: "shuffle"; iconColor: checked ? "#ffffff" : page.secondary; checked: page.music.shuffle; onClicked: page.music.shuffle = !page.music.shuffle; Accessible.name: Language.text("Shuffle", "随机播放") }
                Item { Layout.fillWidth: true }
                MusicActionButton { surfaceColor: "#33485f"; textColor: page.foreground; flat: true; iconOnly: true; iconName: "mediaPrevious"; iconFilled: true; iconSize: 28; iconColor: page.foreground; enabled: page.music.canGoPrevious; onClicked: page.music.previous(); Accessible.name: Language.text("Previous", "上一首") }
                MusicActionButton { surfaceColor: "#33485f"; textColor: page.foreground; objectName: "reviewImmersivePlay"; flat: true; iconOnly: true; implicitWidth: 54; implicitHeight: 48; iconName: page.music.playbackState === "Playing" ? "mediaPause" : "mediaPlay"; iconFilled: true; iconSize: 32; iconColor: page.foreground; enabled: page.music.currentTrackId > 0; onClicked: page.music.togglePlayPause(); Accessible.name: Language.text("Play or pause", "播放或暂停") }
                MusicActionButton { surfaceColor: "#33485f"; textColor: page.foreground; flat: true; iconOnly: true; iconName: "mediaNext"; iconFilled: true; iconSize: 28; iconColor: page.foreground; enabled: page.music.canGoNext; onClicked: page.music.next(); Accessible.name: Language.text("Next", "下一首") }
                Item { Layout.fillWidth: true }
                MusicActionButton { surfaceColor: "#33485f"; textColor: page.foreground; flat: true; iconOnly: true; iconName: "repeat"; iconColor: checked ? "#ffffff" : page.secondary; checked: page.music.repeatMode !== "none"; onClicked: page.music.repeatMode = page.music.repeatMode === "none" ? "playlist" : page.music.repeatMode === "playlist" ? "track" : "none"; Accessible.name: Language.text("Repeat mode", "循环模式"); ToolTip.text: page.music.repeatMode === "track" ? Language.text("Repeat one", "单曲循环") : page.music.repeatMode === "playlist" ? Language.text("Repeat all", "列表循环") : Language.text("Repeat off", "关闭循环"); ToolTip.visible: hovered }
            }
            Label { Layout.fillWidth: true; elide: Text.ElideRight; text: page.music.providerStatus; color: page.secondary; font.pixelSize: 11; ToolTip.text: text; ToolTip.visible: statusHover.hovered; HoverHandler { id: statusHover } }
        }
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumWidth: 240; Layout.bottomMargin: 46; spacing: 18
            Label { visible: page.presentationMode === 0; text: Language.text("Queue · %1 remaining", "队列 · 剩余 %1 首").arg(Math.max(0, page.music.queueModel.count - page.music.queueIndex - 1)); color: page.foreground; font.pixelSize: 14; font.weight: Font.DemiBold }
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
                        MusicActionButton { surfaceColor: "#33485f"; textColor: page.foreground; flat: true; iconOnly: true; iconName: "close"; iconSize: 13; iconColor: page.secondary; implicitWidth: 28; onClicked: page.music.removeQueueRow(queueRow.index); Accessible.name: Language.text("Remove from queue", "移出队列") }
                    }
                }
                Label { anchors.centerIn: parent; visible: page.music.queueModel.count <= page.music.queueIndex + 1; width: parent.width - 32; text: Language.text("No more songs queued. Add music from an album or search.", "队列中没有更多歌曲，可从专辑或搜索中添加。"); wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; color: page.secondary }
            }
            Flickable {
                id: lyricsView
                Layout.fillWidth: true; Layout.fillHeight: true; visible: page.presentationMode === 1
                clip: true
                contentWidth: width
                contentHeight: lyricColumn.height
                boundsBehavior: Flickable.StopAtBounds
                readonly property int currentIndex: page.music.currentLyricIndex
                readonly property int count: lyricRepeater.count
                property bool browsing: false
                function followCurrent() {
                    if (!visible || !page.visible || browsing) return
                    const line = lyricRepeater.itemAt(currentIndex)
                    if (!line) return
                    const target = Math.max(0, Math.min(contentHeight - height,
                        line.y + line.height / 2 - height * .44))
                    if (AppTheme.reduceMotion || !page.smoothLyrics) { followAnimation.stop(); contentY = target }
                    else { followAnimation.to = target; followAnimation.running = true }
                }
                onCurrentIndexChanged: Qt.callLater(followCurrent)
                onHeightChanged: Qt.callLater(followCurrent)
                onVisibleChanged: if (visible) Qt.callLater(followCurrent)
                onMovementStarted: {
                    browsing = true
                    followAnimation.stop()
                    resumeFollowing.stop()
                }
                onMovementEnded: resumeFollowing.restart()
                Connections {
                    target: page
                    function onVisibleChanged() {
                        if (page.visible) {
                            lyricsView.browsing = false
                            Qt.callLater(lyricsView.followCurrent)
                        }
                    }
                }
                Timer {
                    id: resumeFollowing; interval: 3000
                    onTriggered: { lyricsView.browsing = false; lyricsView.followCurrent() }
                }
                // One scroll owner; retargeting preserves velocity instead of restarting each line.
                SmoothedAnimation {
                    id: followAnimation; target: lyricsView; property: "contentY"
                    duration: 900; velocity: -1
                }
                Column {
                    id: lyricColumn
                    width: lyricsView.width; spacing: 8
                    onHeightChanged: Qt.callLater(lyricsView.followCurrent)
                    Item { width: 1; height: lyricsView.height * .44 }
                    Repeater {
                        id: lyricRepeater
                        model: page.music.lyrics
                        onItemAdded: Qt.callLater(lyricsView.followCurrent)
                        delegate: Item {
                    id: lyricLine
                    required property var modelData; required property int index
                    width: lyricsView.width
                    height: lyricText.implicitHeight + 24
                    readonly property int distance: Math.abs(index - lyricsView.currentIndex)
                    readonly property bool active: index === lyricsView.currentIndex
                    // Each line trails the common scroll slightly, without changing its layout slot.
                    property real followedY: lyricsView.contentY
                    Behavior on followedY {
                        enabled: page.smoothLyrics && !AppTheme.reduceMotion && !lyricsView.browsing && page.visible
                        SmoothedAnimation { duration: 90 + Math.min(lyricLine.distance, 5) * 30; velocity: -1 }
                    }
                    readonly property real lag: lyricsView.browsing ? 0 : lyricsView.contentY - followedY
                    readonly property real screenCenter: y + height / 2 - lyricsView.contentY + lag
                    readonly property real edgeFade: Math.max(0, Math.min(1, screenCenter / 48, (lyricsView.height - screenCenter) / 48))
                    property real emphasis: active ? 1 : .82
                    property real lineOpacity: active ? 1 : Math.max(.27, .64 - distance * .07)
                    property real softness: !page.lyricBlur || active || lyricsView.browsing ? 0 : Math.min(.42, distance * .085)
                    Behavior on emphasis { NumberAnimation { duration: AppTheme.reduceMotion ? 0 : 380; easing.type: Easing.OutCubic } }
                    Behavior on lineOpacity { NumberAnimation { duration: AppTheme.reduceMotion ? 0 : 380 } }
                    Behavior on softness { NumberAnimation { duration: AppTheme.reduceMotion ? 0 : 450 } }
                    transform: Translate { y: lyricLine.lag }
                    opacity: edgeFade * lineOpacity
                    Label {
                        id: lyricText
                        x: 12; y: 12; width: parent.width - 24
                        text: lyricLine.modelData.text || ""
                        wrapMode: Text.WordWrap; font.pixelSize: page.lyricFontSize;
                        horizontalAlignment: page.centerLyrics ? Text.AlignHCenter : Text.AlignLeft; font.weight: Font.DemiBold
                        color: page.foreground
                        scale: lyricLine.emphasis; transformOrigin: page.centerLyrics ? Item.Center : Item.Left
                        layer.enabled: lyricLine.softness > .001 && lyricLine.screenCenter > -lyricLine.height && lyricLine.screenCenter < lyricsView.height + lyricLine.height
                        layer.effect: MultiEffect {
                            blurEnabled: true; blurMax: 16; blur: lyricLine.softness
                        }
                    }
                }
                    }
                    Item { width: 1; height: lyricsView.height * .56 }
                }
                ColumnLayout {
                    anchors.centerIn: parent; width: parent.width - 32; visible: parent.count === 0; spacing: 12
                    Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; text: page.music.lyricsLoading ? Language.text("Loading lyrics…", "正在加载歌词…") : page.music.lyricsError || Language.text("Lyrics unavailable", "暂无歌词"); color: page.secondary }
                    MusicActionButton { surfaceColor: "#33485f"; textColor: page.foreground; Layout.alignment: Qt.AlignHCenter; text: Language.text("Retry lyrics", "重试加载歌词"); visible: page.music.lyricsEnabled && !page.music.lyricsLoading && page.music.currentTrackId > 0; onClicked: page.music.reloadLyrics() }
                }
            }
        }
    }
    LiquidCard {
        id: modeButtons
        anchors.right: parent.right; anchors.rightMargin: 32
        anchors.bottom: parent.bottom; anchors.bottomMargin: 24
        width: 88; height: 38; radius: 19; padding: 3
        backdrop: ambientBackdrop
        tintColor: "#8393a6"; tintStrength: .18; readability: 0
        RowLayout {
            anchors.fill: parent; spacing: 2
            Button {
                Layout.fillWidth: true; Layout.fillHeight: true
                padding: 0
                Accessible.name: Language.text("Lyrics", "歌词")
                checked: page.presentationMode === 1
                onClicked: { page.music.lyricsEnabled = true; page.presentationMode = 1 }
                ToolTip.text: Accessible.name; ToolTip.visible: hovered
                background: Rectangle { radius: height / 2; color: parent.checked ? "#30ffffff" : parent.hovered ? "#15ffffff" : "transparent" }
                contentItem: Item {
                    Image {
                        anchors.centerIn: parent; width: 17; height: 17
                        source: "data:image/svg+xml," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M5 4h14a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2h-8l-5 3v-3H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2Z M7 8h10M7 12h7" fill="none" stroke="#f5f7fa" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>')
                    }
                }
            }
            Button {
                Layout.fillWidth: true; Layout.fillHeight: true
                padding: 0
                Accessible.name: Language.text("Queue", "播放队列")
                checked: page.presentationMode === 0
                onClicked: page.presentationMode = 0
                ToolTip.text: Accessible.name; ToolTip.visible: hovered
                background: Rectangle { radius: height / 2; color: parent.checked ? "#30ffffff" : parent.hovered ? "#15ffffff" : "transparent" }
                contentItem: Item { VectorIcon { anchors.centerIn: parent; width: 17; height: 17; name: "queueList"; size: 17; color: page.foreground } }
            }
        }
    }

}
