import QtQuick
import QtQuick.Effects
import qs.config

// Rounded cover art / notification image with icon fallback
Item {
    id: root

    property url source
    property real radius: 8
    property string fallback: "music_note"

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Theme.surfaceHi
        visible: img.status !== Image.Ready

        Icon {
            anchors.centerIn: parent
            name: root.fallback
            size: Math.round(root.height * 0.55)
            color: Theme.fgDim
        }
    }

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        visible: false
        sourceSize.width: 192
        sourceSize.height: 192
    }

    MultiEffect {
        anchors.fill: parent
        source: img
        maskEnabled: true
        maskSource: mask
        visible: img.status === Image.Ready
    }

    Item {
        id: mask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle { anchors.fill: parent; radius: root.radius }
    }
}
