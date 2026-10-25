import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components
import "views"

// The island window: owns the state (what is showing, hover, timers) and the pill.
// Every state the pill can show lives in views/ (one file each).
PanelWindow {
    id: root

    // ---- geometry table (pill size per mode) ----
    readonly property int topGap: Config.topGap
    readonly property var sizes: ({
        idle:   { w: 132, h: 34  },
        media:  { w: 226, h: 38  },
        osd:    { w: 300, h: 48  },
        peek:   { w: 390, h: 72  },
        notif:  { w: 430, h: 84  },
        hub:    { w: 320, h: 112 },
        player: { w: 460, h: 192 },
        center: { w: 460, h: 482 },
        power:  { w: 560, h: 140 },
        // pages that size themselves
        walls:     { w: wallpaperView.wantW, h: wallpaperView.wantH },
        launcher:  { w: launcherView.wantW,  h: launcherView.wantH },
        clipboard: { w: clipboardView.wantW, h: clipboardView.wantH }
    })

    // shared cover art: ONE item that morphs between layouts
    readonly property var artGeom: ({
        media:  { s: 24, y: 7,  show: true  },
        peek:   { s: 46, y: 13, show: true  },
        notif:  { s: 48, y: 18, show: true  },
        player: { s: 72, y: 16, show: true  }
    })
    readonly property var ag: artGeom[mode] ?? ({ x: 16, s: 24, y: 7, show: false })

    // ---- window ----
    anchors.top: true
    implicitWidth: Math.max(sizes.player.w, sizes.walls.w, sizes.center.w, sizes.power.w, sizes.launcher.w, sizes.clipboard.w) + 80
    implicitHeight: topGap + Math.max(sizes.center.h, sizes.walls.h, 70 + Config.launcherRows * 52 + 14, 70 + Config.clipboardRows * 52 + 14) + 56
    color: "transparent"
    // reserve space for the idle pill only; expanded states float over windows
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: topGap + sizes.idle.h + 8
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "island"
    WlrLayershell.keyboardFocus: (root.mode === "launcher" || root.mode === "walls" || root.mode === "clipboard" || root.mode === "power") ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: pill }

    // ---- state ----
    property bool hoverRaw: false
    property bool expanded: false
    property bool osdOn: false
    property bool notifOn: false
    property bool peekOn: false
    property string page: "main"   // main | center | walls | launcher | clipboard | power
    // launcher, wallpaper, clipboard and power pages grab the keyboard and stay open until closed
    readonly property bool modal: page === "launcher" || page === "walls" || page === "clipboard" || page === "power"

    // vim state (shared by launcher / clipboard / wallpapers: only one is ever active)
    property bool vimNormal: false     // launcher only: normal vs insert mode
    property string vimPending: ""     // first key of a two-key chord (g, d)
    property int vimCount: 0           // numeric prefix, e.g. 3j
    readonly property bool overSlider: centerView.overSlider

    // scrubbing: drag only moves a local ratio; the seek is sent once, on release
    property bool scrubbing: false
    property bool holdSeek: false
    property real scrubRatio: 0
    readonly property real shownRatio: (scrubbing || holdSeek) ? scrubRatio : progress
    readonly property real trackLen: hasMedia && player.length > 0 ? player.length : 0

    readonly property var player: Media.active
    readonly property bool hasMedia: player !== null && player !== undefined
    readonly property bool mediaPlaying: hasMedia && player.isPlaying
    readonly property string title: hasMedia && player.trackTitle ? player.trackTitle : "Nothing playing"
    readonly property string artist: hasMedia && player.trackArtist ? player.trackArtist : ""
    readonly property string artUrl: hasMedia && player.trackArtUrl ? player.trackArtUrl : ""
    readonly property real progress: hasMedia && player.length > 0 ? Math.min(1, player.position / player.length) : 0

    readonly property string batteryIcon: {
        const d = UPower.displayDevice
        if (!d || !d.isPresent) return "battery_unknown"
        if (d.state === UPowerDeviceState.Charging) return "battery_charging_full"
        const p = d.percentage
        return p > 0.85 ? "battery_full" : p > 0.7 ? "battery_6_bar" : p > 0.55 ? "battery_5_bar"
             : p > 0.4 ? "battery_4_bar" : p > 0.25 ? "battery_3_bar" : p > 0.1 ? "battery_2_bar" : "battery_alert"
    }

    // battery as a pill icon (pill.batteryIcon); hidden on machines without one
    readonly property bool hasBattery: UPower.displayDevice !== null && UPower.displayDevice !== undefined && UPower.displayDevice.isPresent
    readonly property bool pillBattery: Config.pillBatteryIcon && hasBattery
    readonly property color batteryColor: {
        const d = UPower.displayDevice
        if (!d || !d.isPresent) return Theme.fg
        if (d.state === UPowerDeviceState.Charging) return Theme.primary
        return d.percentage <= 0.15 ? Theme.error : Theme.fg
    }

    // priority: notification > hover > osd > track-change peek > playing > idle
    readonly property string mode: {
        if (expanded && page === "launcher") return "launcher"
        if (expanded && page === "clipboard") return "clipboard"
        if (expanded && page === "power") return "power"
        if (notifOn) return "notif"
        if (expanded) return page === "center" ? "center" : page === "walls" ? "walls" : (hasMedia ? "player" : "hub")
        if (osdOn) return "osd"
        if (peekOn && hasMedia) return "peek"
        if (mediaPlaying) return "media"
        return "idle"
    }

    function fmt(s) {
        s = Math.max(0, Math.floor(s))
        const m = Math.floor(s / 60), r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }

    function commitSeek() {
        scrubbing = false
        if (hasMedia && player.canSeek && trackLen > 0) {
            player.position = scrubRatio * trackLen
            holdSeek = true            // keep showing the target until the player catches up
            holdTimer.restart()
        }
    }

    IdleInhibitor { window: root; enabled: Controls.keepAwake }

    onExpandedChanged: if (!expanded) page = "main"
    onModeChanged: {
        if (mode === "center") Controls.refresh()
        vimReset()
        if (mode === "launcher") launcherView.shown()
        if (mode === "clipboard") clipboardView.shown()
        if (mode === "power") powerView.shown()
        if (mode === "walls") wallpaperView.shown()
        if (mode !== "player") { scrubbing = false; holdSeek = false }
    }

    Connections { target: Osd;    function onTriggered()    { if (root.mode !== "center" && root.mode !== "walls" && root.mode !== "launcher" && root.mode !== "clipboard" && root.mode !== "power") { root.osdOn = true; osdTimer.restart() } } }
    Connections { target: Media;  function onTrackChanged() { if (!Config.mediaPeek) return; root.peekOn = true;  peekTimer.restart()  } }
    Connections {
        target: Notifs
        function onArrived() {
            root.notifOn = true
            if (root.hoverRaw) notifTimer.stop(); else notifTimer.restart()
        }
    }

    Timer { id: osdTimer;   interval: Config.osdTimeout; onTriggered: root.osdOn = false }
    Timer { id: notifTimer; interval: Config.notifTimeout; onTriggered: { root.notifOn = false; Notifs.clear() } }
    Timer { id: holdTimer;  interval: 900;  onTriggered: root.holdSeek = false }
    Timer { id: peekTimer;  interval: Config.peekTimeout; onTriggered: root.peekOn = false }
    Timer { id: enterTimer; interval: Config.hoverDelay;  onTriggered: root.expanded = true }
    Timer { id: leaveTimer; interval: Config.leaveDelay;  onTriggered: if (!root.modal) root.expanded = false }

    // ---- IPC: open / toggle / close a page ----
    Timer { id: ipcTimer; interval: Config.ipcTimeout; onTriggered: if (!root.hoverRaw) root.expanded = false }
    function openPage(p) {
        if (["main", "center", "walls", "launcher", "clipboard", "power"].indexOf(p) < 0) p = "center"
        page = p
        expanded = true
        if (modal) ipcTimer.stop(); else ipcTimer.restart()
    }
    function closeIsland() { ipcTimer.stop(); expanded = false }

    // ---- vim helpers ----
    function vimReset() { vimPending = ""; vimCount = 0 }


    Connections {
        target: Ui
        function onOpenRequested(p) { root.openPage(p) }
        function onToggleRequested(p) { if (root.expanded && root.page === p) root.closeIsland(); else root.openPage(p) }
        function onCloseRequested() { root.closeIsland() }
    }

    // MPRIS position isn't pushed; poll while the player is visible
    Timer {
        interval: 250
        repeat: true
        running: root.mode === "player" && root.mediaPlaying
        onTriggered: root.player.positionChanged()
    }

    // ======================= the island =======================
    ClippingRectangle {
        id: pill

        readonly property var dim: root.sizes[root.mode]
        readonly property bool anticipating: Config.hoverToExpand && root.hoverRaw && !root.expanded
                                             && (root.mode === "idle" || root.mode === "media")

        y: root.topGap
        anchors.horizontalCenter: parent.horizontalCenter
        width: dim.w
        height: dim.h
        radius: Math.min(height / 2, 36)
        topLeftRadius: Config.notch ? 0 : radius
        topRightRadius: Config.notch ? 0 : radius
        color: Theme.bg
        border.width: 0

        transformOrigin: Item.Top
        scale: anticipating ? 1.07 : 1.0

        // spring morph: height snappier than width, like iOS
        Behavior on width  { SpringAnimation { spring: 3.6; damping: 0.40; epsilon: 0.15 } }
        Behavior on height { SpringAnimation { spring: 4.4; damping: 0.46; epsilon: 0.15 } }
        Behavior on scale  { SpringAnimation { spring: 7.0; damping: 0.45; epsilon: 0.001 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: Config.shadow
            shadowColor: Config.shadowColor
            shadowOpacity: Config.shadowOpacity
            shadowBlur: Config.shadowBlur
            shadowVerticalOffset: Config.shadowOffset
        }

        HoverHandler {
            onHoveredChanged: {
                root.hoverRaw = hovered
                if (hovered) {
                    leaveTimer.stop(); if (Config.hoverToExpand) enterTimer.restart()
                    if (root.notifOn) notifTimer.stop()
                } else {
                    enterTimer.stop(); leaveTimer.restart()
                    if (root.notifOn) notifTimer.restart()
                }
            }
        }

        TapHandler {
            onTapped: if (root.mode === "notif") { root.notifOn = false; Notifs.clear() }
        }

        // scroll down = control center, scroll up = back (wallpaper page scrolls its own list)
        WheelHandler {
            onWheel: e => { if (root.expanded && !root.notifOn && !root.modal && !(root.mode === "center" && root.overSlider)) root.page = e.angleDelta.y < 0 ? "center" : "main" }
        }

        // ===== views (one file each in views/) =====
        IdleView      { id: idleView;      island: root }
        MediaView     { id: mediaView;     island: root }
        PeekView      { id: peekView;      island: root }
        OsdView       { id: osdView;       island: root }
        NotifView     { id: notifView;     island: root }
        HubView       { id: hubView;       island: root }
        PlayerView    { id: playerView;    island: root }
        CenterView    { id: centerView;    island: root }
        WallpaperView { id: wallpaperView; island: root }
        LauncherView  { id: launcherView;  island: root }
        ClipboardView { id: clipboardView; island: root }
        PowerView     { id: powerView;     island: root }

        // ===== shared cover art (morphs between all layouts) =====
        Art {
            id: cover
            x: root.ag.x ?? 16
            y: root.ag.y
            width: root.ag.s
            height: root.ag.s
            radius: Math.round(width * 0.3)
            opacity: root.ag.show ? 1 : 0
            source: root.mode === "notif" ? Notifs.image : root.artUrl
            fallback: root.mode === "notif" ? "notifications" : "music_note"

            Behavior on x      { SpringAnimation { spring: 4.2; damping: 0.45; epsilon: 0.1 } }
            Behavior on y      { SpringAnimation { spring: 4.2; damping: 0.45; epsilon: 0.1 } }
            Behavior on width  { SpringAnimation { spring: 4.2; damping: 0.45; epsilon: 0.1 } }
            Behavior on height { SpringAnimation { spring: 4.2; damping: 0.45; epsilon: 0.1 } }
            Behavior on opacity { NumberAnimation { duration: root.ag.show ? 260 : 110; easing.type: Easing.OutCubic } }
        }
    }
}
