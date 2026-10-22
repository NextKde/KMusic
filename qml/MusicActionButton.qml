import QtQuick
import Kos.Ui
LiquidActionButton {
    materialForm: true
    shadowEnabled: false
    shadowOpacity: .06
    iconColor: destructive ? AppTheme.destructive : MusicColors.icon
    surfaceColor: materialForm && AppTheme.dark ? "#323236" : MusicColors.controlSurface
    accentColor: materialForm && AppTheme.dark ? "#48484a" : MusicColors.selectedTint
    focusRingColor: MusicColors.focus
    keyboardFocusOnly: true
}
