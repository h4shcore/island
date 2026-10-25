//@ pragma UseQApplication
import QtQuick
import Quickshell
import qs.services
import qs.ipc
import qs.modules.island

ShellRoot {
    Component.onCompleted: Clip.refresh()      // also instantiates Clip so its watchers start

    // one island per screen
    Variants {
        model: Quickshell.screens
        Island {
            required property var modelData
            screen: modelData
        }
    }

    Ipc {}
}
