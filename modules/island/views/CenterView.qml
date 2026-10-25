import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components

// Control center: connectivity tiles, sound + display sliders, notifications.
View {
    id: view
    required property var island

    // wheel over a slider / a scrollable notification list must not flip the page
    readonly property bool overSlider: volSlider.hovered || briSlider.hovered || (Notifs.history.length > 2 && listHover.hovered)
    readonly property int gap: 10
    pad: 14
    active: island.mode === "center"
    dims: island.sizes.center

    // ---- row 1: Wi-Fi, Focus, lock ----
    RowLayout {
        x: 0; y: 14
        width: parent.width
        height: 60
        spacing: view.gap
        PillToggle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            icon: Controls.wifi ? "wifi" : "wifi_off"
            label: "Wi-Fi"
            subtitle: !Controls.wifi ? "Off" : (Controls.wifiName !== "" ? Controls.wifiName : "On")
            active: Controls.wifi
            onClicked: Controls.toggleWifi()
        }
        PillToggle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            icon: "do_not_disturb_on"
            label: "Focus"
            subtitle: Notifs.dnd ? "On" : "Off"
            active: Notifs.dnd
            onClicked: Notifs.dnd = !Notifs.dnd
        }
        IconButton {
            Layout.preferredWidth: 60
            Layout.preferredHeight: 60
            implicitWidth: 60
            implicitHeight: 60
            name: "lock"; size: 22; filled: false
            fill: Theme.card
            onClicked: { island.closeIsland(); Power.run("lock") }
        }
    }

    // ---- row 2: Bluetooth, Awake, power menu ----
    RowLayout {
        x: 0; y: 84
        width: parent.width
        height: 60
        spacing: view.gap
        PillToggle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            icon: Controls.btOn ? "bluetooth" : "bluetooth_disabled"
            label: "Bluetooth"
            subtitle: !Controls.btAvailable ? "N/A" : (!Controls.btOn ? "Off" : (Controls.btDevice !== "" ? Controls.btDevice : "On"))
            active: Controls.btOn
            available: Controls.btAvailable
            onClicked: Controls.toggleBluetooth()
        }
        PillToggle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            icon: "coffee"
            label: "Awake"
            subtitle: Controls.keepAwake ? "On" : "Off"
            active: Controls.keepAwake
            onClicked: Controls.keepAwake = !Controls.keepAwake
        }
        IconButton {
            Layout.preferredWidth: 60
            Layout.preferredHeight: 60
            implicitWidth: 60
            implicitHeight: 60
            name: "power_settings_new"; size: 22; filled: false
            fill: Theme.card
            onClicked: island.page = "power"
        }
    }

    // ---- sound ----
    Rectangle {
        x: 0; y: 154
        width: parent.width; height: 72
        radius: 24
        color: Theme.card

        Txt { x: 14; y: 9; text: "Sound"; font.pixelSize: 13; font.weight: Font.DemiBold }
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: 12
            y: 8
            width: Math.max(24, volTxt.implicitWidth + 16); height: 24; radius: 12
            color: Theme.bg
            Txt {
                id: volTxt
                anchors.centerIn: parent
                text: Controls.muted ? "Muted" : Math.round(Controls.volume * 100)
                font.pixelSize: 11
                font.weight: Font.Medium
                color: Theme.fgDim
            }
        }
        HSlider {
            id: volSlider
            x: 12; y: 38
            width: parent.width - 24; height: 24
            icon: Controls.volumeIcon
            value: Controls.volume
            dimmed: Controls.muted
            iconAction: true
            onMoved: v => Controls.setVolume(v)
            onIconClicked: Controls.toggleMute()
        }
    }

    // ---- display ----
    Rectangle {
        x: 0; y: 236
        width: parent.width; height: 72
        radius: 24
        color: Theme.card

        Txt { x: 14; y: 9; text: "Display"; font.pixelSize: 13; font.weight: Font.DemiBold }
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: 12
            y: 8
            width: Math.max(24, briTxt.implicitWidth + 16); height: 24; radius: 12
            color: Theme.bg
            Txt {
                id: briTxt
                anchors.centerIn: parent
                text: Math.round(Controls.brightness * 100)
                font.pixelSize: 11
                font.weight: Font.Medium
                color: Theme.fgDim
            }
        }
        HSlider {
            id: briSlider
            x: 12; y: 38
            width: parent.width - 24; height: 24
            icon: "light_mode"
            value: Controls.brightness
            onMoved: v => Controls.setBrightness(v)
        }
    }

    // ---- notifications ----
    Rectangle {
        id: notifCard
        x: 0; y: 318
        width: parent.width
        height: view.height - y - 14
        radius: 24
        color: Theme.card

        Txt { x: 16; y: 12; text: "Notifications"; font.pixelSize: 12; color: Theme.fgDim }

        // right side of the header: battery, "Clear", page shortcuts
        Row {
            anchors.right: parent.right; anchors.rightMargin: 10
            y: 6
            height: 28
            spacing: 2

            Row {
                anchors.verticalCenter: parent.verticalCenter
                visible: Config.showBattery && island.hasBattery
                spacing: 3
                rightPadding: 8
                Icon { anchors.verticalCenter: parent.verticalCenter; name: island.batteryIcon; size: 16; filled: true; color: island.batteryColor }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) + "%" : ""
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Theme.fgDim
                }
            }
            Item {
                anchors.verticalCenter: parent.verticalCenter
                visible: Notifs.history.length > 0
                width: clearTxt.implicitWidth + 16; height: 24
                Txt { id: clearTxt; anchors.centerIn: parent; text: "Clear"; font.pixelSize: 11; font.weight: Font.Medium; color: Theme.fgDim }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.clearHistory()
                }
            }
            IconButton { anchors.verticalCenter: parent.verticalCenter; implicitWidth: 28; implicitHeight: 28; name: "timer"; size: 17; filled: Countdown.active; color: Countdown.active ? Theme.primary : Theme.fg; onClicked: island.page = "timer" }
            IconButton { anchors.verticalCenter: parent.verticalCenter; implicitWidth: 28; implicitHeight: 28; name: "search"; size: 17; filled: false; onClicked: island.page = "launcher" }
            IconButton { anchors.verticalCenter: parent.verticalCenter; implicitWidth: 28; implicitHeight: 28; name: "content_paste"; size: 17; filled: false; onClicked: island.page = "clipboard" }
            IconButton { anchors.verticalCenter: parent.verticalCenter; implicitWidth: 28; implicitHeight: 28; name: "wallpaper"; size: 17; filled: false; onClicked: island.page = "walls" }
            IconButton { anchors.verticalCenter: parent.verticalCenter; implicitWidth: 28; implicitHeight: 28; name: "emoji_emotions"; size: 17; filled: false; onClicked: island.page = "emoji" }
            IconButton { anchors.verticalCenter: parent.verticalCenter; implicitWidth: 28; implicitHeight: 28; name: "calendar_month"; size: 17; filled: false; onClicked: island.page = "calendar" }
            IconButton { anchors.verticalCenter: parent.verticalCenter; implicitWidth: 28; implicitHeight: 28; name: "widgets"; size: 17; filled: false; onClicked: island.page = "tray" }
        }

        Txt {
            x: 16; y: 44
            visible: Notifs.history.length === 0
            text: "No notifications"
            font.pixelSize: 14
        }

        ListView {
            id: notifList
            x: 8; y: 40
            width: parent.width - 16
            height: parent.height - y - 6
            visible: Notifs.history.length > 0
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: Notifs.history

            HoverHandler { id: listHover }

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                width: notifList.width
                height: 52

                Art {
                    id: rowArt
                    x: 8; y: 8
                    width: 36; height: 36
                    radius: 11
                    source: row.modelData.image
                    fallback: "notifications"
                }
                Column {
                    anchors.left: rowArt.right; anchors.leftMargin: 10
                    anchors.right: rowClose.left; anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    Row {
                        width: parent.width
                        spacing: 6
                        Txt {
                            width: parent.width - rowTime.implicitWidth - 6
                            text: row.modelData.title !== "" ? row.modelData.title : row.modelData.app
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: row.modelData.critical ? Theme.error : Theme.fg
                        }
                        Txt {
                            id: rowTime
                            text: Qt.formatDateTime(new Date(row.modelData.time), Config.timeFormat)
                            font.pixelSize: 10
                            color: Theme.fgDim
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    Txt {
                        width: parent.width
                        text: (row.modelData.title !== "" ? row.modelData.app + (row.modelData.body !== "" ? " · " : "") : "") + row.modelData.body.replace(/<[^>]*>/g, "").replace(/\s+/g, " ")
                        font.pixelSize: 11
                        color: Theme.fgDim
                    }
                }
                IconButton {
                    id: rowClose
                    anchors.right: parent.right; anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 26; implicitHeight: 26
                    name: "close"; size: 15; filled: false
                    onClicked: Notifs.dismissAt(row.index)
                }
            }
        }
    }
}
