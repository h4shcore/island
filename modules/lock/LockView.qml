import QtQuick
import QtQuick.Effects
import qs.config
import qs.services
import qs.components

// What one monitor shows while the session is locked.
// One progress value `p` (0 = black, 1 = fully shown) drives the whole entrance:
// wallpaper blurs in, the clock drifts up, then the password pill springs in.
// A correct password plays it backwards (Lock.leaving) before the session unlocks.
Rectangle {
    id: root
    color: Theme.bg

    readonly property string wall: Config.lockWallpaper && Wallpapers.current !== "" ? "file://" + Wallpapers.current : ""

    property bool shown: false
    readonly property real p: _p
    property real _p: shown && !Lock.leaving ? 1 : 0
    Behavior on _p { NumberAnimation { duration: Lock.leaving ? 320 : 800; easing.type: Easing.OutCubic } }
    Component.onCompleted: Qt.callLater(() => shown = true)

    // 0..1 slice of the entrance, so things can start one after another
    function seg(a, b) { return Math.max(0, Math.min(1, (p - a) / (b - a))) }

    // ---- blurred, dimmed wallpaper (blur and dim ramp up with p) ----
    Image {
        id: bg
        anchors.fill: parent
        source: root.wall
        visible: false
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 1280
        sourceSize.height: 720
    }
    MultiEffect {
        anchors.fill: parent
        source: bg
        visible: bg.status === Image.Ready
        autoPaddingEnabled: false
        scale: 1.08 - 0.08 * root.p            // slow settle
        blurEnabled: true
        blurMax: 64
        blur: root.p
        brightness: -0.35 * root.p
    }

    // ---- clock ----
    Column {
        id: clockCol
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.24 + (1 - root.seg(0.05, 0.65)) * 36
        opacity: root.seg(0.05, 0.65)
        spacing: 4
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(Clock.date, Config.timeFormat)
            font.pixelSize: 96
            font.weight: Font.DemiBold
        }
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(Clock.date, Config.dateFormat)
            font.pixelSize: 20
            color: Theme.fgDim
        }
    }

    // ---- password pill ----
    Rectangle {
        id: pill
        width: 340; height: 58
        radius: height / 2
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.58 + (1 - root.seg(0.3, 0.9)) * 28
        opacity: root.seg(0.3, 0.8)
        color: Theme.bg
        border.width: 2
        border.color: Lock.leaving ? Theme.primary : (Lock.error !== "" ? Theme.error : (input.activeFocus ? Theme.primary : Theme.outline))
        Behavior on border.color { ColorAnimation { duration: 180 } }

        // springs open once the page has faded in, pops on a correct password
        scale: Lock.leaving ? 1.06 : (root.p > 0.5 ? 1.0 : 0.88)
        Behavior on scale { SpringAnimation { spring: 5; damping: 0.42; epsilon: 0.002 } }

        Rectangle {
            id: chip
            x: 9
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height - 18; height: width; radius: width / 2
            color: Lock.error !== "" && !Lock.leaving ? Theme.error : Theme.primary
            Behavior on color { ColorAnimation { duration: 180 } }
            scale: input.activeFocus ? 1.0 : 0.94
            Behavior on scale { SpringAnimation { spring: 7; damping: 0.5; epsilon: 0.002 } }

            Icon {
                id: chipIcon
                anchors.centerIn: parent
                name: Lock.leaving ? "lock_open" : (Lock.busy ? "hourglass_top" : "lock")
                size: 22
                weight: 500
                color: Theme.primaryFg
                // swap glyphs with a quick squash
                onNameChanged: swap.restart()
                SequentialAnimation {
                    id: swap
                    NumberAnimation { target: chipIcon; property: "scale"; to: 0.5; duration: 80 }
                    NumberAnimation { target: chipIcon; property: "scale"; to: 1.0; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
                }
            }
        }

        // prompt text (when nothing is typed)
        Txt {
            anchors.left: chip.right; anchors.leftMargin: 14
            anchors.right: parent.right; anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            opacity: Lock.typed.length === 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 140 } }
            text: Lock.leaving ? "Welcome back" : (Lock.busy ? "Checking…" : (Lock.error !== "" ? Lock.error : "Enter password"))
            color: Lock.error !== "" && !Lock.leaving ? Theme.error : Theme.fgDim
            font.pixelSize: 15
        }

        // dots pop in as you type
        Row {
            anchors.left: chip.right; anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7
            Repeater {
                model: Math.min(Lock.typed.length, 16)
                Rectangle {
                    id: dot
                    width: 10; height: 10; radius: 5
                    color: Theme.fg
                    scale: 0
                    Component.onCompleted: scale = 1
                    Behavior on scale { SpringAnimation { spring: 9; damping: 0.4; epsilon: 0.002 } }
                }
            }
        }

        TextInput {
            id: input
            anchors.fill: parent
            opacity: 0
            focus: true
            echoMode: TextInput.Password
            enabled: !Lock.busy && !Lock.leaving
            onTextChanged: { if (Lock.typed !== text) Lock.typed = text; if (text.length > 0 && Lock.error !== "") Lock.error = "" }
            onAccepted: Lock.attempt(text)
            Keys.onEscapePressed: text = ""
            Component.onCompleted: forceActiveFocus()
        }

        // wrong password: shake
        SequentialAnimation {
            id: shake
            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: -16; duration: 50 }
            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: 16; duration: 90 }
            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: -10; duration: 80 }
            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: 0; duration: 70 }
        }
    }

    Connections {
        target: Lock
        function onFailed() { shake.restart(); input.text = ""; input.forceActiveFocus() }
        function onTypedChanged() { if (input.text !== Lock.typed) input.text = Lock.typed }
        function onLockedChanged() { if (Lock.locked) input.forceActiveFocus() }
    }

    // clicking anywhere gives the field focus back
    MouseArea { anchors.fill: parent; z: -1; onClicked: input.forceActiveFocus() }
}
