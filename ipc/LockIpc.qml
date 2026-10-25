import Quickshell.Io
import qs.services

// qs -c island ipc call lock lock      lock the session now
// qs -c island ipc call lock status    prints "locked" or "unlocked"
// (there is deliberately no unlock call: the password is the only way in)
IpcHandler {
    target: "lock"
    function lock(): void { Lock.lock() }
    function status(): string { return Lock.locked ? "locked" : "unlocked" }
}
