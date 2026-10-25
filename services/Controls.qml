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
