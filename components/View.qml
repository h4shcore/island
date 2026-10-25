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
    property bool ready: false

    x: pad
    y: 0
    width: dims.w - pad * 2
    height: dims.h

    opacity: 0
    scale: 0.84
    visible: opacity > 0.01
    enabled: active

    transform: Translate {
        id: shift
        y: -12
    }

    Component.onCompleted: {
        opacity = active ? 1 : 0
        scale = active ? 1 : 0.84
        shift.y = active ? 0 : -12
        ready = true
    }

    onActiveChanged: {
        if (!ready) return
        if (active) {
            exitAnim.stop()
            if (opacity <= 0.01) {
                opacity = 0
                scale = 0.84
                shift.y = -12
                enterPause.duration = 90
            } else {
                enterPause.duration = 0
            }
            enterAnim.restart()
        } else {
            enterAnim.stop()
            if (opacity <= 0.01) {
                opacity = 0
                scale = 0.84
                shift.y = -12
            } else {
                exitAnim.restart()
            }
        }
    }

    SequentialAnimation {
        id: enterAnim
        PauseAnimation { id: enterPause; duration: 90 }
        ParallelAnimation {
            NumberAnimation { target: view; property: "opacity"; to: 1; duration: 240; easing.type: Easing.OutCubic }
            NumberAnimation { target: view; property: "scale"; to: 1; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
            SpringAnimation { target: shift; property: "y"; to: 0; spring: 4.5; damping: 0.55; epsilon: 0.05 }
        }
    }

    ParallelAnimation {
        id: exitAnim
        NumberAnimation { target: view; property: "opacity"; to: 0; duration: 90; easing.type: Easing.OutCubic }
        NumberAnimation { target: view; property: "scale"; to: 0.84; duration: 90; easing.type: Easing.InCubic }
        NumberAnimation { target: shift; property: "y"; to: -12; duration: 90; easing.type: Easing.InCubic }
    }

    // only rasterise + blur while a transition is running (keeps text crisp at rest)
    layer.enabled: enterAnim.running || exitAnim.running
    layer.effect: MultiEffect {
        blurEnabled: true
        blurMax: 36
        blur: Math.min(1, (1.0 - view.opacity) * 1.2)
    }
}
