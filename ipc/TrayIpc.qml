import Quickshell.Io
import qs.services

// qs -c island ipc call tray toggle | open | close
IpcHandler {
    target: "tray"
    function open(): void { Ui.openRequested("tray") }
    function close(): void { Ui.closeRequested() }
    function toggle(): void { Ui.toggleRequested("tray") }
}
