import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

// Live timer & Pomodoro page: big tabular countdown, progress bar, preset chips,
// and quick +1m / +5m / play-pause / reset controls.
View {
    id: view
    required property var island

    pad: 18
    active: island.mode === "timer"
    dims: island.sizes.timer

    function shown() {
        Qt.callLater(() => { if (view.active) timerKeys.forceActiveFocus() })
    }
    onVisibleChanged: if (visible && active) timerKeys.forceActiveFocus()

    Item {
        id: timerKeys
        focus: island.mode === "timer"
        Keys.onPressed: e => view.key(e)
    }

    function key(e) {
        const k = e.key
        const t = e.text
        const ctrl = (e.modifiers & Qt.ControlModifier) !== 0
        e.accepted = true

        if (k === Qt.Key_Escape || t === "q" || (ctrl && k === Qt.Key_C)) {
            if (Countdown.ringing) Countdown.dismiss()
            island.closeIsland()
            return
        }
        if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
            Countdown.toggle()
            return
        }
        if (k === Qt.Key_Backspace) {
            island.page = "center"
            return
        }
        switch (t) {
        case "r": case "x": Countdown.reset(); break
        case "+": case "=": Countdown.add(60); break
        case "-": Countdown.add(-60); break
        case "1": Countdown.start(60, "Timer"); break
        case "2": Countdown.start(300, "Timer"); break
        case "3": Countdown.start(600, "Timer"); break
        case "4": Countdown.start(1500, "Pomodoro"); break
        case "5": Countdown.start(2700, "Focus"); break
        default: e.accepted = false; break
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        spacing: 10

        // ---- top row: status badge + countdown + play/reset/close ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 46
                Layout.preferredHeight: 46
                radius: 23
                color: Countdown.ringing ? Theme.error : (Countdown.running ? Theme.primary : Theme.card)
                Behavior on color { ColorAnimation { duration: 160 } }

                Icon {
                    anchors.centerIn: parent
                    name: Countdown.ringing ? "notifications_active" : "timer"
                    size: 24
                    filled: Countdown.running || Countdown.ringing
                    color: Countdown.ringing ? Theme.bg : (Countdown.running ? Theme.primaryFg : Theme.fg)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Txt {
                    text: Countdown.ringing ? "Time's up!" : (Countdown.active ? (Countdown.running ? Countdown.label : Countdown.label + " · Paused") : "Set a timer")
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Countdown.ringing ? Theme.error : Theme.fgDim
                }
                Txt {
                    text: Countdown.active ? Countdown.formatted : "25:00"
                    font.pixelSize: 34
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.8
                    color: Countdown.ringing ? Theme.error : Theme.fg
                    opacity: Countdown.active ? 1.0 : 0.45
                }
            }

            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                IconButton {
                    implicitWidth: 38; implicitHeight: 38
                    name: Countdown.ringing ? "check" : (Countdown.running ? "pause" : "play_arrow")
                    size: 22
                    filled: true
                    fill: Countdown.ringing ? Theme.error : Theme.primary
                    color: Countdown.ringing ? Theme.bg : Theme.primaryFg
                    onClicked: Countdown.toggle()
                }
                IconButton {
                    implicitWidth: 38; implicitHeight: 38
                    visible: Countdown.active
                    name: "restart_alt"
                    size: 20
                    filled: false
                    fill: Theme.card
                    onClicked: Countdown.reset()
                }
                IconButton {
                    implicitWidth: 38; implicitHeight: 38
                    name: "close"
                    size: 19
                    filled: false
                    onClicked: {
                        if (Countdown.ringing) Countdown.dismiss()
                        island.closeIsland()
                    }
                }
            }
        }

        // ---- progress bar ----
        Rectangle {
            id: track
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: 3
            color: Theme.secondaryContainer

            Rectangle {
                height: parent.height
                radius: parent.radius
                width: Countdown.ringing ? track.width : (Countdown.active ? Math.max(height, track.width * Countdown.progress) : 0)
                color: Countdown.ringing ? Theme.error : Theme.primary
                Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 160 } }
            }
        }

        // ---- preset & quick-add chips ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: Countdown.presets
                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool sel: Countdown.active && Countdown.total === modelData.secs
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    radius: 15
                    color: chip.sel ? Theme.primary : (chipMa.containsMouse ? Theme.cardHi : Theme.card)
                    scale: chipMa.pressed ? 0.94 : 1.0
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on scale { SpringAnimation { spring: 8; damping: 0.5; epsilon: 0.002 } }

                    Txt {
                        anchors.centerIn: parent
                        text: chip.modelData.label
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: chip.sel ? Theme.primaryFg : Theme.fg
                    }
                    MouseArea {
                        id: chipMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Countdown.start(chip.modelData.secs, chip.modelData.secs === 1500 ? "Pomodoro" : "Timer")
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 46
                Layout.preferredHeight: 30
                radius: 15
                color: addMa.containsMouse ? Theme.cardHi : Theme.card
                scale: addMa.pressed ? 0.94 : 1.0
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on scale { SpringAnimation { spring: 8; damping: 0.5; epsilon: 0.002 } }

                Txt {
                    anchors.centerIn: parent
                    text: "+1m"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.primary
                }
                MouseArea {
                    id: addMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Countdown.add(60)
                }
            }
        }
    }
}
