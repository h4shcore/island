import QtQuick
import QtQuick.Effects

// One content state of the island. Pinned top-left so it lines up with the
// shared cover art; fades, scales, drops in and de-blurs on enter, and
// leaves quickly (iOS-style: content waits for the morph to start).
Item {
    id: view

    property bool active: false
    property var dims: ({ w: 100, h: 30 })
    property real pad: 16

    x: pad
    y: 0
    width: dims.w - pad * 2
    height: dims.h

    opacity: active ? 1 : 0
    scale: active ? 1 : 0.84
    visible: opacity > 0.01
    enabled: active

    transform: Translate {
        y: view.active ? 0 : -12
        Behavior on y { SpringAnimation { spring: 4.5; damping: 0.55; epsilon: 0.05 } }
    }

    Behavior on opacity {
        SequentialAnimation {
            id: opAnim
            PauseAnimation { duration: view.active ? 90 : 0 }
            NumberAnimation { duration: view.active ? 240 : 100; easing.type: Easing.OutCubic }
        }
    }
    Behavior on scale {
        SequentialAnimation {
            id: scAnim
            PauseAnimation { duration: view.active ? 90 : 0 }
            NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
        }
    }

    // only rasterise + blur while a transition is running (keeps text crisp at rest)
    layer.enabled: opAnim.running || scAnim.running
    layer.effect: MultiEffect {
        blurEnabled: true
        blurMax: 36
        blur: Math.min(1, (1.0 - view.opacity) * 1.2)
    }
}
