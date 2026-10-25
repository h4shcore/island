import QtQuick
import qs.config

Row {
    id: eq

    property bool running: false
    property color color: Theme.primary

    spacing: 3
    height: 20

    Repeater {
        model: 5

        Item {
            id: cell
            required property int index
            readonly property real peak: [11, 18, 14, 20, 12][index]
            property real h: 4

            width: 3
            height: eq.height

            Rectangle {
                width: 3
                radius: 1.5
                color: eq.color
                anchors.verticalCenter: parent.verticalCenter
                height: eq.running && eq.visible ? cell.h : 4
            }

            SequentialAnimation {
                running: eq.running && eq.visible
                loops: Animation.Infinite
                NumberAnimation { target: cell; property: "h"; to: cell.peak; duration: 240 + cell.index * 63; easing.type: Easing.InOutQuad }
                NumberAnimation { target: cell; property: "h"; to: 5; duration: 280 + cell.index * 47; easing.type: Easing.InOutQuad }
                NumberAnimation { target: cell; property: "h"; to: cell.peak * 0.6; duration: 200 + cell.index * 51; easing.type: Easing.InOutQuad }
                NumberAnimation { target: cell; property: "h"; to: 4; duration: 260 + cell.index * 39; easing.type: Easing.InOutQuad }
            }
        }
    }
}
