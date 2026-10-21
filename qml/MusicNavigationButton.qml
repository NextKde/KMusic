import QtQuick
import Kos.Ui
LiquidNavigationButton {
    showIdleBackground: false
    iconColor: MusicColors.sidebarAccent
    iconSource: iconName.length ? MusicColors.sidebarIconSource(iconName) : ""
    selectionColor: MusicColors.selectedTint
    hoverColor: MusicColors.hoverFill
    focusRingColor: MusicColors.focus
    keyboardFocusOnly: true
}
