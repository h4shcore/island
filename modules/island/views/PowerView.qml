import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components

// Power menu: Lock, Log out, Sleep, Restart, Shut down.
//   mouse   click a tile
//   keys    ← → / Tab to move, Enter / Space to run, l o s r p to jump, Esc / q to close
// Log out / Restart / Shut down ask twice (power.confirm): the tile turns into "Confirm".
View {
    id: view
    required property var island

    property int sel: 0
    property string armed: ""          // id of the tile waiting for its second press

    // called when the menu opens
    function shown() {
        sel = 0
        armed = ""
        armTimer.stop()
        Qt.callLater(() => powerKeys.forceActiveFocus())
        focusRetry.restart()
    }
    pad: 24
    active: island.mode === "power"
    dims: island.sizes.power

    onSelChanged: if (armed !== "" && Power.actions[sel].id !== armed) { armed = ""; armTimer.stop() }

    function activate(i) {
        const a = Power.actions[i]
        if (!a) return
        sel = i
        if (a.danger && Config.powerConfirm && armed !== a.id) {
            armed = a.id
            armTimer.restart()
            return
        }
        armTimer.stop()
        armed = ""
        island.closeIsland()
        Power.run(a.id)
    }

    function move(d) {
        const n = Power.actions.length
        sel = (sel + d + n) % n
    }

    function key(e) {
        const k = e.key
        const ctrl = (e.modifiers & Qt.ControlModifier) !== 0
        e.accepted = true
        if (k === Qt.Key_Escape || k === Qt.Key_Q || (ctrl && k === Qt.Key_C)) { island.closeIsland(); return }
        if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) { activate(sel); return }
        if (k === Qt.Key_Right || k === Qt.Key_Tab) { move(1); return }
        if (k === Qt.Key_Left || k === Qt.Key_Backtab) { move(-1); return }
        const t = e.text.toLowerCase()
        if (t !== "" && !ctrl) {
            for (let i = 0; i < Power.actions.length; i++) {
                if (Power.actions[i].key === t) { activate(i); return }
            }
        }
        e.accepted = false
    }

    // the confirm state times out on its own
    Timer { id: armTimer; interval: 3000; onTriggered: view.armed = "" }
    // the page fades in a beat after the mode flips; grab focus again once it is visible
    Timer { id: focusRetry; interval: 130; onTriggered: if (view.active) powerKeys.forceActiveFocus() }

    // key sink: the whole page is driven from here
    Item {
        id: powerKeys
        focus: island.mode === "power"
        Keys.onPressed: e => view.key(e)
    }

    Row {
        x: 0
        y: Math.round((view.height - 88) / 2)
        spacing: 18
        Repeater {
            model: Power.actions
            delegate: Item {
                id: tile
                required property var modelData
                required property int index
                readonly property bool isSel: index === view.sel
                readonly property bool isArmed: modelData.id === view.armed

                width: 88; height: 88          // every tile is the same square

                Rectangle {
                    anchors.fill: parent
                    radius: 32
                    color: tile.isArmed ? Theme.error : (ma.containsMouse || tile.isSel ? Theme.cardHi : Theme.card)
                    border.width: tile.isSel ? 2 : 0
                    border.color: tile.isArmed ? Theme.error : Theme.primary
                    scale: ma.pressed ? 0.94 : (tile.isSel ? 1.05 : 1.0)
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on scale { SpringAnimation { spring: 8; damping: 0.5; epsilon: 0.002 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 9
                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: tile.isArmed ? "check" : tile.modelData.icon
                            size: 30
                            weight: 400
                            color: tile.isArmed ? Theme.bg : Theme.fg
                        }
                        Txt {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: tile.width - 12
                            horizontalAlignment: Text.AlignHCenter
                            text: tile.isArmed ? "Confirm" : tile.modelData.label
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: tile.isArmed ? Theme.bg : Theme.fg
                        }
                    }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: view.sel = tile.index
                    onClicked: view.activate(tile.index)
                }
            }
        }
    }
}
