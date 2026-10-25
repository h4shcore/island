import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components

// Volume / brightness popup.
View {
    id: view
    required property var island
    active: island.mode === "osd"
    dims: island.sizes.osd
    RowLayout {
        anchors.fill: parent
        spacing: 12
        Icon { Layout.alignment: Qt.AlignVCenter; name: Osd.icon; size: 22; filled: true }
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
                color: Osd.muted ? Theme.fgDim : Theme.fg
                width: Math.max(height, bar.width * Math.max(0, Math.min(1, Osd.value)))
                Behavior on width { SpringAnimation { spring: 6; damping: 0.55; epsilon: 0.2 } }
            }
        }
        Txt {
            Layout.preferredWidth: 34
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: Math.round(Osd.value * 100)
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Theme.fgDim
        }
    }
}
