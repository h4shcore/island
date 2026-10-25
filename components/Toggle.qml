import QtQuick
import qs.config

// Control-center tile: icon chip top-left, label + state bottom-left.
// Fills with the accent when active.
Item {
    id: t

    property string icon: ""
    property string label: ""
    property string subtitle: ""
    property bool active: false
    property bool available: true
    signal clicked()

    Rectangle {
        anchors.fill: parent
        radius: 26
        opacity: t.available ? 1 : 0.4
        color: t.active ? Theme.primary : (ma.containsMouse ? Theme.surfaceHiest : Theme.surfaceHi)
        scale: ma.pressed ? 0.95 : 1.0
        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on scale { SpringAnimation { spring: 8; damping: 0.5; epsilon: 0.002 } }

        Rectangle {
            id: chip
            x: 12; y: 12
            width: 36; height: 36; radius: 18
            color: t.active ? Qt.rgba(Theme.primaryFg.r, Theme.primaryFg.g, Theme.primaryFg.b, 0.16) : Theme.secondaryContainer
            Behavior on color { ColorAnimation { duration: 160 } }
            Icon {
                anchors.centerIn: parent
                name: t.icon
                size: 20
                filled: false
                color: t.active ? Theme.primaryFg : Theme.fg
            }
        }

        Column {
            x: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            width: parent.width - 24
            spacing: 0
            Txt {
                width: parent.width
                text: t.label
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: t.active ? Theme.primaryFg : Theme.fg
            }
            Txt {
                width: parent.width
                visible: text !== ""
                text: t.subtitle
                font.pixelSize: 11
                color: t.active ? Theme.primaryFg : Theme.fgDim
                opacity: t.active ? 0.75 : 1
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
