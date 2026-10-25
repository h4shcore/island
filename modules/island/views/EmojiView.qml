import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.components

// Emoji + symbol picker: search box, category tabs, grid, preview line.
View {
    id: view
    required property var island

    readonly property int cols: Config.emojiColumns
    readonly property int cellW: Math.floor((wantW - 32) / cols)
    readonly property int gridRows: Math.max(1, Math.min(Math.ceil(Emoji.results.length / cols), Config.emojiRows))
    readonly property int gridY: 108

    readonly property int wantW: Config.emojiWidth
    readonly property int wantH: gridY + gridRows * cellW + 52
    property int openTick: 0

    function shown() {
        emojiInput.text = ""
        Emoji.open()
        openTick++
        island.vimNormal = Config.vimKeys && Config.launcherStartNormal
        Qt.callLater(() => { if (view.active) emojiInput.forceActiveFocus() })
    }
    onVisibleChanged: if (visible && active) emojiInput.forceActiveFocus()
    active: island.mode === "emoji"
    dims: island.sizes.emoji

    // ---- search row ----
    Item {
        x: 0; y: 10
        width: parent.width
        height: 48

        Icon {
            id: eIcon
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            name: "emoji_emotions"
            size: 24
            color: Theme.fgDim
        }
        Txt {
            anchors.left: eIcon.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: emojiInput.text.length === 0
            text: Config.emojiPlaceholder
            font.pixelSize: 20
            color: Theme.fgDim
            opacity: 0.7
        }
        TextInput {
            id: emojiInput
            anchors.left: eIcon.right
            anchors.leftMargin: 12
            anchors.right: Config.vimKeys ? eBadge.left : eClear.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.fg
            selectionColor: Theme.primary
            selectedTextColor: Theme.primaryFg
            font.family: Theme.font
            font.pixelSize: 20
            clip: true
            focus: island.mode === "emoji"
            readOnly: Config.vimKeys && island.vimNormal
            cursorVisible: !readOnly && activeFocus
            onTextChanged: Emoji.query = text

            Keys.onPressed: e => view.key(e)
        }
        Rectangle {
            id: eBadge
            visible: Config.vimKeys
            anchors.right: eClear.visible ? eClear.left : parent.right
            anchors.rightMargin: eClear.visible ? 6 : 0
            anchors.verticalCenter: parent.verticalCenter
            width: eBadgeTxt.implicitWidth + 16
            height: 22
            radius: 11
            color: island.vimNormal ? Theme.primary : Theme.surfaceHi
            Behavior on color { ColorAnimation { duration: 120 } }
            Txt {
                id: eBadgeTxt
                anchors.centerIn: parent
                text: island.vimNormal ? "NORMAL" + (island.vimCount > 0 || island.vimPending !== "" ? "  " + (island.vimCount > 0 ? island.vimCount : "") + island.vimPending : "") : "INSERT"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 0.6
                color: island.vimNormal ? Theme.primaryFg : Theme.fgDim
            }
        }
        IconButton {
            id: eClear
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 28; implicitHeight: 28
            visible: emojiInput.text.length > 0
            name: "close"; size: 18; filled: false
            onClicked: { emojiInput.text = ""; emojiInput.forceActiveFocus() }
        }
    }

    Rectangle {
        x: 0; y: 62
        width: parent.width; height: 1
        color: Theme.outline
        opacity: 0.5
    }

    // ---- category tabs ----
    Row {
        id: tabs
        x: (parent.width - width) / 2
        y: 69
        height: 32
        spacing: 2
        opacity: emojiInput.text.length > 0 ? 0.35 : 1
        Behavior on opacity { NumberAnimation { duration: 140 } }

        Repeater {
            model: Emoji.categories
            delegate: Item {
                id: tab
                required property var modelData
                readonly property bool on: Emoji.category === modelData.id && emojiInput.text.length === 0
                width: 32; height: 32

                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: tab.on ? Theme.secondaryContainer : (tabMa.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.10) : "transparent")
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
                Icon {
                    anchors.centerIn: parent
                    name: tab.modelData.icon
                    size: 19
                    filled: tab.on
                    color: tab.on ? Theme.primary : Theme.fgDim
                }
                MouseArea {
                    id: tabMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        emojiInput.text = ""
                        Emoji.category = tab.modelData.id
                        emojiInput.forceActiveFocus()
                    }
                }
            }
        }
    }

    // ---- grid ----
    GridView {
        id: grid
        x: (parent.width - width) / 2
        y: view.gridY
        width: view.cols * view.cellW
        height: view.gridRows * view.cellW
        Behavior on height { SpringAnimation { spring: 4.8; damping: 0.50; epsilon: 0.25 } }
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        cellWidth: view.cellW
        cellHeight: view.cellW
        model: Emoji.results
        currentIndex: Emoji.selected
        highlightMoveDuration: 0
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
        visible: Emoji.results.length > 0

        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            readonly property bool sel: index === Emoji.selected
            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 14
                color: cell.sel ? Theme.secondaryContainer : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }
            }
            Text {
                anchors.centerIn: parent
                text: cell.modelData.c
                font.pixelSize: Math.round(view.cellW * 0.5)
                color: Theme.fg
                renderType: Text.QtRendering
                scale: cell.sel ? 1.18 : 1.0
                Behavior on scale { SpringAnimation { spring: 8.0; damping: 0.5; epsilon: 0.002 } }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: Emoji.selected = cell.index
                onClicked: { Emoji.selected = cell.index; view.pickSelected() }
            }
        }
    }

    Txt {
        x: 0; y: view.gridY
        width: parent.width; height: view.cellW
        horizontalAlignment: Text.AlignHCenter
        visible: Emoji.results.length === 0
        text: Emoji.query !== "" ? "No matches" : (Emoji.category === "recent" ? "Nothing used yet" : "Empty")
        font.pixelSize: 13
        color: Theme.fgDim
    }

    // ---- preview line ----
    Item {
        x: 0
        y: view.gridY + view.gridRows * view.cellW + 6
        Behavior on y { SpringAnimation { spring: 4.8; damping: 0.50; epsilon: 0.25 } }
        width: parent.width
        height: 36

        Rectangle { width: parent.width; height: 1; color: Theme.outline; opacity: 0.5 }

        Text {
            id: bigChar
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 2
            text: Emoji.current ? Emoji.current.c : ""
            font.pixelSize: 24
            color: Theme.fg
            renderType: Text.QtRendering
        }
        Txt {
            anchors.left: bigChar.right
            anchors.leftMargin: 12
            anchors.right: hintRow.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 2
            text: Emoji.current ? Emoji.current.name : ""
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        Row {
            id: hintRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 2
            spacing: 6
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                visible: Emoji.query === ""
                text: {
                    for (const c of Emoji.categories) if (c.id === Emoji.category) return c.label
                    return ""
                }
                font.pixelSize: 11
                color: Theme.fgDim
            }
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: Config.emojiTypeAfterCopy ? "keyboard" : "content_copy"
                size: 16
                color: Theme.fgDim
            }
        }
    }

    // ---- actions + keys ----
    function pickSelected() {
        const e = Emoji.current
        if (!e) return
        Emoji.pick(e)
        island.closeIsland()
    }
    function key(e) {
        const ctrl = (e.modifiers & Qt.ControlModifier) !== 0
        const k = e.key
        const t = e.text
        const c = view.cols

        if (k === Qt.Key_Return || k === Qt.Key_Enter) { pickSelected(); e.accepted = true; return }
        if (k === Qt.Key_Right) { Emoji.moveBy(1); e.accepted = true; return }
        if (k === Qt.Key_Left)  { Emoji.moveBy(-1); e.accepted = true; return }
        if (k === Qt.Key_Down)  { Emoji.moveBy(c); e.accepted = true; return }
        if (k === Qt.Key_Up)    { Emoji.moveBy(-c); e.accepted = true; return }
        if (k === Qt.Key_Tab)     { emojiInput.text = ""; Emoji.cycleCategory(1); e.accepted = true; return }
        if (k === Qt.Key_Backtab) { emojiInput.text = ""; Emoji.cycleCategory(-1); e.accepted = true; return }
        if (ctrl && (k === Qt.Key_N || k === Qt.Key_J)) { Emoji.moveBy(c); e.accepted = true; return }
        if (ctrl && (k === Qt.Key_P || k === Qt.Key_K)) { Emoji.moveBy(-c); e.accepted = true; return }
        if (ctrl && k === Qt.Key_X) { if (Emoji.category === "recent") Emoji.clearRecent(); e.accepted = true; return }
        if (ctrl && k === Qt.Key_C) { island.closeIsland(); e.accepted = true; return }
        if (Config.vimKeys && ((k === Qt.Key_Escape && !island.vimNormal) || (ctrl && k === Qt.Key_BracketLeft))) {
            island.vimNormal = true; island.vimReset(); e.accepted = true; return
        }
        if (k === Qt.Key_Escape) { island.closeIsland(); e.accepted = true; return }

        if (!Config.vimKeys || !island.vimNormal) return

        e.accepted = true
        const n = Math.max(1, island.vimCount)
        const half = Math.ceil(Config.emojiRows / 2) * c
        if (ctrl) {
            if (k === Qt.Key_D) Emoji.moveBy(half * n)
            else if (k === Qt.Key_U) Emoji.moveBy(-half * n)
            else if (k === Qt.Key_F) Emoji.moveBy(Config.emojiRows * c * n)
            else if (k === Qt.Key_B) Emoji.moveBy(-Config.emojiRows * c * n)
            island.vimReset()
            return
        }
        if (t === "") return
        if (t >= "0" && t <= "9" && !(t === "0" && island.vimCount === 0)) { island.vimCount = island.vimCount * 10 + parseInt(t); return }

        const pend = island.vimPending
        island.vimPending = ""
        switch (t) {
        case "h": Emoji.moveBy(-n); break
        case "l": Emoji.moveBy(n); break
        case "j": Emoji.moveBy(c * n); break
        case "k": Emoji.moveBy(-c * n); break
        case "H": emojiInput.text = ""; Emoji.cycleCategory(-1); break
        case "L": emojiInput.text = ""; Emoji.cycleCategory(1); break
        case "0": Emoji.jump(Math.floor(Emoji.selected / c) * c); break
        case "$": Emoji.jump(Math.floor(Emoji.selected / c) * c + c - 1); break
        case "g":
            if (pend === "g") Emoji.jump(island.vimCount > 0 ? island.vimCount - 1 : 0)
            else { island.vimPending = "g"; return }
            break
        case "G": Emoji.jump(island.vimCount > 0 ? island.vimCount - 1 : Emoji.results.length - 1); break
        case "i": case "/": island.vimNormal = false; break
        case "a": case "A": island.vimNormal = false; emojiInput.cursorPosition = emojiInput.text.length; break
        case "I": island.vimNormal = false; emojiInput.cursorPosition = 0; break
        case "s": case "c": emojiInput.text = ""; island.vimNormal = false; break
        case "y": case "o": pickSelected(); break
        case "q": island.closeIsland(); break
        }
        island.vimCount = 0
    }
}
