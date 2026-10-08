pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

/**
 * Notifications — the one NotificationServer in the shell.
 *
 * Owns the D-Bus name org.freedesktop.Notifications. A notification is only
 * kept if `tracked` is set to true in the `notification` handler — otherwise
 * the server discards it and every later property read returns undefined.
 *
 * Exposed:
 *   list   — live notifications, newest last (ObjectModel values)
 *   count  — list.length
 *   dismissAll()
 */
Singleton {
    id: root

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true
            console.log("Notifications: got " + n.appName + " — " + n.summary)
            // A toast only makes sense when the list is not already on screen
            if (!root._panelOpen) root.toast = n
        }
    }

    readonly property var list:  server.trackedNotifications.values
    readonly property int count:  list.length

    // Toast — the newest notification, shown briefly then auto-cleared.
    property var toast: null
    // Set by the bar module so a toast never fights an open panel.
    property bool _panelOpen: false
    function clearToast() { root.toast = null }

    function dismissAll() {
        const live = server.trackedNotifications.values.slice()
        for (let i = 0; i < live.length; i++) live[i].dismiss()
    }
}