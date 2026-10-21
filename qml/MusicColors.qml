pragma Singleton
import QtQuick
import Kos.Ui
QtObject {
    readonly property color text: AppTheme.text
    readonly property color icon: AppTheme.dark ? "#cdd1d7" : "#555b63"
    readonly property color controlSurface: AppTheme.dark ? "#30343a" : "#ffffff"
    readonly property color selectedTint: AppTheme.dark ? "#a0a5ac" : "#707780"
    readonly property color hoverFill: AppTheme.withAlpha(text, .07)
    readonly property color sliderFill: AppTheme.dark ? "#bfc5cd" : "#747b84"
    readonly property color rowFill: AppTheme.dark ? "#292d33" : "#eff0f2"
    readonly property color placeholder: AppTheme.dark ? "#353a41" : "#dce0e5"
    // System accent is reserved for actual focus and meaningful on/active states.
    readonly property color focus: AppTheme.focusRing
}
