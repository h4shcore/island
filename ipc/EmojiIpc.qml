import Quickshell.Io
import qs.services

// qs -c island ipc call emoji toggle | open | close | clearRecent
IpcHandler {
    target: "emoji"
    function open(): void { Ui.openRequested("emoji") }
    function close(): void { Ui.closeRequested() }
    function toggle(): void { Ui.toggleRequested("emoji") }
    function clearRecent(): void { Emoji.clearRecent() }
}
