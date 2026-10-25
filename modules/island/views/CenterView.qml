import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import qs.config
import qs.services
import qs.components

// Control center: connectivity tiles, sound + display sliders, notifications.
View {
    id: view
    required property var island

    // wheel over a slider / a scrollable notification list must not flip the page
    readonly property bool overSlider: sub !== "" || volSlider.hovered || briSlider.hovered || (Notifs.history.length > 2 && listHover.hovered)

    // picker sub-page: "" (main) | wifi | bt
    property string sub: ""
    property string askSsid: ""                // secured network waiting for its password
    readonly property bool typing: sub === "wifi" && askSsid !== ""
    function openSub(s) {
        sub = s
        askSsid = ""
        if (s === "wifi") Controls.scanWifi()
        if (s === "bt") Controls.btScan(true)
    }
    function closeSub() {
        if (sub === "bt") Controls.btScan(false)
        sub = ""
        askSsid = ""
    }
    Connections { target: view.island; function onModeChanged() { if (view.island.mode !== "center" && view.sub !== "") view.closeSub() } }
    Connections { target: Controls; function onBtOnChanged() { if (view.sub === "bt") Controls.btScan(true) } }
    onTypingChanged: if (typing) focusTimer.restart()
    Timer { id: focusTimer; interval: 60; repeat: true
        property int n: 0
        onTriggered: { passInput.forceActiveFocus(); if (++n >= 10 || passInput.activeFocus) { stop(); n = 0 } }
    }

    function btIcon(d) {
        const i = d.icon || ""
        if (i.indexOf("headset") >= 0 || i.indexOf("headphone") >= 0) return "headphones"
        if (i.indexOf("keyboard") >= 0) return "keyboard"
        if (i.indexOf("mouse") >= 0) return "mouse"
        if (i.indexOf("phone") >= 0) return "smartphone"
        if (i.indexOf("gaming") >= 0) return "sports_esports"
        if (i.indexOf("speaker") >= 0) return "speaker"
        return "bluetooth"
    }
    function wifiIcon(sig) { return sig > 75 ? "signal_wifi_4_bar" : sig > 50 ? "network_wifi_3_bar" : sig > 25 ? "network_wifi_2_bar" : "network_wifi_1_bar" }
    readonly property int gap: 10
    pad: 14
    active: island.mode === "center"
    dims: island.sizes.center

    // ================= main page =================
    View {
        id: mainPage
        property var island: null   // no slide direction: same blur-fade morph as the island pages
        pad: 0
        dims: ({ w: view.width, h: view.height })
        active: view.sub === ""

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
            more: true
            onMoreClicked: view.openSub("wifi")
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
            more: true
            onMoreClicked: view.openSub("bt")
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
                id: volPill
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

    // ================= picker page (Wi-Fi / Bluetooth / sound output) =================
    View {
        id: picker
        property var island: null   // no slide direction: same blur-fade morph as the island pages
        pad: 0
        dims: ({ w: view.width, h: view.height })
        active: view.sub !== ""

        // header: back, title, refresh, on/off switch
        Item {
            id: pHead
            x: 0; y: 14
            width: parent.width; height: 44

            IconButton {
                x: 0
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 40; implicitHeight: 40
                name: "arrow_back"; size: 22; filled: false
                onClicked: view.closeSub()
            }
            Txt {
                x: 48
                anchors.verticalCenter: parent.verticalCenter
                text: view.sub === "wifi" ? "Wi-Fi" : "Bluetooth"
                font.pixelSize: 17
                font.weight: Font.DemiBold
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                IconButton {
                    id: refreshBtn
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: view.sub === "wifi" && Controls.wifi ? 1 : 0
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    implicitWidth: 36; implicitHeight: 36
                    name: "refresh"; size: 20; filled: false
                    color: Controls.wifiScanning ? Theme.primary : Theme.fg
                    onClicked: Controls.scanWifi()
                    RotationAnimator {
                        target: refreshBtn
                        from: 0; to: 360; duration: 900
                        loops: Animation.Infinite
                        running: Controls.wifiScanning && refreshBtn.visible
                        onRunningChanged: if (!running) refreshBtn.rotation = 0
                    }
                }
                // on/off switch
                Rectangle {
                    id: sw
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property bool on: view.sub === "wifi" ? Controls.wifi : Controls.btOn
                    width: 50; height: 30; radius: 15
                    opacity: view.sub === "bt" && !Controls.btAvailable ? 0.4 : 1
                    color: on ? Theme.primary : Theme.secondaryContainer
                    Behavior on color { ColorAnimation { duration: 160 } }
                    Rectangle {
                        width: 22; height: 22; radius: 11
                        y: 4
                        x: sw.on ? parent.width - width - 4 : 4
                        color: sw.on ? Theme.primaryFg : Theme.fgDim
                        Behavior on x { SpringAnimation { spring: 7; damping: 0.55; epsilon: 0.1 } }
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: view.sub === "wifi" ? Controls.toggleWifi() : Controls.toggleBluetooth()
                    }
                }
            }
        }

        Rectangle {
            id: listCard
            x: 0; y: 68
            width: parent.width
            height: parent.height - y - 14
            radius: 24
            color: Theme.card
            clip: true

            // ---- Wi-Fi ----
            View {
                id: wifiPane
                property var island: null   // no slide direction: same blur-fade morph as the island pages
                pad: 0
                dims: ({ w: listCard.width, h: listCard.height })
                active: view.sub === "wifi" && view.askSsid === ""
            ListView {
                anchors.fill: parent; anchors.margins: 6
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: Controls.wifi ? Controls.wifiList : []
                delegate: PickerRow {
                    required property var modelData
                    width: ListView.view.width
                    icon: view.wifiIcon(modelData.signal)
                    title: modelData.ssid
                    subtitle: Controls.wifiBusy === modelData.ssid ? "Working…"
                            : modelData.active ? "Connected"
                            : Controls.wifiKnown.indexOf(modelData.ssid) >= 0 ? "Saved"
                            : modelData.secure ? "Secured" : "Open"
                    selected: modelData.active
                    trailing: modelData.active ? "check" : (modelData.secure ? "lock" : "")
                    busy: Controls.wifiBusy === modelData.ssid
                    onClicked: {
                        if (modelData.active) Controls.disconnectWifi(modelData.ssid)
                        else if (modelData.secure && Controls.wifiKnown.indexOf(modelData.ssid) < 0) { view.askSsid = modelData.ssid; passInput.text = "" }
                        else Controls.connectWifi(modelData.ssid)
                    }
                }
            }
            Txt {
                anchors.centerIn: parent
                visible: (!Controls.wifi || Controls.wifiList.length === 0)
                color: Theme.fgDim
                text: !Controls.wifi ? "Wi-Fi is off" : (Controls.wifiScanning ? "Searching…" : "No networks found")
            }
            Txt {
                x: 18; y: parent.height - 30
                width: parent.width - 36
                visible: Controls.wifiMsg !== ""
                text: Controls.wifiMsg
                font.pixelSize: 11
                color: Theme.error
            }
            }

            // password prompt for a new secured network
            View {
                id: passPane
                property var island: null   // no slide direction: same blur-fade morph as the island pages
                pad: 0
                dims: ({ w: listCard.width, h: listCard.height })
                active: view.sub === "wifi" && view.askSsid !== ""

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 48
                    spacing: 12
                    Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "lock"; size: 26; color: Theme.fgDim }
                    Txt { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: view.askSsid; font.pixelSize: 15; font.weight: Font.DemiBold }
                    Rectangle {
                        width: parent.width; height: 42; radius: 21
                        color: Theme.bg
                        border.width: passInput.activeFocus ? 1 : 0
                        border.color: Theme.primary
                        TextInput {
                            id: passInput
                            anchors.fill: parent
                            anchors.leftMargin: 18; anchors.rightMargin: 18
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 14
                            selectionColor: Theme.primary
                            selectedTextColor: Theme.primaryFg
                            clip: true
                            Keys.onReturnPressed: go()
                            Keys.onEnterPressed: go()
                            Keys.onEscapePressed: view.askSsid = ""
                            function go() {
                                if (text === "") return
                                Controls.connectWifi(view.askSsid, text)
                                view.askSsid = ""
                                text = ""
                            }
                            Txt { anchors.verticalCenter: parent.verticalCenter; visible: parent.text === ""; text: "Password"; color: Theme.fgDim; font.pixelSize: 14 }
                        }
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10
                        Rectangle {
                            width: 110; height: 38; radius: 19
                            color: cancelMa.containsMouse ? Theme.cardHi : Theme.secondaryContainer
                            Txt { anchors.centerIn: parent; text: "Cancel"; font.pixelSize: 13; font.weight: Font.Medium }
                            MouseArea { id: cancelMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: view.askSsid = "" }
                        }
                        Rectangle {
                            width: 110; height: 38; radius: 19
                            color: Theme.primary
                            opacity: passInput.text === "" ? 0.5 : 1
                            Txt { anchors.centerIn: parent; text: "Connect"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.primaryFg }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: passInput.go() }
                        }
                    }
                }
            }

            // ---- Bluetooth ----
            View {
                id: btPane
                property var island: null   // no slide direction: same blur-fade morph as the island pages
                pad: 0
                dims: ({ w: listCard.width, h: listCard.height })
                active: view.sub === "bt"
            ListView {
                anchors.fill: parent; anchors.margins: 6
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: Controls.btList
                delegate: PickerRow {
                    required property var modelData
                    readonly property bool working: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                    width: ListView.view.width
                    icon: view.btIcon(modelData)
                    title: modelData.name
                    subtitle: working ? "Working…"
                            : modelData.connected ? "Connected" + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : "")
                            : modelData.paired ? "Paired" : "Tap to pair"
                    selected: modelData.connected
                    trailing: modelData.connected ? "check" : ""
                    busy: working
                    onClicked: Controls.btActivate(modelData)
                }
            }
            Txt {
                anchors.centerIn: parent
                visible: (!Controls.btOn || Controls.btList.length === 0)
                color: Theme.fgDim
                text: !Controls.btAvailable ? "No Bluetooth adapter" : (!Controls.btOn ? "Bluetooth is off" : "Searching…")
            }
            }
        }
    }
}
