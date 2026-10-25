pragma Singleton
import QtQuick
import Quickshell

// One shared wall clock for every view.
Singleton {
    readonly property alias date: sc.date
    SystemClock { id: sc; precision: SystemClock.Seconds }
}
