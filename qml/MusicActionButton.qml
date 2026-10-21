import QtQuick
import Kos.Ui
LiquidActionButton {
    shadowEnabled: !flat
    shadowOpacity: .06
    iconColor: destructive ? AppTheme.destructive : MusicColors.icon
    surfaceColor: MusicColors.controlSurface
    accentColor: MusicColors.selectedTint
    focusRingColor: MusicColors.focus
    keyboardFocusOnly: true
}
