import QtQuick
import QtQuick.Controls
import Kos.Ui
Item {
    id: tile
    property string title: ""
    property string subtitle: ""
    property string actionObjectName: ""
    property url artwork
    signal clicked()
    implicitHeight: width + 44
    Artwork { id: cover; width: parent.width; height: width; source: tile.artwork; title: tile.title; radius: 8 }
    AbstractButton {
        objectName: tile.actionObjectName
        anchors.fill: cover; hoverEnabled: true; Accessible.name: tile.title
        onClicked: tile.clicked()
        background: Rectangle { radius: 8; color: parent.down ? "#18000000" : parent.hovered ? "#0affffff" : "transparent"; border.width: parent.visualFocus ? 2 : 0; border.color: AppTheme.focusRing }
    }
    Column {
        anchors.top: cover.bottom; anchors.topMargin: 8; width: parent.width; spacing: 3
        Label { width: parent.width; text: tile.title; color: AppTheme.text; font.pixelSize: 13; elide: Text.ElideRight }
        Label { width: parent.width; text: tile.subtitle; color: AppTheme.mutedText; font.pixelSize: 11; elide: Text.ElideRight }
    }
}
