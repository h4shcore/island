import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components

// Track-change peek.
View {
    id: view
    required property var island
    active: island.mode === "peek"
    dims: island.sizes.peek
    RowLayout {
        anchors.fill: parent
        spacing: 12
        Item { Layout.preferredWidth: 46 }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1
            Marquee { Layout.fillWidth: true; text: island.title; pixelSize: 14 }
            Txt { Layout.fillWidth: true; text: island.artist; font.pixelSize: 12; color: Theme.fgDim }
        }
        Equalizer { Layout.alignment: Qt.AlignVCenter; running: island.mediaPlaying }
    }
}
