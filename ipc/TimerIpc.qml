import Quickshell.Io
import qs.services

// qs -c island ipc call timer toggle | open | close
// qs -c island ipc call timer start 25m | pause | resume | reset | add 5m | status
IpcHandler {
    target: "timer"
    function open(): void { Ui.openRequested("timer") }
    function close(): void { Ui.closeRequested() }
    function toggle(): void { Ui.toggleRequested("timer") }
    function start(duration: string): void {
        Countdown.start(duration !== "" ? duration : "25m", "")
    }
    function add(delta: string): void {
        Countdown.add(delta !== "" ? delta : "1m")
    }
    function pause(): void { Countdown.pause() }
    function resume(): void { Countdown.resume() }
    function playPause(): void { Countdown.toggle() }
    function reset(): void { Countdown.reset() }
    function status(): string {
        if (Countdown.ringing) return "ringing"
        if (!Countdown.active) return "idle"
        return (Countdown.running ? "running " : "paused ") + Countdown.formatted
    }
}
