import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components

// Hover state with nothing playing.
View {
    id: view
    required property var island
    active: island.mode === "hub"
    dims: island.sizes.hub
    IconButton {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 8
        implicitWidth: 32
        implicitHeight: 32
        name: "search"
        size: 18
        filled: false
        onClicked: island.page = "launcher"
    }
    IconButton {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 8
        implicitWidth: 32
        implicitHeight: 32
        name: "tune"
        size: 18
        filled: false
        onClicked: island.page = "center"
    }
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0
        Txt {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(Clock.date, Config.timeFormat)
            font.pixelSize: 42
            font.weight: Font.Medium
            font.letterSpacing: -1
        }
        Txt {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(Clock.date, Config.dateFormat)
            font.pixelSize: 12
            color: Theme.fgDim
        }
    }
}
