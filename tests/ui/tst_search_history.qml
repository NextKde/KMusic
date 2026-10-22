import QtQuick
import QtTest
import "../../qml/SearchHistory.mjs" as SearchHistory

TestCase {
    name: "SearchHistoryRecovery"
    function test_invalid_storage_data() {
        return [{tag:"broken json",stored:"{"}, {tag:"null root",stored:"null"},
            {tag:"array root",stored:"[]"}, {tag:"string list",stored:'{"netease":"old query"}'},
            {tag:"object list",stored:'{"netease":{"query":"old query"}}'}]
    }
    function test_invalid_storage(data) {
        compare(JSON.stringify(SearchHistory.read(data.stored)), "{}")
    }
    function test_sanitize_preserves_source_and_order() {
        const history = SearchHistory.read('{"netease":["  Song  ",null,42,"song","","Other"],"local":["Local"]}')
        compare(history.netease.length, 2)
        compare(history.netease[0], "Song")
        compare(history.netease[1], "Other")
        compare(history.local[0], "Local")
    }
    function test_bound_persisted_entries() {
        const queries = []
        for (let i = 0; i < 30; ++i) queries.push("query" + i + "x".repeat(220))
        const history = SearchHistory.read(JSON.stringify({local: queries}))
        compare(history.local.length, 20)
        compare(history.local[0].length, 200)
    }
}
