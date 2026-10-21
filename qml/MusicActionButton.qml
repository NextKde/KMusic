import QtQuick
import Kos.Ui
LiquidActionButton {
    materialForm: true
    shadowEnabled: false
    shadowOpacity: .06
    iconColor: destructive ? AppTheme.destructive : MusicColors.icon
    surfaceColor: MusicColors.controlSurface
    accentColor: MusicColors.selectedTint
    focusRingColor: MusicColors.focus
    keyboardFocusOnly: true
}
