import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.components

// Month calendar. Keys: h/j/k/l or arrows = day/week, H/L or PgUp/PgDn = month,
// { } = year, t = today, Esc / q = close.  Mouse: click a day, wheel = month.
View {
    id: view
    required property var island

    // ---- state ----
    property var sel: mk(new Date().getFullYear(), new Date().getMonth(), new Date().getDate())
    readonly property int vy: sel.getFullYear()
    readonly property int vm: sel.getMonth()
    readonly property int selKey: key(sel)
    readonly property int todayKey: key(Clock.date)

    readonly property bool wk: Config.calendarWeekNumbers
    readonly property int wkW: wk ? 28 : 0
    readonly property int first: ((Config.calendarFirstDay % 7) + 7) % 7
    readonly property int offset: (mk(vy, vm, 1).getDay() - first + 7) % 7
    readonly property int dim: mk(vy, vm + 1, 0).getDate()
    readonly property int weeks: Math.ceil((offset + dim) / 7)

    readonly property int cellW: Math.floor((wantW - 32 - wkW) / 7)
    readonly property int cellH: 38
    readonly property int gridY: 78
    readonly property int footY: gridY + weeks * cellH + 8

    readonly property int wantW: 360
    readonly property int wantH: footY + 52 + 6

    active: island.mode === "calendar"
    dims: island.sizes.calendar

    function shown() {
        const n = new Date()
        sel = mk(n.getFullYear(), n.getMonth(), n.getDate())
        Qt.callLater(() => { if (view.active) view.forceActiveFocus() })
    }
    onVisibleChanged: if (visible && active) view.forceActiveFocus()
    Keys.onPressed: e => view.handleKey(e)

    // ---- date helpers (noon avoids DST edge cases) ----
    function mk(y, m, d) { return new Date(y, m, d, 12, 0, 0) }
    function key(d) { return d.getFullYear() * 10000 + d.getMonth() * 100 + d.getDate() }
    function addDays(d, n) { return mk(d.getFullYear(), d.getMonth(), d.getDate() + n) }
    function addMonths(d, n) {
        const t = mk(d.getFullYear(), d.getMonth() + n, 1)
        const last = mk(t.getFullYear(), t.getMonth() + 1, 0).getDate()
        return mk(t.getFullYear(), t.getMonth(), Math.min(d.getDate(), last))
    }
    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7))
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1))
        return Math.ceil(((t - y0) / 86400000 + 1) / 7)
    }
    function dayOfYear(d) {
        return Math.round((mk(d.getFullYear(), d.getMonth(), d.getDate()) - mk(d.getFullYear(), 0, 1)) / 86400000) + 1
    }
    function daysFromToday(d) {
        const t = Clock.date
        return Math.round((mk(d.getFullYear(), d.getMonth(), d.getDate()) - mk(t.getFullYear(), t.getMonth(), t.getDate())) / 86400000)
    }
    function relative(d) {
        const n = daysFromToday(d)
        if (n === 0) return "Today"
        if (n === 1) return "Tomorrow"
        if (n === -1) return "Yesterday"
        return n > 0 ? "In " + n + " days" : -n + " days ago"
    }

    function goToday() { const n = new Date(); sel = mk(n.getFullYear(), n.getMonth(), n.getDate()) }

    // ---- header ----
    Item {
        x: 0; y: 12
        width: parent.width
        height: 38

        Txt {
            id: title
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.locale().monthName(view.vm) + " " + view.vy
            font.pixelSize: 19
            font.weight: Font.DemiBold
            font.letterSpacing: -0.3
            elide: Text.ElideNone
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: view.goToday()
            }
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            IconButton {
                implicitWidth: 32; implicitHeight: 32
                name: "chevron_left"; size: 22; filled: false
                onClicked: view.sel = view.addMonths(view.sel, -1)
            }
            IconButton {
                implicitWidth: 32; implicitHeight: 32
                name: "today"; size: 18; filled: false
                color: view.selKey === view.todayKey ? Theme.primary : Theme.fg
                onClicked: view.goToday()
            }
            IconButton {
                implicitWidth: 32; implicitHeight: 32
                name: "chevron_right"; size: 22; filled: false
                onClicked: view.sel = view.addMonths(view.sel, 1)
            }
        }
    }

    // ---- weekday labels ----
    Row {
        x: view.wkW
        y: 54
        height: 20
        Repeater {
            model: 7
            delegate: Txt {
                required property int index
                width: view.cellW
                height: 20
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale().dayName((view.first + index) % 7, Locale.ShortFormat)
                font.pixelSize: 11
                font.weight: Font.Medium
                color: Theme.fgDim
            }
        }
    }

    // ---- week numbers ----
    Column {
        visible: view.wk
        x: 0
        y: view.gridY
        Repeater {
            model: view.weeks
            delegate: Txt {
                required property int index
                width: view.wkW - 4
                height: view.cellH
                horizontalAlignment: Text.AlignHCenter
                text: view.isoWeek(new Date(view.vy, view.vm, 1 - view.offset + index * 7 + 3, 12))
                font.pixelSize: 10
                color: Theme.fgDim
                opacity: 0.55
            }
        }
    }

    // ---- day grid ----
    Item {
        id: gridBox
        x: view.wkW
        y: view.gridY
        width: view.cellW * 7
        height: view.weeks * view.cellH
        Behavior on height { SpringAnimation { spring: 4.8; damping: 0.50; epsilon: 0.25 } }

        Repeater {
            model: view.weeks * 7
            delegate: Item {
                id: day
                required property int index
                readonly property var date: new Date(view.vy, view.vm, 1 - view.offset + index, 12)
                readonly property int dk: view.key(date)
                readonly property bool inMonth: date.getMonth() === view.vm
                readonly property bool isToday: dk === view.todayKey
                readonly property bool isSel: dk === view.selKey

                x: (index % 7) * view.cellW
                y: Math.floor(index / 7) * view.cellH
                width: view.cellW
                height: view.cellH

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) - 4
                    height: width
                    radius: width / 2
                    color: day.isToday ? Theme.primary : (day.isSel ? Theme.secondaryContainer : (dayMa.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08) : "transparent"))
                    border.width: day.isSel ? 2 : 0
                    border.color: day.isToday ? Theme.fg : Theme.primary
                    scale: day.isSel ? 1.06 : 1.0
                    Behavior on color { ColorAnimation { duration: 110 } }
                    Behavior on scale { SpringAnimation { spring: 8.0; damping: 0.55; epsilon: 0.002 } }
                }
                Txt {
                    anchors.centerIn: parent
                    text: day.date.getDate()
                    font.pixelSize: 13
                    font.weight: day.isToday || day.isSel ? Font.DemiBold : Font.Normal
                    color: day.isToday ? Theme.primaryFg : Theme.fg
                    opacity: day.inMonth ? 1 : 0.35
                }
                MouseArea {
                    id: dayMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: view.sel = new Date(day.date.getTime())
                }
            }
        }

        // wheel = previous / next month
        WheelHandler {
            onWheel: e => view.sel = view.addMonths(view.sel, e.angleDelta.y < 0 ? 1 : -1)
        }
    }

    // ---- footer: the selected date ----
    Item {
        x: 0
        y: view.footY
        Behavior on y { SpringAnimation { spring: 4.8; damping: 0.50; epsilon: 0.25 } }
        width: parent.width
        height: 52

        Rectangle { width: parent.width; height: 1; color: Theme.outline; opacity: 0.5 }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.right: relChip.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 2
            spacing: 1
            Txt {
                width: parent.width
                text: Qt.formatDate(view.sel, "dddd, d MMMM yyyy")
                font.pixelSize: 14
                font.weight: Font.Medium
            }
            Txt {
                width: parent.width
                text: "Week " + view.isoWeek(view.sel) + "  ·  Day " + view.dayOfYear(view.sel)
                font.pixelSize: 11
                color: Theme.fgDim
            }
        }
        Rectangle {
            id: relChip
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 2
            width: relTxt.implicitWidth + 20
            height: 26
            radius: 13
            color: view.selKey === view.todayKey ? Theme.primary : Theme.surfaceHi
            Behavior on color { ColorAnimation { duration: 120 } }
            Txt {
                id: relTxt
                anchors.centerIn: parent
                text: view.relative(view.sel)
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: view.selKey === view.todayKey ? Theme.primaryFg : Theme.fg
            }
        }
    }

    // ---- keys ----
    function handleKey(e) {
        const k = e.key
        const t = e.text
        const ctrl = (e.modifiers & Qt.ControlModifier) !== 0
        const shift = (e.modifiers & Qt.ShiftModifier) !== 0
        e.accepted = true

        if (k === Qt.Key_Escape || (ctrl && k === Qt.Key_C)) { island.closeIsland(); return }
        if (k === Qt.Key_Left)  { sel = addDays(sel, -1); return }
        if (k === Qt.Key_Right) { sel = addDays(sel, 1); return }
        if (k === Qt.Key_Up)    { sel = addDays(sel, -7); return }
        if (k === Qt.Key_Down)  { sel = addDays(sel, 7); return }
        if (k === Qt.Key_PageUp)   { sel = shift ? addMonths(sel, -12) : addMonths(sel, -1); return }
        if (k === Qt.Key_PageDown) { sel = shift ? addMonths(sel, 12) : addMonths(sel, 1); return }
        if (k === Qt.Key_Home) { goToday(); return }
        if (ctrl && (k === Qt.Key_N || k === Qt.Key_J)) { sel = addDays(sel, 7); return }
        if (ctrl && (k === Qt.Key_P || k === Qt.Key_K)) { sel = addDays(sel, -7); return }

        switch (t) {
        case "h": sel = addDays(sel, -1); break
        case "l": sel = addDays(sel, 1); break
        case "j": sel = addDays(sel, 7); break
        case "k": sel = addDays(sel, -7); break
        case "H": case "[": case "p": sel = addMonths(sel, -1); break
        case "L": case "]": case "n": sel = addMonths(sel, 1); break
        case "{": sel = addMonths(sel, -12); break
        case "}": sel = addMonths(sel, 12); break
        case "t": case "g": goToday(); break
        case "0": sel = mk(vy, vm, 1); break
        case "$": sel = mk(vy, vm + 1, 0); break
        case "q": island.closeIsland(); break
        default: e.accepted = false
        }
    }
}
