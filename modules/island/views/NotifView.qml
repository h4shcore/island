import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components

// Notification banner.
View {
    id: view
    required property var island
    active: island.mode === "notif"
    dims: island.sizes.notif
    RowLayout {
        anchors.fill: parent
        spacing: 14
        Item { Layout.preferredWidth: 48 }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1
            Txt {
                Layout.fillWidth: true
                text: Notifs.app
                font.pixelSize: 10
                font.letterSpacing: 0.9
                font.capitalization: Font.AllUppercase
                color: Notifs.critical ? Theme.error : Theme.fgDim
            }
            Txt {
                Layout.fillWidth: true
                text: Notifs.title
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Txt {
                Layout.fillWidth: true
                text: Notifs.body
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 2
                font.pixelSize: 12
                color: Theme.fgDim
            }
        }
    }
}
