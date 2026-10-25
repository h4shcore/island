import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components

// Clipboard history.
View {
    id: view
    required property var island

    readonly property int wantW: Config.clipboardWidth
    readonly property int wantH: 70 + Math.max(1, Math.min(Clip.results.length, Config.clipboardRows)) * 52 + 14

    function shown() {
        clipInput.text = ""
        Clip.selected = 0
        Clip.refresh()
        island.vimNormal = Config.vimKeys && Config.launcherStartNormal
        Qt.callLater(() => clipInput.forceActiveFocus())
    }
    active: island.mode === "clipboard"
    dims: island.sizes.clipboard

    Item {
        x: 0; y: 10
        width: parent.width
        height: 48

        Icon {
            id: cIcon
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            name: "content_paste"
            size: 24
            color: Theme.fgDim
        }
        Txt {
            anchors.left: cIcon.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: clipInput.text.length === 0
            text: Config.clipboardPlaceholder
            font.pixelSize: 20
            color: Theme.fgDim
            opacity: 0.7
        }
        TextInput {
            id: clipInput
            anchors.left: cIcon.right
            anchors.leftMargin: 12
            anchors.right: Config.vimKeys ? clipBadge.left : clipClear.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.fg
            selectionColor: Theme.primary
            selectedTextColor: Theme.primaryFg
            font.family: Theme.font
            font.pixelSize: 20
            clip: true
            focus: island.mode === "clipboard"
            readOnly: Config.vimKeys && island.vimNormal
            cursorVisible: !readOnly && activeFocus
            onTextChanged: Clip.query = text

            Keys.onPressed: e => view.key(e)
        }
        // vim mode badge
        Rectangle {
            id: clipBadge
            visible: Config.vimKeys
            anchors.right: clipClear.visible ? clipClear.left : parent.right
            anchors.rightMargin: clipClear.visible ? 6 : 0
            anchors.verticalCenter: parent.verticalCenter
            width: clipBadgeTxt.implicitWidth + 16
            height: 22
            radius: 11
            color: island.vimNormal ? Theme.primary : Theme.surfaceHi
            Behavior on color { ColorAnimation { duration: 120 } }
            Txt {
                id: clipBadgeTxt
                anchors.centerIn: parent
                text: island.vimNormal ? "NORMAL" + (island.vimCount > 0 || island.vimPending !== "" ? "  " + (island.vimCount > 0 ? island.vimCount : "") + island.vimPending : "") : "INSERT"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 0.6
                color: island.vimNormal ? Theme.primaryFg : Theme.fgDim
            }
        }
        IconButton {
            id: clipClear
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 28; implicitHeight: 28
            visible: clipInput.text.length > 0
            name: "close"; size: 18; filled: false
            onClicked: { clipInput.text = ""; clipInput.forceActiveFocus() }
        }
    }

    Rectangle {
        x: 0; y: 62
        width: parent.width; height: 1
        color: Theme.outline
        opacity: 0.5
        visible: Clip.results.length > 0
    }

    ListView {
        id: clipList
        x: 0; y: 70
        width: parent.width
        height: Math.max(1, Math.min(Clip.results.length, Config.clipboardRows)) * 52
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Clip.results
        currentIndex: Clip.selected
        highlightMoveDuration: 0
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool sel: index === Clip.selected

            width: clipList.width
            height: 52

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 2
                anchors.bottomMargin: 2
                radius: 16
                color: row.sel ? Theme.secondaryContainer : "transparent"
                Behavior on color { ColorAnimation { duration: 90 } }
            }
            Rectangle {
                id: appIcon
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 34; height: 34; radius: 17
                color: row.sel ? Theme.primary : Theme.surfaceHi
                Behavior on color { ColorAnimation { duration: 90 } }
                Icon {
                    anchors.centerIn: parent
                    name: row.modelData.image ? "image" : "notes"
                    size: 18
                    filled: true
                    color: row.sel ? Theme.primaryFg : Theme.fgDim
                }
            }
            Column {
                anchors.left: appIcon.right
                anchors.leftMargin: 12
                anchors.right: hint.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                Txt { width: parent.width; text: row.modelData.text; font.pixelSize: 14; font.weight: Font.Medium }
                Txt {
                    width: parent.width
                    visible: text !== ""
                    text: row.modelData.sub
                    font.pixelSize: 11
                    color: Theme.fgDim
                }
            }
            Icon {
                id: hint
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                name: "content_copy"
                size: 18
                color: Theme.fgDim
                opacity: row.sel ? 1 : 0
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: Clip.selected = row.index
                onClicked: { Clip.selected = row.index; view.copySelected() }
            }
        }
    }

    Txt {
        x: 0; y: 70
        width: parent.width; height: 52
        horizontalAlignment: Text.AlignHCenter
        visible: Clip.results.length === 0
        text: Clip.query === "" ? "Clipboard is empty" : "No matches"
        font.pixelSize: 13
        color: Theme.fgDim
    }

    // ---- clipboard actions + keys ----
    function copySelected() {
        const e = Clip.results[Clip.selected]
        if (!e) return
        Clip.copy(e)
        island.closeIsland()
    }
    function key(e) {
        const ctrl = (e.modifiers & Qt.ControlModifier) !== 0
        const k = e.key
        const t = e.text

        if (k === Qt.Key_Return || k === Qt.Key_Enter) { copySelected(); e.accepted = true; return }
        if (k === Qt.Key_Down || k === Qt.Key_Tab) { Clip.move(1); e.accepted = true; return }
        if (k === Qt.Key_Up || k === Qt.Key_Backtab) { Clip.move(-1); e.accepted = true; return }
        if (ctrl && (k === Qt.Key_N || k === Qt.Key_J)) { Clip.move(1); e.accepted = true; return }
        if (ctrl && (k === Qt.Key_P || k === Qt.Key_K)) { Clip.move(-1); e.accepted = true; return }
        if (ctrl && k === Qt.Key_X) { Clip.remove(Clip.results[Clip.selected]); e.accepted = true; return }
        if (ctrl && k === Qt.Key_C) { island.closeIsland(); e.accepted = true; return }
        if (Config.vimKeys && ((k === Qt.Key_Escape && !island.vimNormal) || (ctrl && k === Qt.Key_BracketLeft))) {
            island.vimNormal = true; island.vimReset(); e.accepted = true; return
        }
        if (k === Qt.Key_Escape) { island.closeIsland(); e.accepted = true; return }

        if (!Config.vimKeys || !island.vimNormal) return

        e.accepted = true
        const n = Math.max(1, island.vimCount)
        const half = Math.ceil(Config.clipboardRows / 2)
        if (ctrl) {
            if (k === Qt.Key_D) Clip.moveBy(half * n)
            else if (k === Qt.Key_U) Clip.moveBy(-half * n)
            else if (k === Qt.Key_F) Clip.moveBy(Config.clipboardRows * n)
            else if (k === Qt.Key_B) Clip.moveBy(-Config.clipboardRows * n)
            island.vimReset()
            return
        }
        if (t === "") return
        if (t >= "0" && t <= "9" && !(t === "0" && island.vimCount === 0)) { island.vimCount = island.vimCount * 10 + parseInt(t); return }

        const pend = island.vimPending
        island.vimPending = ""
        switch (t) {
        case "j": Clip.moveBy(n); break
        case "k": Clip.moveBy(-n); break
        case "g":
            if (pend === "g") Clip.jump(island.vimCount > 0 ? island.vimCount - 1 : 0)
            else { island.vimPending = "g"; return }
            break
        case "G": Clip.jump(island.vimCount > 0 ? island.vimCount - 1 : Clip.results.length - 1); break
        case "d":
            if (pend === "d") Clip.remove(Clip.results[Clip.selected])     // dd = delete entry
            else { island.vimPending = "d"; return }
            break
        case "x": Clip.remove(Clip.results[Clip.selected]); break
        case "i": case "/": island.vimNormal = false; break
        case "a": case "A": island.vimNormal = false; clipInput.cursorPosition = clipInput.text.length; break
        case "I": island.vimNormal = false; clipInput.cursorPosition = 0; break
        case "s": case "c": clipInput.text = ""; island.vimNormal = false; break
        case "y": case "l": case "o": copySelected(); break
        case "q": island.closeIsland(); break
        }
        island.vimCount = 0
    }
}
