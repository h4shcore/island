import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components

// Volume / brightness / battery live popup.
View {
    id: view
    required property var island
    active: island.mode === "osd"
    dims: island.sizes.osd

    readonly property color accentColor: {
        if (Osd.kind === "battery") {
            if (Osd.charging) return Theme.primary
            if (Osd.value <= 0.15) return Theme.error
        }
        return Osd.muted ? Theme.fgDim : Theme.fg
    }

    RowLayout {
        anchors.fill: parent
        spacing: 12
        Icon {
            Layout.alignment: Qt.AlignVCenter
            name: Osd.icon
            size: 22
            filled: true
            color: view.accentColor
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        Txt {
            visible: Osd.label !== ""
            Layout.alignment: Qt.AlignVCenter
            text: Osd.label
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: view.accentColor
        }
        Rectangle {
            id: bar
            Layout.fillWidth: true
            Layout.preferredHeight: 8
            Layout.alignment: Qt.AlignVCenter
            radius: 4
            color: Theme.secondaryContainer
            Rectangle {
                height: parent.height
                radius: parent.radius
                color: view.accentColor
                width: Math.max(height, bar.width * Math.max(0, Math.min(1, Osd.value)))
                Behavior on width { SpringAnimation { spring: 6; damping: 0.55; epsilon: 0.2 } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
        Txt {
            Layout.preferredWidth: 36
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: Math.round(Osd.value * 100) + (Osd.kind === "battery" ? "%" : "")
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Theme.fgDim
        }
    }
}
