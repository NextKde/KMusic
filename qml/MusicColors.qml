pragma Singleton
import QtQuick
import Kos.Ui
QtObject {
    readonly property int sidebarPadding: 16
    readonly property int sidebarRowHeight: 30
    readonly property int sidebarRowGap: 4
    readonly property int sidebarGroupGap: 16
    readonly property int sidebarTitleSize: 17
    readonly property int sidebarCaptionSize: 11
    readonly property int sidebarSearchSize: 13
    readonly property int sidebarSearchHeight: 34
    readonly property int sidebarSearchIconSize: 14
    readonly property int sidebarControlInset: 12
    readonly property int sidebarIconGap: 6
    readonly property color sidebarLabelPrimary: AppTheme.dark ? Qt.rgba(1, 1, 1, .92) : Qt.rgba(0, 0, 0, .92)
    readonly property color sidebarLabelSecondary: AppTheme.dark ? Qt.rgba(1, 1, 1, .62) : Qt.rgba(0, 0, 0, .62)
    readonly property color sidebarLabelTertiary: AppTheme.dark ? Qt.rgba(1, 1, 1, .40) : Qt.rgba(0, 0, 0, .40)
    readonly property color text: AppTheme.text
    readonly property color icon: AppTheme.dark ? "#cdd1d7" : "#555b63"
    readonly property color controlSurface: AppTheme.dark ? "#20252f" : "#ffffff"
    readonly property color selectedTint: AppTheme.dark ? "#a0a5ac" : "#707780"
    readonly property color hoverFill: AppTheme.withAlpha(text, .07)
    readonly property color sliderFill: AppTheme.dark ? "#bfc5cd" : "#747b84"
    readonly property color rowFill: AppTheme.dark ? "#292d33" : "#eff0f2"
    readonly property color placeholder: AppTheme.dark ? "#353a41" : "#dce0e5"
    // System accent is reserved for actual focus and meaningful on/active states.
    readonly property color focus: AppTheme.focusRing
    readonly property color sidebarAccent: AppTheme.dark ? "#ff453a" : "#fa233b"
    // Original music-navigation artwork: compact, rounded, consistent strokes.
    function sidebarIconSource(name, color) {
        const glyphs = {
            person: '<circle cx="12" cy="8" r="4"/><path d="M4 22v-2a8 8 0 0 1 16 0v2"/>', 
            account: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="9" r="3"/><path d="M5.5 18a7 7 0 0 1 13 0"/>',
            folder: '<path d="M3 7V4h7l2 3h9v14H3z"/>',
            sparkle: '<rect x="3" y="3" width="6.5" height="6.5" rx="1.4"/><rect x="14.5" y="3" width="6.5" height="6.5" rx="1.4"/><rect x="3" y="14.5" width="6.5" height="6.5" rx="1.4"/><rect x="14.5" y="14.5" width="6.5" height="6.5" rx="1.4"/>',
            search: '<circle cx="10.5" cy="10.5" r="6.7"/><path d="m15.5 15.5 5 5"/>',
            music: '<path d="M15 16.8V3.5l5 1.3v4l-5-1.3"/><ellipse cx="11.6" cy="17.9" rx="3.4" ry="2.5" fill="currentColor" stroke="none"/>',
            album: '<rect x="4" y="7" width="16" height="14" rx="2"/><path d="M6.5 4.5h11M9 2h6M14 16V10l3 1"/><ellipse cx="12.3" cy="16.6" rx="1.8" ry="1.4" fill="currentColor" stroke="none"/>',
            artist: '<rect x="8" y="2.5" width="8" height="12" rx="4"/><path d="M5 10.5v1a7 7 0 0 0 14 0v-1M12 18.5V22M8.5 22h7"/>',
            queue: '<path d="M3 5h13M3 10h13M3 15h7M18 18V10l3 1"/><ellipse cx="15.6" cy="19" rx="2.5" ry="1.8" fill="currentColor" stroke="none"/>',
            playlist: '<path d="M3 5h13M3 10h13M3 15h7M18 18V10l3 1"/><ellipse cx="15.6" cy="19" rx="2.5" ry="1.8" fill="currentColor" stroke="none"/>'
        }
        const ink = (color || sidebarAccent).toString()
        return "data:image/svg+xml;utf8," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" color="' + ink + '" fill="none" stroke="' + ink + '" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">' + (glyphs[name] || glyphs.music) + '</svg>')
    }

}
