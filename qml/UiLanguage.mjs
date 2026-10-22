// Engine UI language follows the saved preference, or the system by default.
export function chinese() {
    if (Qt.uiLanguage) return Qt.uiLanguage.toLowerCase().startsWith("zh")
    const locale = Qt.locale()
    const languages = locale.uiLanguages
    const primary = languages.length ? languages[0] : locale.name
    return primary.toLowerCase().startsWith("zh")
}
export function text(english, chineseText) {
    return chinese() ? chineseText : english
}
