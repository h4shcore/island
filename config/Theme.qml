pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Colors hot-reload from ~/.config/quickshell/colors.json (matugen output).
// The defaults below (Material 3 baseline dark) are used until that file exists.
Singleton {
    id: root

    readonly property color surface: ad.surface
    readonly property color surfaceHi: ad.surfaceHi
    readonly property color surfaceHiest: ad.surfaceHiest
    readonly property color fg: ad.fg
    readonly property color fgDim: ad.fgDim
    readonly property color primary: ad.primary
    readonly property color primaryFg: ad.primaryFg
    readonly property color secondaryContainer: ad.secondaryContainer
    readonly property color error: ad.error
    readonly property color outline: ad.outline

    readonly property string font: Config.font
    readonly property string iconFont: Config.iconFont

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        adapter: JsonAdapter {
            id: ad
            property string surface: "#141218"
            property string surfaceHi: "#2b2930"
            property string surfaceHiest: "#36343b"
            property string fg: "#e6e0e9"
            property string fgDim: "#cac4d0"
            property string primary: "#d0bcff"
            property string primaryFg: "#381e72"
            property string secondaryContainer: "#4a4458"
            property string error: "#f2b8b5"
            property string outline: "#49454f"
        }
    }
}
