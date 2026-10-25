import QtQuick
import qs.config

// Control-center tile, pill shaped: round icon chip on the left, label + state next to it.
// The chip fills with the accent when active.
Item {
    id: t

    property string icon: ""
    property string label: ""
    property string subtitle: ""
    property bool active: false
    property bool available: true
    signal clicked()

    Rectangle {
        id: body
        anchors.fill: parent
        radius: height / 2
        opacity: t.available ? 1 : 0.4
        color: ma.containsMouse ? Theme.cardHi : Theme.card
        scale: ma.pressed ? 0.96 : 1.0
        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on scale { SpringAnimation { spring: 8; damping: 0.5; epsilon: 0.002 } }

        Rectangle {
            id: chip
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height - 20
            height: width
            radius: width / 2
            color: t.active ? Theme.primary : Theme.secondaryContainer
            Behavior on color { ColorAnimation { duration: 160 } }
            Icon {
                anchors.centerIn: parent
                name: t.icon
                size: 20
                filled: true
                color: t.active ? Theme.primaryFg : Theme.fg
            }
        }

        Column {
            anchors.left: chip.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Txt {
                width: parent.width
                text: t.label
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Txt {
                width: parent.width
                visible: text !== ""
                text: t.subtitle
                font.pixelSize: 11
                color: Theme.fgDim
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        enabled: t.available
        cursorShape: Qt.PointingHandCursor
        onClicked: t.clicked()
    }
}
