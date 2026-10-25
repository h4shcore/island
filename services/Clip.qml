pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Clipboard history on top of cliphist (+ wl-clipboard).
//   needs:  cliphist, wl-clipboard
//   fill it: set "clipboard.watch": true in settings.json, or run these yourself at login:
//            wl-paste --type text  --watch cliphist store
//            wl-paste --type image --watch cliphist store
Singleton {
    id: root

    property string query: ""
    property int selected: 0
    property var items: []          // { id, raw, text, image, sub }

    readonly property var results: {
        const words = query.trim().toLowerCase().split(/\s+/).filter(w => w.length > 0)
        if (words.length === 0) return items
        return items.filter(it => {
            const t = it.text.toLowerCase()
            return words.every(w => t.includes(w))
        })
    }
    onQueryChanged: selected = 0

    // ---- load history ----
    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                const lines = text.split("\n")
                for (let i = 0; i < lines.length && out.length < Config.clipboardMaxItems; i++) {
                    const raw = lines[i]
                    const tab = raw.indexOf("\t")
                    if (tab < 1) continue
                    const id = raw.slice(0, tab)
                    const body = raw.slice(tab + 1).trim()
                    const m = body.match(/^\[\[ binary data (.+) \]\]$/)
                    out.push({
                        id: id,
                        raw: raw,
                        image: m !== null,
                        text: m !== null ? "Image" : body,
                        sub: m !== null ? m[1] : body.length + (body.length === 1 ? " character" : " characters")
                    })
                }
                root.items = out
                if (root.selected >= root.results.length) root.selected = Math.max(0, root.results.length - 1)
            }
        }
    }
    function refresh() { if (!lister.running) lister.running = true }

    // ---- actions ----
    function copy(it) {
        if (!it) return
        Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", it.id])
    }

    Process { id: deleter; onRunningChanged: if (!running) root.refresh() }
    function remove(it) {
        if (!it) return
        items = items.filter(x => x.id !== it.id)           // instant feedback
        if (selected >= results.length) selected = Math.max(0, results.length - 1)
        deleter.command = ["sh", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "sh", it.raw]
        deleter.running = true
    }

    Process { id: wiper; onRunningChanged: if (!running) root.refresh() }
    function wipe() {
        items = []
        selected = 0
        wiper.command = ["cliphist", "wipe"]
        wiper.running = true
    }

    // ---- navigation ----
    function move(d) {
        const n = results.length
        if (n === 0) return
        selected = (selected + d + n) % n
    }
    function jump(i) {
        const n = results.length
        if (n === 0) return
        selected = Math.max(0, Math.min(n - 1, i))
    }
    function moveBy(d) { jump(selected + d) }

    // ---- optional clipboard watchers (leave off if your compositor already runs them) ----
    Process {
        running: Config.clipboardWatch
        command: ["wl-paste", "--type", "text", "--watch", "cliphist", "store"]
    }
    Process {
        running: Config.clipboardWatch
        command: ["wl-paste", "--type", "image", "--watch", "cliphist", "store"]
    }
}
