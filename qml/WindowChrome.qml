import QtQuick
import QtQuick.Window
import Kos.Ui
Item {
    id: chrome
    required property var targetWindow
    height: 30
    MouseArea {
        // 控制按钮移到左边后，拖拽区要避开左边这一块
        anchors.fill: parent; anchors.leftMargin: controls.width + 22
        property point pressPosition
        property bool moveArmed: false
        onPressed: mouse => { pressPosition = Qt.point(mouse.x, mouse.y); moveArmed = true }
        onReleased: moveArmed = false
        onCanceled: moveArmed = false
        onPositionChanged: mouse => {
            if (pressed && moveArmed && (Math.abs(mouse.x - pressPosition.x) > 4 || Math.abs(mouse.y - pressPosition.y) > 4)) {
                moveArmed = false; chrome.targetWindow.startSystemMove()
            }
        }
        onDoubleClicked: { moveArmed = false; chrome.targetWindow.toggleMaximized() }
    }
    KosWindowControls {
        id: controls
        targetWindow: chrome.targetWindow; maximizeMode: true
        circleSize: 14; buttonWidth: 14; buttonHeight: 14; spacing: 14
        // 从右侧改到左侧：符合 macOS 惯例（红绿灯在左上角）
        anchors.left: parent.left; anchors.leftMargin: 14.5
        anchors.top: parent.top; anchors.topMargin: 10.5
    }
}
