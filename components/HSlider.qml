import QtQuick
import qs.config

// Horizontal pill slider: the fill grows from the left and carries the icon.
// With iconAction a tap on the icon (no drag) emits iconClicked (e.g. mute).
// Mouse wheel nudges the value by 5%.
Item {
    id: s

    property real value: 0
    property string icon: ""
    property bool dimmed: false
    property bool iconAction: false
    readonly property bool hovered: ma.containsMouse
    signal moved(real v)
    signal iconClicked()

    readonly property real target: Math.max(0, Math.min(1, ma.pressed ? ma.v : value))
    property real shown: target
    Behavior on shown { enabled: !ma.pressed; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    readonly property bool accented: Config.sliderAccent && !dimmed
    readonly property color fillColor: dimmed ? Theme.fgDim : (Config.sliderAccent ? Theme.primary : Theme.fg)
    readonly property color onFill: accented ? Theme.primaryFg : Theme.surface

    // track
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.surface
    }

    // fill: never narrower than a circle, so the icon always sits on it
    Rectangle {
        width: s.height + (s.width - s.height) * s.shown
        height: s.height
        radius: height / 2
        color: s.fillColor
        Behavior on color { ColorAnimation { duration: 150 } }

        Icon {
            x: 0
            width: s.height
            height: s.height
            name: s.icon
            size: 16
            filled: true
            color: s.onFill
            scale: ma.pressed && ma.tap ? 0.88 : 1.0
            Behavior on scale { SpringAnimation { spring: 8; damping: 0.5; epsilon: 0.002 } }
        }
    }

    MouseArea {
        id: ma
        property real v: 0
        property real px: 0
        property bool tap: false
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        // the cap of the fill follows the cursor
        function val(x) { return Math.max(0, Math.min(1, (x - s.height / 2) / Math.max(1, s.width - s.height))) }

        onPressed: m => {
            px = m.x
            tap = s.iconAction && m.x < s.height
            if (tap) {
                v = s.value
            } else {
                v = val(m.x)
                s.moved(v)
            }
        }
        onPositionChanged: m => {
            if (!pressed) return
            if (tap && Math.abs(m.x - px) > 3) tap = false
            if (!tap) {
                v = val(m.x)
                s.moved(v)
            }
        }
        onReleased: {
            if (tap) s.iconClicked()
            tap = false
        }
        onWheel: w => s.moved(Math.max(0, Math.min(1, s.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
