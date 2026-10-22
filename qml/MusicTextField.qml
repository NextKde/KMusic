import QtQuick
import Kos.Ui
import "UiLanguage.mjs" as Language

// App defaults only; rendering and liquid optics remain in the shared control.
LiquidTextField {
    id: field
    property bool searchField: false
    materialForm: true
    implicitHeight: 36
    font.pixelSize: 13
    textColor: AppTheme.text
    mutedTextColor: AppTheme.dark ? "#b1b2bb" : "#64646e"
    glassColor: materialForm ? (AppTheme.dark ? "#303036" : "#f0f0f3")
        : (AppTheme.dark ? Qt.rgba(32 / 255, 37 / 255, 47 / 255, .20) : Qt.rgba(1, 1, 1, .20))
    outlineColor: materialForm ? AppTheme.withAlpha(AppTheme.text, activeFocus ? .24 : .10) : "transparent"
    leftPadding: searchField ? 34 : 12
    rightPadding: clearAction.visible ? 38 : 12
    Accessible.name: placeholderText
    MusicActionButton {
        id: clearAction
        visible: field.searchField && field.enabled && !field.readOnly && field.text.length > 0
        anchors.right: parent.right
        anchors.rightMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        width: 26; height: 26
        flat: true; iconOnly: true; iconName: "close"; iconSize: 12
        iconColor: field.mutedTextColor
        Accessible.name: Language.text("Clear search", "清除搜索")
        onClicked: { field.clear(); field.forceActiveFocus() }
    }
    Image {
        visible: parent.searchField
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 14; height: 14
        source: MusicColors.sidebarIconSource("search", parent.mutedTextColor)
    }
}
