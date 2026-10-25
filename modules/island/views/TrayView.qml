import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.config
import qs.services
import qs.components

// System tray (StatusNotifier). Left click activates, right click opens the item's
// menu inside the island, middle click = secondary action.
View {
    id: view
    required property var island

    // ---- state ----
    property var stack: []                 // open menu handles; empty = icon grid
    property var owner: null               // tray item whose menu is showing
    property var hovered: null
    readonly property bool inMenu: stack.length > 0
    readonly property var topMenu: inMenu ? stack[stack.length - 1] : null
    property string menuTitle: ""
    property var titles: []                // title stack, parallel to `stack`

    readonly property var list: SystemTray.items.values.filter(i => !Config.trayHidePassive || i.status !== Status.Passive)
    readonly property int cols: Math.max(2, Config.trayColumns)
    readonly property int cell: 52
    readonly property int gridRows: Math.max(1, Math.min(Math.ceil(list.length / cols), 4))

    readonly property var entries: opener.children ? opener.children.values : []
    readonly property int menuListH: Math.min(entries.reduce((a, en) => a + (en.isSeparator ? 9 : 36), 0), 9 * 36)

    readonly property int wantW: Math.max(300, cols * cell + 32)
    readonly property int wantH: inMenu ? 56 + Math.max(menuListH, 36) + 12 : 12 + gridRows * 56 + 40

    active: island.mode === "tray"
    dims: island.sizes.tray

    function shown() { stack = []; titles = []; owner = null; hovered = null }

    function itemTitle(it) { return it.tooltipTitle || it.title || it.id }

    function openMenu(it) {
        if (!it || !it.hasMenu) return
        owner = it
        stack = [it.menu]
        titles = [itemTitle(it)]
    }
    function push(entry) {
        stack = stack.concat([entry])
        titles = titles.concat([entry.text.replace(/_/g, "")])
    }
    function back() {
        if (stack.length <= 1) { stack = []; titles = []; owner = null; return }
        stack = stack.slice(0, -1)
        titles = titles.slice(0, -1)
    }

    QsMenuOpener { id: opener; menu: view.topMenu }

    // ======================= icon grid =======================
    Item {
        id: gridPage
        anchors.fill: parent
        opacity: view.inMenu ? 0 : 1
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 140 } }

        Flow {
            readonly property int used: Math.max(1, Math.min(view.list.length, view.cols)) * view.cell
            x: (parent.width - used) / 2
            y: 12
            width: used
            Repeater {
                model: view.list
                delegate: Item {
                    id: ti
                    required property var modelData
                    width: view.cell
                    height: 56

                    Rectangle {
                        anchors.centerIn: parent
                        width: 46; height: 46; radius: 16
                        color: ma.containsMouse ? Theme.surfaceHi : "transparent"
                        scale: ma.pressed ? 0.9 : (ma.containsMouse ? 1.06 : 1.0)
                        Behavior on color { ColorAnimation { duration: 110 } }
                        Behavior on scale { SpringAnimation { spring: 7; damping: 0.42; epsilon: 0.002 } }
                    }
                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 28
                        source: ti.modelData.icon
                        opacity: ti.modelData.status === Status.Passive ? 0.55 : 1
                    }
                    Rectangle {
                        visible: ti.modelData.status === Status.NeedsAttention
                        x: parent.width / 2 + 10; y: 8
                        width: 9; height: 9; radius: 4.5
                        color: Theme.error
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onEntered: view.hovered = ti.modelData
                        onExited: if (view.hovered === ti.modelData) view.hovered = null
                        onWheel: w => ti.modelData.scroll(w.angleDelta.y, false)
                        onClicked: m => {
                            const it = ti.modelData
                            if (m.button === Qt.RightButton) {
                                if (it.hasMenu) view.openMenu(it); else it.secondaryActivate()
                            } else if (m.button === Qt.MiddleButton) {
                                it.secondaryActivate()
                            } else if (it.onlyMenu && it.hasMenu) {
                                view.openMenu(it)
                            } else {
                                it.activate()
                                view.island.closeIsland()
                            }
                        }
                    }
                }
            }
        }

        Txt {
            x: 0; y: 12
            width: parent.width; height: 56
            horizontalAlignment: Text.AlignHCenter
            visible: view.list.length === 0
            text: "No tray icons"
            font.pixelSize: 13
            color: Theme.fgDim
        }

        // footer: hovered app name
        Item {
            x: 0
            y: 12 + view.gridRows * 56 + 4
            Behavior on y { SpringAnimation { spring: 4.8; damping: 0.50; epsilon: 0.25 } }
            width: parent.width
            height: 28
            Rectangle { width: parent.width; height: 1; color: Theme.outline; opacity: 0.5 }
            Txt {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 2
                width: parent.width - 8
                horizontalAlignment: Text.AlignHCenter
                text: view.hovered ? view.itemTitle(view.hovered) : (view.list.length > 0 ? "System tray · " + view.list.length : "")
                font.pixelSize: 12
                color: view.hovered ? Theme.fg : Theme.fgDim
            }
        }
    }

    // ======================= menu page =======================
    Item {
        id: menuPage
        anchors.fill: parent
        opacity: view.inMenu ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 140 } }

        Item {
            x: 0; y: 8
            width: parent.width
            height: 40
            IconButton {
                id: backBtn
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 32; implicitHeight: 32
                name: "arrow_back"; size: 20; filled: false
                onClicked: view.back()
            }
            IconImage {
                id: ownerIcon
                anchors.left: backBtn.right
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 20
                visible: view.owner !== null && view.stack.length === 1
                source: view.owner ? view.owner.icon : ""
            }
            Txt {
                anchors.left: ownerIcon.visible ? ownerIcon.right : backBtn.right
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: view.titles.length > 0 ? view.titles[view.titles.length - 1] : ""
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
        }
        Rectangle { x: 0; y: 52; width: parent.width; height: 1; color: Theme.outline; opacity: 0.5 }

        ListView {
            id: menuList
            x: 0; y: 56
            width: parent.width
            height: Math.max(view.menuListH, 36)
            Behavior on height { SpringAnimation { spring: 4.8; damping: 0.50; epsilon: 0.25 } }
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: opener.children

            delegate: Item {
                id: row
                required property var modelData
                width: menuList.width
                height: modelData.isSeparator ? 9 : 36

                Rectangle {
                    visible: row.modelData.isSeparator
                    anchors.centerIn: parent
                    width: parent.width - 16; height: 1
                    color: Theme.outline; opacity: 0.6
                }
                Rectangle {
                    visible: !row.modelData.isSeparator
                    anchors.fill: parent
                    anchors.topMargin: 1; anchors.bottomMargin: 1
                    radius: 12
                    color: rowMa.containsMouse && row.modelData.enabled ? Theme.secondaryContainer : "transparent"
                    Behavior on color { ColorAnimation { duration: 90 } }
                }
                Row {
                    visible: !row.modelData.isSeparator
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.right: chev.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    opacity: row.modelData.enabled ? 1 : 0.4

                    Item {
                        id: lead
                        width: 20; height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        visible: row.modelData.buttonType !== QsMenuButtonType.None || row.modelData.icon !== ""
                        Icon {
                            anchors.centerIn: parent
                            visible: row.modelData.buttonType !== QsMenuButtonType.None
                            name: row.modelData.buttonType === QsMenuButtonType.RadioButton
                                  ? (row.modelData.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked")
                                  : (row.modelData.checkState === Qt.Checked ? "check_box" : "check_box_outline_blank")
                            size: 18
                            filled: row.modelData.checkState === Qt.Checked
                            color: row.modelData.checkState === Qt.Checked ? Theme.primary : Theme.fgDim
                        }
                        IconImage {
                            anchors.centerIn: parent
                            visible: row.modelData.buttonType === QsMenuButtonType.None && row.modelData.icon !== ""
                            implicitSize: 18
                            source: row.modelData.icon
                        }
                    }
                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - (lead.visible ? 30 : 0)
                        text: row.modelData.text.replace(/_/g, "")
                        font.pixelSize: 13
                    }
                }
                Icon {
                    id: chev
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    visible: row.modelData.hasChildren
                    name: "chevron_right"
                    size: 18
                    color: Theme.fgDim
                }
                MouseArea {
                    id: rowMa
                    anchors.fill: parent
                    enabled: !row.modelData.isSeparator && row.modelData.enabled
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (row.modelData.hasChildren) view.push(row.modelData)
                        else { row.modelData.triggered(); view.island.closeIsland() }
                    }
                }
            }
        }

        Txt {
            x: 0; y: 56
            width: parent.width; height: 36
            horizontalAlignment: Text.AlignHCenter
            visible: view.entries.length === 0
            text: "Empty menu"
            font.pixelSize: 13
            color: Theme.fgDim
        }
    }
}
