import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components

// App launcher.
View {
    id: view
    required property var island

    // size the pill wants in this view
    readonly property int wantW: Config.launcherWidth
    readonly property int wantH: 70 + Math.max(1, Math.min(Apps.results.length, Config.launcherRows)) * 52 + 14
    property int openTick: 0

    // called when the launcher opens
    function shown() {
        searchInput.text = ""
        Apps.selected = 0
        openTick++
        island.vimNormal = Config.vimKeys && Config.launcherStartNormal
        Qt.callLater(() => { if (view.active) searchInput.forceActiveFocus() })
    }
    onVisibleChanged: if (visible && active) searchInput.forceActiveFocus()
    active: island.mode === "launcher"
    dims: island.sizes.launcher

    Item {
        x: 0; y: 10
        width: parent.width
        height: 48

        Icon {
            id: sIcon
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            name: "search"
            size: 24
            color: Theme.fgDim
        }
        Txt {
            anchors.left: sIcon.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: searchInput.text.length === 0
            text: Config.launcherPlaceholder
            font.pixelSize: 20
            color: Theme.fgDim
            opacity: 0.7
        }
        TextInput {
            id: searchInput
            anchors.left: sIcon.right
            anchors.leftMargin: 12
            anchors.right: Config.vimKeys ? modeBadge.left : clearBtn.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.fg
            selectionColor: Theme.primary
            selectedTextColor: Theme.primaryFg
            font.family: Theme.font
            font.pixelSize: 20
            clip: true
            focus: island.mode === "launcher"
            readOnly: Config.vimKeys && island.vimNormal
            cursorVisible: !readOnly && activeFocus
            onTextChanged: Apps.query = text

            Keys.onPressed: e => view.key(e)
        }
        // vim mode badge
        Rectangle {
            id: modeBadge
            visible: Config.vimKeys
            anchors.right: clearBtn.visible ? clearBtn.left : parent.right
            anchors.rightMargin: clearBtn.visible ? 6 : 0
            anchors.verticalCenter: parent.verticalCenter
            width: badgeTxt.implicitWidth + 16
            height: 22
            radius: 11
            color: island.vimNormal ? Theme.primary : Theme.surfaceHi
            Behavior on color { ColorAnimation { duration: 120 } }
            Txt {
                id: badgeTxt
                anchors.centerIn: parent
                text: island.vimNormal ? "NORMAL" + (island.vimCount > 0 || island.vimPending !== "" ? "  " + (island.vimCount > 0 ? island.vimCount : "") + island.vimPending : "") : "INSERT"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 0.6
                color: island.vimNormal ? Theme.primaryFg : Theme.fgDim
            }
        }
        IconButton {
            id: clearBtn
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 28; implicitHeight: 28
            visible: searchInput.text.length > 0
            name: "close"; size: 18; filled: false
            onClicked: { searchInput.text = ""; searchInput.forceActiveFocus() }
        }
    }

    Rectangle {
        x: 0; y: 62
        width: parent.width; height: 1
        color: Theme.outline
        opacity: 0.5
        visible: Apps.results.length > 0
    }

    ListView {
        id: appList
        x: 0; y: 70
        width: parent.width
        height: Math.max(1, Math.min(Apps.results.length, Config.launcherRows)) * 52
        Behavior on height { SpringAnimation { spring: 4.8; damping: 0.50; epsilon: 0.25 } }
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Apps.results
        currentIndex: Apps.selected
        highlightMoveDuration: 0
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool sel: index === Apps.selected
            readonly property int seenTick: view.openTick

            width: appList.width
            height: 52
            scale: row.sel ? 1.0 : 0.985
            Behavior on scale { SpringAnimation { spring: 8.0; damping: 0.55; epsilon: 0.002 } }

            property real enterOp: 1
            property real enterY: 0
            opacity: enterOp
            transform: Translate { y: row.enterY }

            onSeenTickChanged: {
                if (row.index < Config.launcherRows) {
                    rowAnim.stop()
                    enterOp = 0
                    enterY = 10
                    rowPause.duration = 40 + row.index * 18
                    rowAnim.restart()
                }
            }
            Component.onCompleted: {
                if (view.active && row.index < Config.launcherRows) {
                    enterOp = 0
                    enterY = 10
                    rowPause.duration = 40 + row.index * 18
                    rowAnim.restart()
                }
            }

            SequentialAnimation {
                id: rowAnim
                PauseAnimation { id: rowPause; duration: 40 }
                ParallelAnimation {
                    NumberAnimation { target: row; property: "enterOp"; to: 1; duration: 190; easing.type: Easing.OutCubic }
                    NumberAnimation { target: row; property: "enterY";  to: 0; duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 2
                anchors.bottomMargin: 2
                radius: 16
                color: row.sel ? Theme.secondaryContainer : "transparent"
                Behavior on color { ColorAnimation { duration: 110 } }
            }
            Item {
                id: appIcon
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 34; height: 34
                scale: row.sel ? 1.06 : 1.0
                Behavior on scale { SpringAnimation { spring: 7.5; damping: 0.5; epsilon: 0.002 } }
                IconImage {
                    anchors.fill: parent
                    visible: !Apps.emojiMode
                    source: Apps.emojiMode ? "" : Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                }
                Text {
                    anchors.centerIn: parent
                    visible: Apps.emojiMode
                    text: Apps.emojiMode ? row.modelData.c : ""
                    font.pixelSize: 26
                    color: Theme.fg
                    renderType: Text.QtRendering
                }
            }
            Column {
                anchors.left: appIcon.right
                anchors.leftMargin: 12
                anchors.right: hint.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                Txt { width: parent.width; text: row.modelData.name; font.pixelSize: 14; font.weight: Font.Medium }
                Txt {
                    width: parent.width
                    visible: text !== ""
                    text: Apps.emojiMode ? (row.modelData.sub || "") : (row.modelData.genericName || row.modelData.comment || "")
                    font.pixelSize: 11
                    color: Theme.fgDim
                }
            }
            Icon {
                id: hint
                anchors.right: parent.right
                anchors.rightMargin: row.sel ? 14 : 20
                anchors.verticalCenter: parent.verticalCenter
                name: Apps.emojiMode ? "content_copy" : "keyboard_return"
                size: 18
                color: Theme.fgDim
                opacity: row.sel ? 1 : 0
                Behavior on anchors.rightMargin { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: Apps.selected = row.index
                onClicked: { Apps.selected = row.index; view.launchSelected() }
            }
        }
    }

    Txt {
        x: 0; y: 70
        width: parent.width; height: 52
        horizontalAlignment: Text.AlignHCenter
        visible: Apps.results.length === 0
        text: "No results"
        font.pixelSize: 13
        color: Theme.fgDim
    }

    function launchSelected() {
        const e = Apps.results[Apps.selected]
        if (!e) return
        Apps.launch(e)
        island.closeIsland()
    }

    // ---- launcher keys (insert mode behaves like a normal search box) ----
    function key(e) {
        const ctrl = (e.modifiers & Qt.ControlModifier) !== 0
        const k = e.key
        const t = e.text

        // keys that work in both modes
        if (k === Qt.Key_Return || k === Qt.Key_Enter) { launchSelected(); e.accepted = true; return }
        if (k === Qt.Key_Down || k === Qt.Key_Tab) { Apps.move(1); e.accepted = true; return }
        if (k === Qt.Key_Up || k === Qt.Key_Backtab) { Apps.move(-1); e.accepted = true; return }
        if (ctrl && (k === Qt.Key_N || k === Qt.Key_J)) { Apps.move(1); e.accepted = true; return }
        if (ctrl && (k === Qt.Key_P || k === Qt.Key_K)) { Apps.move(-1); e.accepted = true; return }
        if (ctrl && k === Qt.Key_C) { island.closeIsland(); e.accepted = true; return }
        if (Config.vimKeys && ((k === Qt.Key_Escape && !island.vimNormal) || (ctrl && k === Qt.Key_BracketLeft))) {
            island.vimNormal = true; island.vimReset(); e.accepted = true; return
        }
        if (k === Qt.Key_Escape) { island.closeIsland(); e.accepted = true; return }

        if (!Config.vimKeys || !island.vimNormal) return    // insert mode: let TextInput type

        // ---- normal mode ----
        e.accepted = true
        const n = Math.max(1, island.vimCount)
        if (ctrl) {
            if (k === Qt.Key_D) Apps.moveBy(Math.ceil(Config.launcherRows / 2) * n)
            else if (k === Qt.Key_U) Apps.moveBy(-Math.ceil(Config.launcherRows / 2) * n)
            else if (k === Qt.Key_F) Apps.moveBy(Config.launcherRows * n)
            else if (k === Qt.Key_B) Apps.moveBy(-Config.launcherRows * n)
            island.vimReset()
            return
        }
        if (t === "") return                          // bare modifiers etc.

        if (t >= "0" && t <= "9" && !(t === "0" && island.vimCount === 0)) { island.vimCount = island.vimCount * 10 + parseInt(t); return }

        const pend = island.vimPending
        island.vimPending = ""
        switch (t) {
        case "j": Apps.moveBy(n); break
        case "k": Apps.moveBy(-n); break
        case "g":
            if (pend === "g") Apps.jump(island.vimCount > 0 ? island.vimCount - 1 : 0)
            else { island.vimPending = "g"; return }
            break
        case "G": Apps.jump(island.vimCount > 0 ? island.vimCount - 1 : Apps.results.length - 1); break
        case "d":
            if (pend === "d") searchInput.text = ""
            else { island.vimPending = "d"; return }
            break
        case "x": case "D": searchInput.text = ""; break
        case "i": case "/": island.vimNormal = false; break
        case "a": case "A": island.vimNormal = false; searchInput.cursorPosition = searchInput.text.length; break
        case "I": island.vimNormal = false; searchInput.cursorPosition = 0; break
        case "s": case "c": searchInput.text = ""; island.vimNormal = false; break
        case "l": case "o": launchSelected(); break
        case "q": island.closeIsland(); break
        }
        island.vimCount = 0
    }
}
