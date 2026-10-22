// QSettings may contain old or malformed values. Never expose a non-list model
// or non-string entry to the search dialog's delegates and submit path.
export function read(serialized) {
    let stored
    try { stored = JSON.parse(serialized) } catch (_) { return {} }
    if (!stored || typeof stored !== "object" || Array.isArray(stored)) return {}
    const result = {}
    for (const source of ["local", "netease"]) {
        if (!Array.isArray(stored[source])) continue
        const seen = new Set()
        const entries = []
        for (const item of stored[source]) {
            if (typeof item !== "string") continue
            const text = item.trim().slice(0, 200)
            const key = text.toLowerCase()
            if (!text || seen.has(key)) continue
            seen.add(key)
            entries.push(text)
            if (entries.length === 20) break
        }
        result[source] = entries
    }
    return result
}
