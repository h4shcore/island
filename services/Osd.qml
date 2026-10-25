pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property string kind: "volume"   // volume | brightness
    property real value: 0
    property bool muted: false
    property bool ready: false
    signal triggered()

    readonly property string icon: {
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
        triggered()
    }

    // ---- volume (automatic, via PipeWire) ----
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    // ignore the burst of property changes at startup
    Timer { interval: 1500; running: true; onTriggered: root.ready = true }

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
