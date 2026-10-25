import Quickshell.Io
import qs.services

// qs -c island ipc call launcher toggle | open | close
IpcHandler {
    target: "launcher"
    function open(): void { Ui.openRequested("launcher") }
    function close(): void { Ui.closeRequested() }
    function toggle(): void { Ui.toggleRequested("launcher") }
}
