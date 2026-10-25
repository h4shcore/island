import Quickshell.Io
import qs.services

// qs -c island ipc call center toggle | open | close
IpcHandler {
    target: "center"
    function open(): void { Ui.openRequested("center") }
    function close(): void { Ui.closeRequested() }
    function toggle(): void { Ui.toggleRequested("center") }
}
