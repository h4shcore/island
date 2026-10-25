pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    signal trackChanged()

    function pick() {
        const v = Mpris.players.values
        for (let i = 0; i < v.length; i++)
            if (v[i].isPlaying) return v[i]
        return v.length > 0 ? v[0] : null
    }

    readonly property var active: pick()

    Connections {
        target: root.active
        function onTrackTitleChanged() {
            if (root.active && root.active.isPlaying && root.active.trackTitle !== "")
                root.trackChanged()
        }
    }
}
