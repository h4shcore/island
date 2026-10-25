import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components

// Compact pill while something plays: cover art left (shared Art item),
// clock (pill.clockWithMedia) and battery icon (pill.batteryIcon) in the middle,
// equalizer right.
View {
    id: view
    required property var island
    active: island.mode === "media"
    dims: island.sizes.media

    Row {
        anchors.centerIn: parent
        spacing: 7
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            visible: Config.pillClockWithMedia
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

    Equalizer {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        running: island.mediaPlaying
    }
}
