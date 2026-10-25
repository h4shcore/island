import QtQuick
import qs.config

Item {
    id: btn

    property string name: ""       // Material Symbols ligature
    property int size: 26
    property bool filled: true
    property bool hoverFill: true
    property color color: Theme.fg
    property color fill: "transparent"
    signal clicked()

    implicitWidth: 44
    implicitHeight: 44
    opacity: ma.pressed ? 0.65 : 1.0
    Behavior on opacity { NumberAnimation { duration: 90 } }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: btn.fill.a > 0 ? btn.fill : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, btn.hoverFill && ma.containsMouse ? 0.10 : 0)
        scale: ma.pressed ? 0.86 : (ma.containsMouse ? 1.07 : 1.0)
        Behavior on scale { SpringAnimation { spring: 7; damping: 0.38; epsilon: 0.002 } }
        Behavior on color { ColorAnimation { duration: 140 } }

        Icon {
            anchors.centerIn: parent
            name: btn.name
            size: btn.size
            filled: btn.filled
            color: btn.color
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
