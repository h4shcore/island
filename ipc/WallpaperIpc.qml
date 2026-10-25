import Quickshell.Io
import qs.services

// qs -c island ipc call wallpaper random | next | prev | restore | refresh
// qs -c island ipc call wallpaper set /path/to/image.jpg
// qs -c island ipc call wallpaper mode dark|light
// qs -c island ipc call wallpaper scheme tonal-spot|content|expressive|fidelity|fruit-salad|monochrome|neutral|rainbow
// qs -c island ipc call wallpaper contrast 0.4      (-1 .. 1)
// qs -c island ipc call wallpaper accent "#42A5F5"  (or: auto)
// qs -c island ipc call wallpaper current
// qs -c island ipc call wallpaper open | toggle | close      (the picker page)
IpcHandler {
    target: "wallpaper"
    function next(): void { Wallpapers.next() }
    function prev(): void { Wallpapers.prev() }
    function random(): void { Wallpapers.random() }
    function restore(): void { Wallpapers.restore() }
    function refresh(): void { Wallpapers.refresh() }
    function set(path: string): void { Wallpapers.apply(path) }
    function mode(m: string): void { Wallpapers.setMode(m) }
    function scheme(name: string): void { Wallpapers.setScheme(name === "default" ? "" : (name.startsWith("scheme-") ? name : "scheme-" + name)) }
    function contrast(v: string): void { Wallpapers.setContrast(parseFloat(v)) }
    function accent(hex: string): void { Wallpapers.setAccent(hex === "auto" ? "" : hex) }
    function current(): string { return Wallpapers.current }
    function open(): void { Ui.openRequested("walls") }
    function close(): void { Ui.closeRequested() }
    function toggle(): void { Ui.toggleRequested("walls") }
}
