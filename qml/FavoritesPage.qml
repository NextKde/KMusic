import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
import "UiLanguage.mjs" as Language

// 「收藏音乐」内容页。目录的创建 / 重命名 / 删除与导航都在侧边栏完成，
// 这里只负责显示选中目录里的曲目快照。
Item {
    id: page
    required property var music
    property string source: "netease"
    property string folderId: ""
    property real bottomContentInset: 0
    property color backgroundColor: "transparent"

    readonly property string sourceLabel: source === "bilibili"
        ? "Bilibili"
        : Language.text("NetEase Cloud Music", "网易云音乐")

    signal newFolderRequested()

    function clock(ms) {
        if (ms <= 0)
            return ""
        const total = Math.round(ms / 1000)
        const minutes = Math.floor(total / 60)
        const seconds = total % 60
        return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds)
    }

    function refresh() {
        trackModel.clear()
        if (page.folderId.length === 0)
            return
        const list = favorites.tracks(page.folderId)
        for (let i = 0; i < list.length; ++i)
            trackModel.append(list[i])
    }

    function playRow(row) {
        if (row < 0 || row >= trackModel.count)
            return
        const entry = trackModel.get(row)
        // 快照里保存了地址时直接按地址播放；在线曲目的快照不带地址，
        // 它的 id 就是 KMusic 曲库行号，按 id 回到原有解析流程。
        if (entry.url.length > 0) {
            page.music.openUri(entry.url)
            return
        }
        const libraryId = Number(entry.id)
        if (libraryId > 0)
            page.music.playTrack(libraryId)
    }

    onFolderIdChanged: refresh()
    onSourceChanged: refresh()
    Component.onCompleted: refresh()

    Connections {
        target: favorites
        function onChanged() { page.refresh() }
    }

    ListModel { id: trackModel }

    // 内容区合成走 ShaderEffectSource，页面若完全透明，上一帧残留的像素会透上来。
    // 这里铺一层与内容区一致的底色，颜色由 Main.qml 传入，避免两处各写一份。
    Rectangle { anchors.fill: parent; color: page.backgroundColor }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 32
        anchors.rightMargin: 32
        anchors.topMargin: 22
        spacing: 10

        // 目录名由顶部浮动标题栏显示，这里只放来源与曲目数，避免重复标题。
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Label {
                Layout.fillWidth: true
                elide: Text.ElideRight
                // 目录为空时只显示来源名；具体该做什么由下面的空状态提示说明。
                text: page.folderId.length
                    ? page.sourceLabel + " · " + Language.text("%1 tracks", "%1 首").arg(trackModel.count)
                    : page.sourceLabel
                color: AppTheme.mutedText
                font.pixelSize: 12
            }
            MusicActionButton {
                objectName: "reviewFavoriteNewFolder"
                text: Language.text("New folder", "新建收藏目录")
                onClicked: page.newFolderRequested()
            }
        }

        ListView {
            id: trackList
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: trackModel.count > 0
            clip: true
            spacing: 2
            model: trackModel
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            delegate: Rectangle {
                id: row
                required property int index
                required property string id
                required property string title
                required property string artist
                required property string album
                required property real durationMs
                width: trackList.width
                height: 46
                radius: 8
                color: rowHover.hovered ? MusicColors.hoverFill : "transparent"
                HoverHandler { id: rowHover }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            Layout.fillWidth: true
                            textFormat: Text.PlainText
                            text: row.title.length ? row.title : row.id
                            color: AppTheme.text
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            textFormat: Text.PlainText
                            text: row.artist.length
                                ? row.artist + (row.album.length ? " — " + row.album : "")
                                : Language.text("Unknown artist", "未知艺术家")
                            color: AppTheme.mutedText
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                    Label {
                        text: page.clock(row.durationMs)
                        color: MusicColors.sidebarLabelTertiary
                        font.pixelSize: 11
                    }
                    MusicActionButton {
                        iconOnly: true; iconName: "close"; implicitWidth: 22; implicitHeight: 22; flat: true
                        Accessible.name: Language.text("Remove from folder", "从收藏目录移除")
                        ToolTip.text: Accessible.name; ToolTip.visible: hovered
                        onClicked: favorites.removeFromFolder(page.folderId, row.id)
                    }
                }
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onDoubleTapped: page.playRow(row.index)
                }
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: {
                        trackMenu.row = row.index
                        trackMenu.popup()
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            visible: trackModel.count === 0
            wrapMode: Text.WordWrap
            color: MusicColors.sidebarLabelTertiary
            font.pixelSize: 12
            text: page.folderId.length === 0
                ? Language.text("Choose a favorite folder on the left, or right-click a source to create one.",
                                "在左侧选择一个收藏目录，或右键来源新建目录。")
                : Language.text("This folder is empty. Use the heart in the player bar to collect the song that is playing.",
                                "这个目录还没有曲目。播放时点播放器上的爱心即可收藏。")
        }

        Item { Layout.preferredHeight: page.bottomContentInset }
    }

    Menu {
        id: trackMenu
        property int row: -1
        palette.window: MusicColors.controlSurface
        palette.windowText: AppTheme.text
        palette.text: AppTheme.text
        palette.buttonText: AppTheme.text
        palette.base: MusicColors.controlSurface
        palette.light: MusicColors.selectedSurface
        palette.midlight: MusicColors.hoverFill
        palette.dark: AppTheme.border
        palette.highlight: MusicColors.selectedSurface
        palette.highlightedText: AppTheme.text
        background: Rectangle {
            implicitWidth: 190
            implicitHeight: trackMenu.contentHeight + 8
            color: MusicColors.controlSurface
            radius: 8
            border.width: 1
            border.color: AppTheme.border
        }
        MenuItem {
            text: Language.text("Play", "播放")
            onTriggered: page.playRow(trackMenu.row)
        }
        MenuItem {
            text: Language.text("Remove from folder", "从收藏目录移除")
            onTriggered: {
                if (trackMenu.row < 0 || trackMenu.row >= trackModel.count)
                    return
                favorites.removeFromFolder(page.folderId, trackModel.get(trackMenu.row).id)
            }
        }
    }
}
