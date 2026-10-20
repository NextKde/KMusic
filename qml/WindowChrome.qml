import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Kos.Ui
Rectangle {
    id: chrome
    required property var targetWindow
    height: 30
    color: AppTheme.window
    MouseArea {
        anchors.fill: parent; anchors.rightMargin: controls.width + 18
        property point pressPosition
        onPressed: mouse => { pressPosition = Qt.point(mouse.x, mouse.y) }
        onPositionChanged: mouse => {
            if (pressed && Math.abs(mouse.x - pressPosition.x) + Math.abs(mouse.y - pressPosition.y) > 4)
                chrome.targetWindow.startSystemMove()
        }
        onDoubleClicked: chrome.targetWindow.toggleMaximized()
    }
    Label { anchors.centerIn: parent; text: "KMusic"; color: AppTheme.mutedText; font.pixelSize: 12 }
    KosWindowControls {
        id: controls
        targetWindow: chrome.targetWindow
        maximizeMode: true
        circleSize: 14; buttonWidth: 14; buttonHeight: 14; spacing: 14
        anchors.right: parent.right; anchors.rightMargin: 14.5
        anchors.top: parent.top; anchors.topMargin: 10.5
    }
}
