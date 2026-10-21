import QtQuick
import Kos.Ui
LiquidNavigationButton {
    iconColor: checked ? MusicColors.text : MusicColors.icon
    selectionColor: MusicColors.selectedTint
    hoverColor: MusicColors.hoverFill
    focusRingColor: MusicColors.focus
    keyboardFocusOnly: true
}
