import QtQuick
import qs.config

// Material Symbols ligature icon (needs "Material Symbols Rounded", Qt >= 6.7 for filled)
Text {
    property string name: ""
    property int size: 20
    property bool filled: false

    text: name
    color: Theme.fg
    font.family: Theme.iconFont
    font.pixelSize: size
    font.variableAxes: ({ "FILL": filled ? 1 : 0 })
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
