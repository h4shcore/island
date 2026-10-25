pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Singleton {
    id: root

    property string kind: "volume"   // volume | brightness | battery
    property real value: 0
    property bool muted: false
    property bool charging: false
    property string label: ""
    property bool ready: false
    signal triggered()

    readonly property string icon: {
        if (kind === "battery") {
            if (charging) return "battery_charging_full"
            return value > 0.85 ? "battery_full" : value > 0.7 ? "battery_6_bar" : value > 0.55 ? "battery_5_bar"
                 : value > 0.4 ? "battery_4_bar" : value > 0.25 ? "battery_3_bar" : value > 0.1 ? "battery_2_bar" : "battery_alert"
        }
        if (kind === "brightness")
            return value > 0.66 ? "brightness_high" : value > 0.33 ? "brightness_medium" : "brightness_low"
        if (muted) return "volume_off"
        if (value <= 0.001) return "volume_mute"
        return value < 0.5 ? "volume_down" : "volume_up"
    }

    function show(k, v, m) {
        kind = k
        value = v
        muted = m
        charging = false
        label = ""
        triggered()
    }

    function showBattery(pct, chg, lbl) {
        kind = "battery"
        value = Math.max(0, Math.min(1, pct))
        muted = false
        charging = chg
        label = lbl || (chg ? "Charging" : "Battery")
        triggered()
    }

    // ---- volume (automatic, via PipeWire) ----
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    // ignore the burst of property changes at startup
    Timer {
        interval: 1500
        running: true
        onTriggered: {
            const d = UPower.displayDevice
            if (d && d.isPresent) root._lastState = d.state
            root.ready = true
        }
    }

    function fromAudio() {
        const a = Pipewire.defaultAudioSink?.audio
        if (!a || !ready) return
        show("volume", a.volume, a.muted)
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio ?? null
        function onVolumeChanged() { root.fromAudio() }
        function onMutedChanged() { root.fromAudio() }
    }

    // ---- battery charger plug/unplug & low-battery live peek (via UPower) ----
    property int _lastState: -1
    property bool _warned15: false
    property bool _warned5: false

    Connections {
        target: UPower.displayDevice
        function onStateChanged() {
            const d = UPower.displayDevice
            if (!d || !d.isPresent || !root.ready) return
            if (d.state === root._lastState) return
            root._lastState = d.state
            const chg = d.state === UPowerDeviceState.Charging || d.state === UPowerDeviceState.FullyCharged
            if (chg) {
                root._warned15 = false
                root._warned5 = false
                root.showBattery(d.percentage, true, d.state === UPowerDeviceState.FullyCharged ? "Charged" : "Charging")
            } else if (d.state === UPowerDeviceState.Discharging) {
                root.showBattery(d.percentage, false, "On Battery")
            }
        }
        function onPercentageChanged() {
            const d = UPower.displayDevice
            if (!d || !d.isPresent || !root.ready) return
            if (d.state !== UPowerDeviceState.Discharging) return
            if (d.percentage <= 0.05 && !root._warned5) {
                root._warned5 = true
                root._warned15 = true
                root.showBattery(d.percentage, false, "Critical")
            } else if (d.percentage <= 0.15 && !root._warned15) {
                root._warned15 = true
                root.showBattery(d.percentage, false, "Low Battery")
            }
        }
    }

    // ---- brightness (via IPC + brightnessctl) ----
    Process {
        id: bright
        stdout: StdioCollector {
            onStreamFinished: {
                // brightnessctl -m: name,class,cur,pct%,max
                const p = text.trim().split(",")
                if (p.length >= 5) root.show("brightness", parseInt(p[3]) / 100, false)
            }
        }
    }

    function brightness(delta) {
        bright.command = ["brightnessctl", "-m", "set", delta]
        bright.running = true
    }
}
