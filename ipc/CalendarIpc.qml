import Quickshell.Io
import qs.services

// qs -c island ipc call calendar toggle | open | close
IpcHandler {
    target: "calendar"
    function open(): void { Ui.openRequested("calendar") }
    function close(): void { Ui.closeRequested() }
    function toggle(): void { Ui.toggleRequested("calendar") }
}
