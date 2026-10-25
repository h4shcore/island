pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pam
import qs.config

// Session lock state + password check (PAM). The lock surfaces themselves live in
// modules/lock and are created by shell.qml while `locked` is true.
Singleton {
    id: root

    property bool locked: false
    property string typed: ""        // mirrored between screens so every monitor shows the same dots
    property string error: ""
    property bool busy: false
    property int failures: 0
    property bool leaving: false     // password accepted, the lock screen is animating out
    signal failed()

    property string _pw: ""

    function lock() {
        if (locked) return
        typed = ""
        error = ""
        failures = 0
        leaving = false
        locked = true
    }

    function attempt(pw) {
        if (busy || pw === "") return
        _pw = pw
        error = ""
        busy = true
        pam.start()
    }

    Timer {
        id: leaveTimer
        interval: 380
        onTriggered: { root.locked = false; root.leaving = false; root.typed = "" }
    }

    PamContext {
        id: pam
        config: Config.lockPam
        onPamMessage: { if (responseRequired) respond(root._pw) }
        onCompleted: result => {
            root.busy = false
            root._pw = ""
            if (result === PamResult.Success) {
                root.error = ""
                root.leaving = true
                leaveTimer.restart()
            } else {
                root.failures++
                root.error = result === PamResult.MaxTries ? "Too many attempts" : "Wrong password"
                root.typed = ""
                root.failed()
            }
        }
        onError: err => {
            root.busy = false
            root._pw = ""
            root.typed = ""
            root.error = "Authentication error"
            root.failed()
        }
    }
}
