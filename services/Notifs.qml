pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// NOTE: only one notification daemon can own org.freedesktop.Notifications.
// Stop mako/swaync/other shells' servers before running this.
Singleton {
    id: root

    property string title: ""
    property string body: ""
    property string app: ""
    property string image: ""
    property bool critical: false
    property var current: null
    property bool dnd: false
    signal arrived()

    // recent notifications for the control center, newest first.
    // each entry: { app, title, body, image, critical, time }
    property var history: []
    readonly property int historyMax: 30

    function remember(entry) {
        history = [entry].concat(history).slice(0, historyMax)
    }
    function dismissAt(i) { history = history.filter((_, j) => j !== i) }
    function clearHistory() { history = [] }

    function clear() {
        if (current) {
            try { current.dismiss() } catch (e) {}
            current = null
        }
    }

    NotificationServer {
        keepOnReload: true
        bodySupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true

            let img = n.image
            if (!img && n.appIcon)
                img = n.appIcon.startsWith("/") ? n.appIcon : Quickshell.iconPath(n.appIcon, true)

            // logged in the control center even when Focus swallows the banner
            root.remember({
                app: n.appName,
                title: n.summary,
                body: n.body,
                image: img ?? "",
                critical: n.urgency === NotificationUrgency.Critical,
                time: Date.now()
            })

            if (root.dnd && n.urgency !== NotificationUrgency.Critical) {
                n.dismiss()
                return
            }
            root.clear()
            root.current = n
            root.title = n.summary
            root.body = n.body
            root.app = n.appName
            root.critical = n.urgency === NotificationUrgency.Critical
            root.image = img ?? ""
            root.arrived()
        }
    }
}
