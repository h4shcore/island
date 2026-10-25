import Quickshell.Io
import qs.services

// qs -c island ipc call clipboard toggle | open | close | wipe
IpcHandler {
    target: "clipboard"
    function open(): void { Ui.openRequested("clipboard") }
    function close(): void { Ui.closeRequested() }
    function toggle(): void { Ui.toggleRequested("clipboard") }
    function wipe(): void { Clip.wipe() }
}
