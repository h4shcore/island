pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// ============================================================================
//  island settings live in settings.json (next to shell.qml).
//  Save the file and the shell updates live, no restart needed.
//  Point ISLAND_SETTINGS at another file to use a different location.
//  Every key is optional: anything missing falls back to the default below.
// ============================================================================
Singleton {
    id: root

    // ---- look ----
    readonly property string font: ad.look.font
    readonly property string iconFont: ad.look.iconFont
    readonly property int topGap: ad.look.topGap
    readonly property bool shadow: ad.look.shadow
    readonly property bool sheen: ad.look.sheen
    readonly property bool sliderAccent: ad.look.sliderAccent        // true = matugen primary, false = neutral

    // ---- clock (Qt format strings) ----
    readonly property string timeFormat: ad.clock.timeFormat          // "h:mm AP" for 12 hour
    readonly property string dateFormat: ad.clock.dateFormat
    readonly property string shortDateFormat: ad.clock.shortDateFormat // compact date on the hover player

    // ---- pill (the small resting island) ----
    readonly property bool pillClockWithMedia: ad.pill.clockWithMedia  // keep the clock visible while media plays
    readonly property bool pillBatteryIcon: ad.pill.batteryIcon        // battery as an icon only (no number), skipped when there is no battery

    // ---- behaviour ----
    readonly property bool hoverToExpand: ad.behavior.hoverToExpand   // false = only open through IPC / the launcher
    readonly property int hoverDelay: ad.behavior.hoverDelay
    readonly property int leaveDelay: ad.behavior.leaveDelay
    readonly property bool mediaPeek: ad.behavior.mediaPeek
    readonly property int osdTimeout: ad.behavior.osdTimeout
    readonly property int notifTimeout: ad.behavior.notifTimeout
    readonly property int peekTimeout: ad.behavior.peekTimeout
    readonly property int ipcTimeout: ad.behavior.ipcTimeout

    // ---- control center ----
    readonly property bool showBattery: ad.controlCenter.showBattery

    // ---- power menu ----
    readonly property bool powerConfirm: ad.power.confirm              // ask twice before log out / restart / shut down
    readonly property var powerCommands: ({
        lock: ad.power.lock,
        logout: ad.power.logout,
        suspend: ad.power.suspend,
        reboot: ad.power.reboot,
        poweroff: ad.power.poweroff
    })

    // ---- wallpapers ----
    // "~" is expanded; the ISLAND_WALLPAPERS env var wins over the file.
    readonly property string wallpaperDir: Quickshell.env("ISLAND_WALLPAPERS") || expand(ad.wallpapers.dir)
    // "%f" is replaced by the image path (awww needs `awww-daemon` running).
    //   awww:         ["awww", "img", "--transition-type", "fade", "%f"]
    //   swaybg:       ["sh", "-c", "pkill swaybg; swaybg -m fill -i \"$1\" &", "sh", "%f"]
    readonly property var wallpaperSetter: ad.wallpapers.setter
    readonly property string matugenMode: ad.wallpapers.matugenMode  // dark | light
    readonly property string matugenScheme: ad.wallpapers.matugenScheme // e.g. "scheme-tonal-spot"; empty = default
    readonly property real matugenContrast: ad.wallpapers.matugenContrast // -1 .. 1, the UI can change it live
    readonly property var accentPresets: ad.wallpapers.accentPresets  // swatches in the switcher's colour panel
    readonly property int wallpaperWidth: ad.wallpapers.width
    readonly property bool wallpaperLoop: ad.wallpapers.loop          // wrap around at both ends
    readonly property int wallpaperCardWidth: ad.wallpapers.cardWidth // thumbnail width (height follows 16:10)

    // ---- launcher ----
    readonly property int launcherWidth: ad.launcher.width
    readonly property int launcherRows: ad.launcher.rows
    readonly property int launcherMaxResults: ad.launcher.maxResults
    readonly property string launcherPlaceholder: ad.launcher.placeholder
    // prefix for apps that need a terminal (Terminal=true)
    //   kitty / foot: ["kitty"]   alacritty: ["alacritty", "-e"]   wezterm: ["wezterm", "start", "--"]
    readonly property var terminal: ad.launcher.terminal

    // ---- clipboard (cliphist) ----
    readonly property int clipboardWidth: ad.clipboard.width
    readonly property int clipboardRows: ad.clipboard.rows
    readonly property int clipboardMaxItems: ad.clipboard.maxItems
    readonly property string clipboardPlaceholder: ad.clipboard.placeholder
    readonly property bool clipboardWatch: ad.clipboard.watch         // run wl-paste --watch cliphist store for you

    // ---- keyboard ----
    readonly property bool vimKeys: ad.keys.vim                       // vim binds in launcher + wallpaper switcher
    readonly property bool launcherStartNormal: ad.keys.launcherStartNormal // false = open in insert mode

    function expand(p) {
        if (!p) return ""
        return p === "~" || p.startsWith("~/") ? Quickshell.env("HOME") + p.slice(1) : p
    }

    FileView {
        path: Quickshell.env("ISLAND_SETTINGS") || Quickshell.shellPath("settings.json")
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        adapter: JsonAdapter {
            id: ad

            property JsonObject look: JsonObject {
                property string font: "Inter"
                property string iconFont: "Material Symbols Rounded"
                property int topGap: 10
                property bool shadow: true
                property bool sheen: true
                property bool sliderAccent: true
            }
            property JsonObject clock: JsonObject {
                property string timeFormat: "HH:mm"
                property string dateFormat: "dddd, d MMMM"
                property string shortDateFormat: "ddd, d MMM"
            }
            property JsonObject pill: JsonObject {
                property bool clockWithMedia: true
                property bool batteryIcon: true
            }
            property JsonObject behavior: JsonObject {
                property bool hoverToExpand: true
                property int hoverDelay: 110
                property int leaveDelay: 300
                property bool mediaPeek: true
                property int osdTimeout: 1700
                property int notifTimeout: 5200
                property int peekTimeout: 3200
                property int ipcTimeout: 6000
            }
            property JsonObject controlCenter: JsonObject {
                property bool showBattery: true
            }
            property JsonObject power: JsonObject {
                property bool confirm: true
                property var lock: ["loginctl", "lock-session"]
                property var logout: ["sh", "-c", "niri msg action quit --skip-confirmation || hyprctl dispatch exit || swaymsg exit || loginctl terminate-user $USER"]
                property var suspend: ["systemctl", "suspend"]
                property var reboot: ["systemctl", "reboot"]
                property var poweroff: ["systemctl", "poweroff"]
            }
            property JsonObject wallpapers: JsonObject {
                property string dir: "~/Pictures/Wallpapers"
                property var setter: ["awww", "img", "--transition-type", "fade", "--transition-duration", "1", "%f"]
                property string matugenMode: "dark"
                property string matugenScheme: ""
                property real matugenContrast: 0
                property var accentPresets: ["#EF5350", "#FF8A65", "#FFCA28", "#9CCC65", "#26A69A", "#42A5F5", "#7E57C2", "#EC407A"]
                property int width: 700
                property int cardWidth: 200
                property bool loop: true
            }
            property JsonObject launcher: JsonObject {
                property int width: 560
                property int rows: 6
                property int maxResults: 40
                property string placeholder: "Search apps"
                property var terminal: ["kitty"]
            }
            property JsonObject clipboard: JsonObject {
                property int width: 560
                property int rows: 6
                property int maxItems: 100
                property string placeholder: "Search clipboard"
                property bool watch: false
            }
            property JsonObject keys: JsonObject {
                property bool vim: true
                property bool launcherStartNormal: false
            }
        }
    }
}
