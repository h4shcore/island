pragma Singleton
import QtQuick
import Quickshell

// Live countdown / Pomodoro timer service for the island.
// Named Countdown (not Timer) so it never shadows QtQuick.Timer.
Singleton {
    id: root

    property int total: 0
    property int remaining: 0
    property bool running: false
    property bool ringing: false
    property string label: "Timer"

    readonly property bool active: total > 0 || ringing
    readonly property real progress: total > 0 ? Math.max(0, Math.min(1, remaining / total)) : 0
    readonly property string formatted: fmt(remaining)

    readonly property var presets: [
        { label: "1m",  secs: 60   },
        { label: "5m",  secs: 300  },
        { label: "10m", secs: 600  },
        { label: "25m", secs: 1500 },
        { label: "45m", secs: 2700 }
    ]

    signal started()
    signal finished()

    function fmt(s) {
        s = Math.max(0, Math.floor(s))
        const h = Math.floor(s / 3600)
        const m = Math.floor((s % 3600) / 60)
        const r = s % 60
        const mm = (h > 0 && m < 10 ? "0" : "") + m
        const rr = (r < 10 ? "0" : "") + r
        return h > 0 ? (h + ":" + mm + ":" + rr) : (mm + ":" + rr)
    }

    // Accepts "25m", "1h30m", "90s", "5:00", or plain seconds ("300").
    function parse(spec) {
        if (typeof spec === "number") return Math.max(0, Math.floor(spec))
        const str = String(spec || "").trim().toLowerCase()
        if (str === "") return 0
        if (str.includes(":")) {
            const p = str.split(":").map(x => parseInt(x) || 0)
            if (p.length === 3) return p[0] * 3600 + p[1] * 60 + p[2]
            if (p.length === 2) return p[0] * 60 + p[1]
        }
        let secs = 0
        let matched = false
        const re = /(\d+(?:\.\d+)?)\s*([hms])/g
        let m
        while ((m = re.exec(str)) !== null) {
            matched = true
            const v = parseFloat(m[1])
            const u = m[2]
            secs += u === "h" ? v * 3600 : u === "m" ? v * 60 : v
        }
        if (matched) return Math.round(secs)
        const n = parseFloat(str)
        return isNaN(n) ? 0 : Math.round(n)
    }

    function start(spec, lbl) {
        const s = typeof spec === "number" ? spec : parse(spec)
        if (s <= 0) return
        ringTimer.stop()
        ringing = false
        total = s
        remaining = s
        label = lbl && lbl !== "" ? lbl : (s === 1500 ? "Pomodoro" : "Timer")
        running = true
        started()
    }

    function add(spec) {
        const s = typeof spec === "number" ? spec : parse(spec)
        if (s === 0) return
        if (ringing) {
            ringTimer.stop()
            ringing = false
        }
        if (total <= 0) {
            start(Math.max(1, s), "Timer")
            return
        }
        remaining = Math.max(0, remaining + s)
        total = Math.max(total, remaining)
        if (remaining === 0) {
            running = false
            total = 0
        }
    }

    function pause() {
        running = false
    }

    function resume() {
        if (ringing) { dismiss(); return }
        if (remaining > 0) running = true
    }

    function toggle() {
        if (ringing) { dismiss(); return }
        if (running) pause()
        else if (remaining > 0) resume()
        else start(1500, "Pomodoro")
    }

    function reset() {
        ringTimer.stop()
        running = false
        ringing = false
        total = 0
        remaining = 0
        label = "Timer"
    }

    function dismiss() {
        ringTimer.stop()
        ringing = false
        if (remaining <= 0) {
            total = 0
            label = "Timer"
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            if (root.remaining > 1) {
                root.remaining -= 1
            } else {
                root.remaining = 0
                root.running = false
                root.ringing = true
                ringTimer.restart()
                root.finished()
            }
        }
    }

    Timer {
        id: ringTimer
        interval: 12000
        onTriggered: root.dismiss()
    }
}
