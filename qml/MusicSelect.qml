import QtQuick
import Kos.Ui
LiquidSelect {
    appearanceMode: AppTheme.dark ? "dark" : "light"
    accentColor: MusicColors.selectedTint
    selectedTextColor: MusicColors.text
    focusRingColor: MusicColors.focus
    sheetColor: AppTheme.dark ? "#2a2d31" : "#f3f4f5"
}
