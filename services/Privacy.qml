pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live privacy & recording indicator: detects active microphone capture,
// webcam use, and screen recording so the island pill can show an iOS-style
// live privacy dot.
Singleton {
    id: root

    property bool mic: false
    property bool cam: false
    property bool screen: false

    readonly property bool active: mic || cam || screen
    readonly property string icon: screen ? "fiber_manual_record" : (cam ? "videocam" : "mic")
    readonly property color color: screen ? "#EF5350" : (cam ? "#66BB6A" : "#FFA726")
    readonly property string label: {
        const parts = []
        if (screen) parts.push("Screen recording")
        if (cam) parts.push("Camera in use")
        if (mic) parts.push("Mic in use")
        return parts.join(" · ")
    }

    Process {
        id: probe
        command: [
            "sh", "-c",
            "mic=0; cam=0; scr=0; " +
            "grep -q 'state: RUNNING' /proc/asound/card*/pcm*c/sub*/status 2>/dev/null && mic=1; " +
            "ls -l /proc/[0-9]*/fd 2>/dev/null | grep -q '/dev/video' && cam=1; " +
            "pgrep -x 'wf-recorder|wl-screenrec|gpu-screen-record|kooha' >/dev/null 2>&1 && scr=1; " +
            "printf '%d,%d,%d\\n' \"$mic\" \"$cam\" \"$scr\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",")
                if (p.length >= 3) {
                    root.mic = p[0] === "1"
                    root.cam = p[1] === "1"
                    root.screen = p[2] === "1"
                }
            }
        }
    }

    function refresh() {
        if (!probe.running) probe.running = true
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }
}
