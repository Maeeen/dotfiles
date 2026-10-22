pragma Singleton

import Quickshell

// "Stay awake": when on, the bar inhibits idle, so hypridle does not dim, lock or suspend.
Singleton {
    id: root

    property alias inhibit: persist.inhibit

    // Keeps the state when the config reloads
    PersistentProperties {
        id: persist
        reloadableId: "idleInhibit"
        property bool inhibit: false
    }
}
