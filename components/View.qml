import QtQuick
import QtQuick.Effects

// One content state of the island. Pinned top-left so it lines up with the
// shared cover art; cross-fades with a gaussian blur and directional slide
// momentum between overlapping view transitions.
Item {
    id: view

    property bool active: false
    property var dims: ({ w: 100, h: 30 })
    property real pad: 16
    property real blurAmount: 1
    property bool ready: false

    // directional slide hint (-1 = left, 0 = vertical morph, 1 = right)
    readonly property int navDir: (view.island && view.island.navDir !== undefined) ? view.island.navDir : 0

    x: pad
    y: 0
    width: dims.w - pad * 2
    height: dims.h

    opacity: 0
    scale: 0.90
    visible: opacity > 0.01
    enabled: active

    transform: Translate {
        id: shift
        x: 0
        y: -10
    }

    Component.onCompleted: {
        opacity = active ? 1 : 0
        scale = active ? 1 : 0.90
        shift.x = 0
        shift.y = active ? 0 : -10
        blurAmount = active ? 0 : 1
        ready = true
    }

    onActiveChanged: {
        if (!ready) return
        if (active) {
            exitAnim.stop()
            if (opacity <= 0.01) {
                opacity = 0
                scale = 0.90
                shift.x = navDir * 20
                shift.y = navDir === 0 ? -10 : -4
                blurAmount = 1
                enterPause.duration = 45
            } else {
                enterPause.duration = 0
            }
            enterAnim.restart()
        } else {
            enterAnim.stop()
            if (opacity <= 0.01) {
                opacity = 0
                scale = 0.90
                shift.x = 0
                shift.y = -10
                blurAmount = 1
            } else {
                exitShiftX.to = -navDir * 20
                exitShiftY.to = navDir === 0 ? -10 : -4
                exitAnim.restart()
            }
        }
    }

    SequentialAnimation {
        id: enterAnim
        PauseAnimation { id: enterPause; duration: 45 }
        ParallelAnimation {
            NumberAnimation { target: view; property: "opacity"; to: 1; duration: 220; easing.type: Easing.InOutCubic }
            NumberAnimation { target: view; property: "scale"; to: 1; duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.25 }
            NumberAnimation { target: shift; property: "x"; to: 0; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
            NumberAnimation { target: shift; property: "y"; to: 0; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            SequentialAnimation {
                PauseAnimation { duration: 35 }
                NumberAnimation { target: view; property: "blurAmount"; to: 0; duration: 240; easing.type: Easing.OutCubic }
            }
        }
    }

    ParallelAnimation {
        id: exitAnim
        NumberAnimation { target: view; property: "blurAmount"; to: 1; duration: 110; easing.type: Easing.OutQuad }
        NumberAnimation { target: view; property: "opacity"; to: 0; duration: 170; easing.type: Easing.InOutQuad }
        NumberAnimation { target: view; property: "scale"; to: 0.90; duration: 170; easing.type: Easing.InOutQuad }
        NumberAnimation { id: exitShiftX; target: shift; property: "x"; to: 0; duration: 170; easing.type: Easing.InOutQuad }
        NumberAnimation { id: exitShiftY; target: shift; property: "y"; to: -10; duration: 170; easing.type: Easing.InOutQuad }
    }

    // only rasterise + blur while a transition is running (keeps text crisp at rest)
    layer.enabled: enterAnim.running || exitAnim.running
    layer.effect: MultiEffect {
        blurEnabled: true
        blurMax: 44
        blur: view.blurAmount
    }
}
