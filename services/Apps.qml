pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// App search + launch state for the launcher page
Singleton {
    id: root

    property string query: ""
    property int selected: 0
    property var counts: ({})     // launch counts per desktop entry id (most used float to the top)

    readonly property var all: DesktopEntries.applications.values.filter(e => !e.noDisplay)

    readonly property var results: {
        const q = query.trim().toLowerCase()
        const list = all
        const out = []
        for (let i = 0; i < list.length; i++) {
            const s = score(list[i], q)
            if (s > 0) out.push({ e: list[i], s: s })
        }
        out.sort((a, b) => (b.s - a.s) || a.e.name.localeCompare(b.e.name))
        return out.slice(0, Config.launcherMaxResults).map(o => o.e)
    }

    onQueryChanged: selected = 0

    function fuzzy(h, q) {
        let i = 0
        for (let k = 0; k < h.length && i < q.length; k++)
            if (h[k] === q[i]) i++
        return i === q.length
    }

    function score(e, q) {
        const use = counts[e.id] || 0
        if (q === "") return 1 + use
        const n = (e.name || "").toLowerCase()
        let s = 0
        if (n === q) s = 1000
        else if (n.startsWith(q)) s = 800
        else if (n.split(/[\s\-_.]+/).some(w => w.startsWith(q))) s = 600
        else if (n.includes(q)) s = 400
        else {
            const hay = ((e.genericName || "") + " " + (e.comment || "") + " " + (e.keywords ? e.keywords.join(" ") : "") + " " + (e.id || "")).toLowerCase()
            if (hay.includes(q)) s = 150
            else if (fuzzy(n, q)) s = 80
        }
        return s > 0 ? s + Math.min(30, use * 3) : 0
    }

    function move(d) {
        const n = results.length
        if (n === 0) return
        selected = (selected + d + n) % n
    }

    // clamped jumps for vim motions (no wrap-around)
    function jump(i) {
        const n = results.length
        if (n === 0) return
        selected = Math.max(0, Math.min(n - 1, i))
    }
    function moveBy(d) { jump(selected + d) }

    // ---- usage counts on disk ----
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/island/launcher.json"
        printErrors: false
        onLoaded: { try { root.counts = JSON.parse(text()) } catch (e) {} }
    }
    Process { id: saver }
    function _save() {
        saver.command = ["sh", "-c", "mkdir -p \"$HOME/.local/state/island\" && printf %s \"$1\" > \"$HOME/.local/state/island/launcher.json\"", "sh", JSON.stringify(counts)]
        saver.running = true
    }

    function launch(e) {
        if (!e) return
        const c = Object.assign({}, counts)
        c[e.id] = (c[e.id] || 0) + 1
        counts = c
        _save()
        if (e.runInTerminal) Quickshell.execDetached(Config.terminal.concat(e.command))
        else e.execute()
    }
}
