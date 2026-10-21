import QtQuick
import Kos.Ui
LiquidActionButton {
    iconColor: destructive ? AppTheme.destructive : MusicColors.icon
    surfaceColor: MusicColors.controlSurface
    accentColor: MusicColors.selectedTint
    focusRingColor: MusicColors.focus
    keyboardFocusOnly: true
}
