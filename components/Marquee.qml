import QtQuick
import qs.config

// Single-line text that glides back and forth when it doesn't fit
Item {
    id: m

    property string text: ""
    property color color: Theme.fg
    property int pixelSize: 14
    property int weight: Font.DemiBold
    readonly property real overflow: Math.max(0, label.implicitWidth - width)

    clip: true
    implicitHeight: label.implicitHeight

    Txt {
        id: label
        text: m.text
        color: m.color
        font.pixelSize: m.pixelSize
        font.weight: m.weight
        elide: Text.ElideNone
        width: implicitWidth
    }

    onOverflowChanged: if (overflow <= 0) label.x = 0
    onTextChanged: label.x = 0

    SequentialAnimation {
        running: m.overflow > 0 && m.visible
        loops: Animation.Infinite
        PauseAnimation { duration: 1800 }
        NumberAnimation { target: label; property: "x"; to: -(m.overflow + 6); duration: Math.max(900, m.overflow * 30); easing.type: Easing.InOutSine }
        PauseAnimation { duration: 1200 }
        NumberAnimation { target: label; property: "x"; to: 0; duration: Math.max(900, m.overflow * 30); easing.type: Easing.InOutSine }
    }
}
