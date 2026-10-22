pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    property list<Notification> list: server.trackedNotifications.values
    property bool panelOpen: false
    // Notification shown in the pop-up, null when none
    property Notification toast: null
    // The panel and the pop-up open on the focused monitor
    property ShellScreen screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    function clear() {
        // Copy first, because dismiss() removes the notification from the list
        for (const n of [...root.list])
            n.dismiss();
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: function (n) {
            n.tracked = true;
            n.closed.connect(() => {
                if (root.toast === n)
                    root.toast = null;
            });
            root.toast = n;
            toastTimer.restart();
        }
    }

    // Hide the pop-up after 5 s; it stays open while the mouse is on it
    Timer {
        id: toastTimer
        interval: 5000
        onTriggered: root.toast = null
    }
}
