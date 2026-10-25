pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Wallpaper library + switcher. Sets the wallpaper, then runs matugen so
// ~/.config/quickshell/colors.json (and everything else you template) re-themes.
// The matugen choices made in the switcher (mode, scheme, contrast, accent) are
// remembered in ~/.local/state/island/matugen.json.
Singleton {
    id: root

    // settings live in settings.json (see Config.qml)
    readonly property string dir: Config.wallpaperDir
    readonly property var setter: Config.wallpaperSetter

    // ---- matugen options (UI-editable) ----
    property string mode: Config.matugenMode      // dark | light
    property string scheme: Config.matugenScheme  // "" = matugen default (tonal spot)
    property real contrast: Config.matugenContrast // -1 .. 1
    property string accent: ""                    // "" = from the wallpaper, else "#rrggbb"

    readonly property var schemes: [
        { id: "scheme-tonal-spot",  name: "Tonal" },
        { id: "scheme-content",     name: "Content" },
        { id: "scheme-expressive",  name: "Expressive" },
        { id: "scheme-fidelity",    name: "Fidelity" },
        { id: "scheme-fruit-salad", name: "Fruit" },
        { id: "scheme-monochrome",  name: "Mono" },
        { id: "scheme-neutral",     name: "Neutral" },
        { id: "scheme-rainbow",     name: "Rainbow" }
    ]
    readonly property string schemeId: scheme !== "" ? scheme : "scheme-tonal-spot"
    readonly property string schemeLabel: {
        const s = schemes.find(x => x.id === schemeId)
        return s ? s.name : schemeId
    }
    readonly property string contrastLabel: (contrast >= 0 ? "+" : "") + contrast.toFixed(1)

    property var files: []
    property string current: ""
    property bool busy: false
    property string error: ""

    readonly property int index: files.indexOf(current)
    readonly property string status: error !== "" ? error
                                   : busy ? "Applying…"
                                   : files.length + (files.length === 1 ? " image" : " images")

    function baseName(p) {
        if (!p) return ""
        const f = p.split("/").pop()
        const i = f.lastIndexOf(".")
        return i > 0 ? f.slice(0, i) : f
    }

    // ---- scan folder ----
    Process {
        id: lister
        command: ["sh", "-c", "find -L \"$1\" -maxdepth 3 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null | sort", "sh", root.dir]
        stdout: StdioCollector {
            onStreamFinished: root.files = text.split("\n").filter(l => l.length > 0)
        }
    }
    function refresh() { lister.running = true }
    Component.onCompleted: refresh()

    // ---- remember the current wallpaper + matugen choices ----
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/island/wallpaper"
        printErrors: false
        onLoaded: root.current = text().trim()
    }
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/island/matugen.json"
        printErrors: false
        onLoaded: {
            try {
                const o = JSON.parse(text())
                if (o.mode === "dark" || o.mode === "light") root.mode = o.mode
                if (typeof o.scheme === "string") root.scheme = o.scheme
                if (typeof o.contrast === "number") root.contrast = Math.max(-1, Math.min(1, o.contrast))
                if (typeof o.accent === "string") root.accent = o.accent
            } catch (e) {}
        }
    }
    Process { id: saver }
    Process { id: optSaver }
    function _save(p) {
        saver.command = ["sh", "-c", "mkdir -p \"$HOME/.local/state/island\" && printf %s \"$1\" > \"$HOME/.local/state/island/wallpaper\"", "sh", p]
        saver.running = true
    }
    function _saveOpts() {
        const o = JSON.stringify({ mode: mode, scheme: scheme, contrast: contrast, accent: accent })
        optSaver.command = ["sh", "-c", "mkdir -p \"$HOME/.local/state/island\" && printf %s \"$1\" > \"$HOME/.local/state/island/matugen.json\"", "sh", o]
        optSaver.running = true
    }

    // ---- apply (setter + matugen, each keeps only the latest queued request) ----
    property string _pendingSet: ""
    property string _pendingMat: ""
    property bool _queued: false

    Process {
        id: setProc
        onExited: (code, status) => { if (code !== 0) root.error = "Setter failed (is " + (root.setter[0] || "it") + " running?)" }
        onRunningChanged: {
            if (running || root._pendingSet === "") return
            const p = root._pendingSet
            root._pendingSet = ""
            root._runSet(p)
        }
    }
    Process {
        id: matProc
        onExited: (code, status) => { if (code !== 0) root.error = "matugen failed" }
        onRunningChanged: {
            if (running) return
            if (root._queued) {
                root._queued = false
                root._runMat(root._pendingMat)
            } else {
                root.busy = false
            }
        }
    }
    Timer { interval: 20000; running: root.busy; onTriggered: root.busy = false }

    function _runSet(p) {
        setProc.command = setter.map(a => a === "%f" ? p : a)
        setProc.running = true
    }
    function _runMat(p) {
        const c = ["matugen"]
        if (accent !== "") c.push("color", "hex", accent)
        else c.push("image", p)
        c.push("-m", mode)
        if (scheme !== "") c.push("-t", scheme)
        if (Math.abs(contrast) > 0.001) c.push("--contrast", contrast.toFixed(2))
        matProc.command = c
        matProc.running = true
    }
    function _rerun() {
        if (current === "" && accent === "") return
        error = ""
        busy = true
        if (matProc.running) { _pendingMat = current; _queued = true } else _runMat(current)
    }

    function apply(p) {
        if (!p) return
        current = p
        error = ""
        busy = true
        _save(p)
        if (setProc.running) _pendingSet = p; else _runSet(p)
        if (matProc.running) { _pendingMat = p; _queued = true } else _runMat(p)
    }

    // ---- option setters (each one re-themes with the current wallpaper) ----
    function setMode(m) {
        if (m !== "dark" && m !== "light") return
        mode = m
        _saveOpts()
        _rerun()
    }
    function setScheme(s) {
        scheme = s
        _saveOpts()
        _rerun()
    }
    function setAccent(hex) {
        accent = hex
        _saveOpts()
        _rerun()
    }
    function setContrast(v) {
        contrast = Math.max(-1, Math.min(1, Math.round(v * 10) / 10))
        contrastTimer.restart()        // sliders fire a lot: only theme once it settles
    }
    Timer { id: contrastTimer; interval: 280; onTriggered: { root._saveOpts(); root._rerun() } }

    function resetStyle() {
        scheme = Config.matugenScheme
        contrast = Config.matugenContrast
        accent = ""
        _saveOpts()
        _rerun()
    }

    function restore() { if (current !== "") apply(current) }

    function step(d) {
        if (files.length === 0) return
        const i = index < 0 ? 0 : (index + d + files.length) % files.length
        apply(files[i])
    }
    function next() { step(1) }
    function prev() { step(-1) }
    function random() {
        if (files.length === 0) return
        let i = Math.floor(Math.random() * files.length)
        if (files.length > 1 && files[i] === current) i = (i + 1) % files.length
        apply(files[i])
    }
}
