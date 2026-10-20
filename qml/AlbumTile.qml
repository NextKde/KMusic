import QtQuick
import QtQuick.Controls
import Kos.Ui
Item {
    id: tile
    property string title: ""
    property string subtitle: ""
    property color first: "#dd6a61"
    property color second: "#512b5c"
    property int motif: 0
    property url artwork
    property bool wide: false
    signal clicked()
    implicitHeight: (wide ? width * .52 : width) + 54
    Rectangle {
        id: cover
        width: parent.width; height: tile.wide ? width * .52 : width
        radius: 8; clip: true
        gradient: Gradient {
            GradientStop { position: 0; color: tile.first }
            GradientStop { position: 1; color: tile.second }
        }
        Repeater {
            model: 4
            delegate: Rectangle {
                required property int index
                width: cover.width * (.42 + index * .1); height: width; radius: width / 2
                x: cover.width * .22 + index * 10; y: cover.height * .12 + index * 18
                color: "transparent"; border.width: tile.motif % 2 === 0 ? 18 : 3
                border.color: Qt.rgba(1, 1, 1, .16 + index * .04); rotation: index * 15
            }
        }
        Image { anchors.fill: parent; source: tile.artwork; fillMode: Image.PreserveAspectCrop; visible: tile.artwork.toString().length > 0; asynchronous: true }
        Label {
            anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 18
            text: tile.title; width: parent.width - 36; wrapMode: Text.WordWrap
            font.pixelSize: tile.wide ? 28 : 20; font.weight: Font.Bold; color: "white"
            visible: !tile.artwork.toString().length
        }
        AbstractButton {
            id: action
            anchors.fill: parent; hoverEnabled: true; Accessible.name: tile.title
            onClicked: tile.clicked()
            background: Rectangle {
                color: parent.hovered ? "#14ffffff" : "transparent"; radius: 8
                border.width: parent.activeFocus ? 2 : 0; border.color: AppTheme.focusRing
            }
        }
    }
    Column {
        anchors.top: cover.bottom; anchors.topMargin: 10; width: parent.width; spacing: 3
        Label { width: parent.width; text: tile.title; color: AppTheme.text; font.pixelSize: 14; elide: Text.ElideRight }
        Label { width: parent.width; text: tile.subtitle; color: AppTheme.mutedText; font.pixelSize: 12; elide: Text.ElideRight }
    }
}
