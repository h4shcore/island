import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components

// Idle pill: the time, plus the battery icon (pill.batteryIcon).
View {
    id: view
    required property var island
    active: island.mode === "idle"
    dims: island.sizes.idle
    Row {
        anchors.centerIn: parent
        spacing: 7
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(Clock.date, Config.timeFormat)
            font.weight: Font.DemiBold
            font.letterSpacing: 0.4
        }
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: island.pillBattery
            name: island.batteryIcon
            size: 17
            filled: true
            color: island.batteryColor
        }
    }
}
