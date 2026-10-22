import QtQuick
import QtTest
import Kos.Ui
import NextKde.Music

TestCase {
    name: "MusicInput"
    when: windowShown
    width: 320; height: 100
    MusicTextField { id: search; width: 280; height: 36; searchField: true }
    function cleanup() { search.text = ""; AppTheme.appearanceMode = "system" }
    function test_clear_preserves_focus() {
        search.text = "test query"
        mouseClick(search, search.width - 18, search.height / 2)
        compare(search.text, "")
        verify(search.activeFocus)
    }
    function test_keyboard_input() {
        search.forceActiveFocus()
        keyClick(Qt.Key_A)
        compare(search.text, "a")
    }
    function test_solid_field_fill_data() { return [{tag:"light",mode:"light",fill:"#f0f0f3"},{tag:"dark",mode:"dark",fill:"#303036"}] }
    function test_solid_field_fill(data) {
        AppTheme.appearanceMode = data.mode
        compare(search.glassColor.toString(), data.fill)
        compare(search.glassColor.a, 1)
        verify(search.textColor.toString() !== search.glassColor.toString())
    }
}
