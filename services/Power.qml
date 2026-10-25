pragma Singleton
import QtQuick
import Quickshell
import qs.config

// Session actions behind the power menu and the `power` IPC target.
// The commands themselves come from settings.json ("power" section).
Singleton {
    id: root

    // order = order of the tiles in the menu; `key` is the hotkey inside the menu
    readonly property var actions: [
        { id: "lock",     icon: "lock",               label: "Lock",      key: "l", danger: false },
        { id: "logout",   icon: "logout",             label: "Log out",   key: "o", danger: true  },
        { id: "suspend",  icon: "bedtime",            label: "Sleep",     key: "s", danger: false },
        { id: "reboot",   icon: "restart_alt",        label: "Restart",   key: "r", danger: true  },
        { id: "poweroff", icon: "power_settings_new", label: "Shut down", key: "p", danger: true  }
    ]

    Timer {
        id: sleepTimer
        property var cmd: []
        interval: 500
        onTriggered: Quickshell.execDetached(cmd)
    }

    // detached, so the action survives the shell being torn down by it
    function run(id) {
        const cmd = Config.powerCommands[id]
        if (id === "lock") {
            if (cmd && cmd.length > 0) Quickshell.execDetached(cmd)
            else Lock.lock()                       // built-in lock screen
            return true
        }
        if (id === "suspend" && Config.lockOnSuspend && cmd && cmd.length > 0) {
            Lock.lock()
            sleepTimer.cmd = cmd                   // give the compositor a moment to show the lock first
            sleepTimer.restart()
            return true
        }
        if (!cmd || cmd.length === 0) {
            console.warn("island power: no command configured for", id)
            return false
        }
        Quickshell.execDetached(cmd)
        return true
    }
}
