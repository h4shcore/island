import QtQuick
import qs.config

// One row of a control-center picker (Wi-Fi network, Bluetooth device, audio output).
Item {
    id: r

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool selected: false      // current network / device / output
    property string trailing: ""       // Material Symbols name shown on the right
    property bool busy: false
    signal clicked()

    implicitHeight: 56

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 4; anchors.rightMargin: 4
        anchors.topMargin: 2; anchors.bottomMargin: 2
        radius: 18
        color: ma.containsMouse ? Theme.cardHi : "transparent"
        scale: ma.pressed ? 0.98 : 1.0
        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on scale { SpringAnimation { spring: 8; damping: 0.5; epsilon: 0.002 } }

        Rectangle {
            id: chip
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 38; height: 38; radius: 19
            color: r.selected ? Theme.primary : Theme.secondaryContainer
            Behavior on color { ColorAnimation { duration: 160 } }
            Icon {
                anchors.centerIn: parent
                name: r.icon
                size: 20
                color: r.selected ? Theme.primaryFg : Theme.fg
            }
        }

        Column {
            anchors.left: chip.right; anchors.leftMargin: 12
            anchors.right: tail.left; anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Txt { width: parent.width; text: r.title; font.pixelSize: 14; font.weight: Font.DemiBold }
            Txt { width: parent.width; visible: text !== ""; text: r.subtitle; font.pixelSize: 11; color: Theme.fgDim }
        }

        Icon {
            id: tail
            anchors.right: parent.right; anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            name: r.busy ? "progress_activity" : r.trailing
            visible: name !== ""
            size: 18
            color: r.selected && !r.busy ? Theme.primary : Theme.fgDim
            RotationAnimator on rotation { running: r.busy; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: r.clicked()
    }
}
