import QtQuick
// An actual opaque native background WINDOW; never injected into app pixels.
Rectangle {
    color: "#d87a4a"
    Repeater {
        model: Math.ceil(parent.width / 16)
        Rectangle {
            required property int index
            x: index * 16; width: 8; height: parent.height
            color: "#226b9a"
        }
    }
    Repeater {
        model: Math.ceil(parent.height / 160)
        Rectangle {
            required property int index
            y: index * 160; height: 32; width: parent.width
            color: "#9b4f7a"
        }
    }
}
