// Follow the first system UI language; use English for non-Chinese locales.
export function chinese() {
    const locale = Qt.locale()
    const languages = locale.uiLanguages
    const primary = languages.length ? languages[0] : locale.name
    return primary.toLowerCase().startsWith("zh")
}
export function text(english, chineseText) {
    return chinese() ? chineseText : english
}
