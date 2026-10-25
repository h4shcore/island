import Quickshell.Io
import qs.services

// qs -c island ipc call power toggle | open | close          (the menu)
// qs -c island ipc call power lock | logout | suspend | reboot | poweroff
//   the direct calls run right away, no confirmation: that is what a keybind wants
IpcHandler {
    target: "power"
    function open(): void { Ui.openRequested("power") }
    function close(): void { Ui.closeRequested() }
    function toggle(): void { Ui.toggleRequested("power") }
    function lock(): void { Power.run("lock") }
    function logout(): void { Power.run("logout") }
    function suspend(): void { Power.run("suspend") }
    function reboot(): void { Power.run("reboot") }
    function poweroff(): void { Power.run("poweroff") }
}
