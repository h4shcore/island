pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Emoji + symbol picker backend.
//   needs:  wl-clipboard (wl-copy);  wtype only if "emoji.typeAfterCopy" is on
//   recents are kept in  $XDG_STATE_HOME/island/emoji-recent.json
Singleton {
    id: root

    readonly property var categories: [
        { id: "recent",     icon: "history",                label: "Recent" },
        { id: "smileys",    icon: "emoji_emotions",         label: "Smileys & Emotion" },
        { id: "people",     icon: "emoji_people",           label: "People & Body" },
        { id: "nature",     icon: "emoji_nature",           label: "Animals & Nature" },
        { id: "food",       icon: "emoji_food_beverage",    label: "Food & Drink" },
        { id: "travel",     icon: "emoji_transportation",   label: "Travel & Places" },
        { id: "activities", icon: "emoji_events",           label: "Activities" },
        { id: "objects",    icon: "emoji_objects",          label: "Objects" },
        { id: "symbols",    icon: "emoji_symbols",          label: "Symbols" },
        { id: "flags",      icon: "flag",                   label: "Flags" },
        { id: "special",    icon: "functions",              label: "Math, arrows, currency, Greek ..." }
    ]

    property string query: ""
    property string category: "smileys"
    property int selected: 0
    property var recent: []                 // characters, newest first

    // ---- dataset (parsed once) ----
    readonly property var all: {
        const out = []
        const raw = EmojiData.raw
        for (let i = 0; i < raw.length; i++) {
            const p = raw[i].split("|")
            if (p.length < 4) continue
            out.push({ c: p[0], name: p[1], kw: p[2], cat: p[3], hay: (p[1] + " " + p[2]).toLowerCase(), i: i })
        }
        return out
    }
    readonly property var byCat: {
        const m = {}
        for (const e of all) (m[e.cat] = m[e.cat] || []).push(e)
        return m
    }
    readonly property var byChar: {
        const m = {}
        for (const e of all) if (!(e.c in m)) m[e.c] = e
        return m
    }

    readonly property var results: {
        const words = query.trim().toLowerCase().split(/\s+/).filter(w => w.length > 0)
        if (words.length > 0) {
            const hits = []
            for (const e of all) {
                let score = 0
                let ok = true
                for (const w of words) {
                    if (!e.hay.includes(w)) { ok = false; break }
                    const n = e.name.toLowerCase()
                    if (n === w) score -= 3
                    else if (n.startsWith(w)) score -= 2
                    else if (n.includes(w)) score -= 1
                }
                if (ok) hits.push({ e: e, s: score })
            }
            hits.sort((a, b) => (a.s - b.s) || (a.e.i - b.e.i))
            return hits.slice(0, 400).map(h => h.e)
        }
        if (category === "recent") return recent.map(c => byChar[c]).filter(e => e !== undefined)
        return byCat[category] || []
    }
    readonly property var current: results[selected] ?? null

    onQueryChanged: selected = 0
    onCategoryChanged: selected = 0

    // ---- navigation ----
    function jump(i) {
        const n = results.length
        if (n === 0) return
        selected = Math.max(0, Math.min(n - 1, i))
    }
    function moveBy(d) { jump(selected + d) }
    function cycleCategory(d) {
        const ids = categories.map(c => c.id)
        const at = Math.max(0, ids.indexOf(category))
        category = ids[(at + d + ids.length) % ids.length]
    }
    function open() {
        query = ""
        selected = 0
        category = recent.length > 0 ? "recent" : "smileys"
    }

    // ---- actions ----
    function pick(e) {
        if (!e) return
        Quickshell.execDetached(["wl-copy", "--", e.c])
        if (Config.emojiTypeAfterCopy)
            Quickshell.execDetached(["sh", "-c", "sleep 0.25; wtype -- \"$1\"", "sh", e.c])
        remember(e.c)
    }

    function remember(c) {
        recent = [c].concat(recent.filter(x => x !== c)).slice(0, Math.max(1, Config.emojiRecentMax))
        Quickshell.execDetached([
            "sh", "-c", "mkdir -p \"$(dirname \"$2\")\" && printf '%s' \"$1\" > \"$2\"",
            "sh", JSON.stringify(recent), storePath
        ])
    }
    function clearRecent() {
        recent = []
        Quickshell.execDetached(["rm", "-f", storePath])
        if (category === "recent") selected = 0
    }

    readonly property string storePath:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/island/emoji-recent.json"

    FileView {
        path: root.storePath
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                const v = JSON.parse(text())
                if (Array.isArray(v)) root.recent = v.filter(x => typeof x === "string")
            } catch (err) { }
        }
    }
}
