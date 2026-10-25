pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

// State + actions behind the control center
Singleton {
    id: root

    // ---- volume ----
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property string volumeIcon: muted || volume <= 0.001 ? "volume_off"
                                       : volume < 0.34 ? "volume_mute"
                                       : volume < 0.67 ? "volume_down" : "volume_up"

    function setVolume(v) {
        if (!sink || !sink.audio) return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1, v))
    }

    // ---- brightness ----
    property real brightness: 0

    Process {
        id: bGet
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split("\n")[0].split(",")
                if (p.length >= 5) root.brightness = parseInt(p[3]) / 100
            }
        }
    }

    property real _pending: -1
    Process {
        id: bSet
        onRunningChanged: if (!running && root._pending >= 0) root._flush()
    }
    function _flush() {
        const v = _pending
        _pending = -1
        bSet.command = ["brightnessctl", "-q", "set", Math.max(1, Math.round(v * 100)) + "%"]
        bSet.running = true
    }
    function setBrightness(v) {
        brightness = Math.max(0.01, Math.min(1, v))
        _pending = brightness
        if (!bSet.running) _flush()
    }

    // ---- wifi (NetworkManager radio) ----
    property bool wifi: false
    Process {
        id: wGet
        command: ["nmcli", "-t", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: root.wifi = text.trim() === "enabled" }
    }
    Process { id: wSet }
    function setWifi(on) {
        wifi = on
        wSet.command = ["nmcli", "radio", "wifi", on ? "on" : "off"]
        wSet.running = true
        if (on) wifiScanTimer.restart()
    }
    function toggleWifi() { setWifi(!wifi) }

    // network name shown under the Wi-Fi toggle
    property string wifiName: ""
    Process {
        id: sGet
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n").find(x => x.startsWith("yes:"))
                root.wifiName = l ? l.slice(4).replace(/\\:/g, ":") : ""
            }
        }
    }

    // ---- bluetooth ----
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btAvailable: btAdapter !== null && btAdapter !== undefined
    readonly property bool btOn: btAvailable && btAdapter.enabled
    readonly property string btDevice: {
        if (!btOn || !Bluetooth.devices) return ""
        const v = Bluetooth.devices.values
        for (let i = 0; i < v.length; i++)
            if (v[i].connected) return v[i].name
        return ""
    }
    function toggleBluetooth() { if (btAvailable) btAdapter.enabled = !btAdapter.enabled }

    // ---- airplane: everything off / everything back on ----
    readonly property bool airplane: !wifi && !btOn
    function toggleAirplane() {
        const on = airplane
        setWifi(on)
        if (btAvailable) btAdapter.enabled = on
    }


    // ---- bluetooth devices (picker) ----
    readonly property var btList: {
        if (!btOn || !Bluetooth.devices) return []
        const v = Array.from(Bluetooth.devices.values).filter(d => d.name !== "")
        v.sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
        return v
    }
    function btScan(on) { if (btAvailable && btAdapter.enabled) btAdapter.discovering = on }
    function btActivate(d) {
        if (d.connected) d.disconnect()
        else if (d.paired) d.connect()
        else d.pair()
    }

    // ---- wi-fi networks (picker) ----
    property var wifiList: []          // [{ ssid, signal, secure, active }]
    property var wifiKnown: []         // saved wifi connection names
    property bool wifiScanning: false
    property string wifiBusy: ""       // ssid being connected
    property string wifiMsg: ""

    // nmcli -t output: fields split on ":", a literal colon is escaped as "\:"
    function _split(line) {
        const out = []
        let cur = ""
        for (let i = 0; i < line.length; i++) {
            const ch = line[i]
            if (ch === "\\" && i + 1 < line.length) { cur += line[i + 1]; i++ }
            else if (ch === ":") { out.push(cur); cur = "" }
            else cur += ch
        }
        out.push(cur)
        return out
    }

    Process {
        id: nList
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const best = {}
                text.split("\n").forEach(l => {
                    if (!l) return
                    const p = root._split(l)
                    if (!p[1]) return
                    const o = { ssid: p[1], signal: parseInt(p[2]) || 0, secure: (p[3] || "") !== "" && p[3] !== "--", active: p[0] === "*" }
                    const e = best[o.ssid]
                    if (!e || o.active || (!e.active && o.signal > e.signal)) best[o.ssid] = o
                })
                root.wifiList = Object.values(best).sort((a, b) => (b.active - a.active) || (b.signal - a.signal))
            }
        }
    }
    Process {
        id: nKnown
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const k = []
                text.split("\n").forEach(l => {
                    const p = root._split(l)
                    if (p.length >= 2 && p[p.length - 1] === "802-11-wireless") k.push(p.slice(0, p.length - 1).join(":"))
                })
                root.wifiKnown = k
            }
        }
    }
    Process {
        id: nRescan
        command: ["nmcli", "dev", "wifi", "rescan"]
        onExited: { root.wifiScanning = false; nList.running = true }
    }
    Timer { id: wifiScanTimer; interval: 1500; onTriggered: root.scanWifi() }

    function scanWifi() {
        if (!wifi) { wifiList = []; return }
        nKnown.running = true
        nList.running = true               // show the cached list right away
        wifiScanning = true
        nRescan.running = true             // then refresh once the rescan is done
    }

    Process {
        id: nConn
        onExited: code => {
            const s = root.wifiBusy
            root.wifiBusy = ""
            root.wifiMsg = code === 0 ? "" : "Couldn't connect to " + s
            wGet.running = true; sGet.running = true; nKnown.running = true; nList.running = true
        }
    }
    function connectWifi(ssid, pw) {
        if (nConn.running) return
        wifiMsg = ""
        wifiBusy = ssid
        if (pw && pw !== "") nConn.command = ["nmcli", "dev", "wifi", "connect", ssid, "password", pw]
        else if (wifiKnown.indexOf(ssid) >= 0) nConn.command = ["nmcli", "connection", "up", "id", ssid]
        else nConn.command = ["nmcli", "dev", "wifi", "connect", ssid]
        nConn.running = true
    }
    function disconnectWifi(ssid) {
        if (nConn.running) return
        wifiMsg = ""
        wifiBusy = ssid
        nConn.command = ["nmcli", "connection", "down", "id", ssid]
        nConn.running = true
    }

    // ---- misc ----
    function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted }
    Process { id: lockProc; command: ["loginctl", "lock-session"] }
    function lock() { lockProc.running = true }

    // ---- keep awake (bound to IdleInhibitor in Island.qml) ----
    property bool keepAwake: false

    function refresh() {
        bGet.running = true
        wGet.running = true
        sGet.running = true
    }
}
