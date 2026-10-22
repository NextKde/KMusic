import QtQuick
import QtTest
import NextKde.Music

TestCase {
    name: "SearchDialogInteraction"
    visible: true
    when: windowShown
    width: 640; height: 520
    SearchDialog { id: popup }
    SignalSpy { id: submitted; target: popup; signalName: "searchRequested" }
    function inputIn(item) {
        if (item instanceof MusicTextField) return item
        for (let child of item.children) {
            const result = inputIn(child)
            if (result) return result
        }
        return null
    }
    function init() { popup.clearAllHistory(); submitted.clear(); popup.sourceId = "netease" }
    function cleanup() { popup.close(); popup.clearAllHistory() }
    function test_open_focus_and_submit() {
        popup.initialQuery = "old query"
        popup.open()
        tryCompare(popup, "opened", true)
        const input = inputIn(popup.contentItem)
        verify(input !== null)
        compare(input.text, "old query")
        verify(input.activeFocus)
        input.text = "  new query  "
        keyClick(Qt.Key_Return)
        compare(submitted.count, 1)
        compare(submitted.signalArguments[0][0], "new query")
        compare(popup.history[0], "new query")
        tryCompare(popup, "visible", false)
    }
    function test_history_is_source_scoped() {
        popup.submit("online query")
        popup.sourceId = "local"
        compare(popup.history.length, 0)
        popup.submit("local query")
        compare(popup.history[0], "local query")
        popup.sourceId = "netease"
        compare(popup.history[0], "online query")
    }
    function test_blank_query_does_not_submit() {
        popup.submit("   ")
        compare(submitted.count, 0)
        compare(popup.history.length, 0)
    }
}
