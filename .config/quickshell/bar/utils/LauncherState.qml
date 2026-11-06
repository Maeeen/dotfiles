pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

// State of the app launcher. Super+T opens it on the focused monitor
// (hyprland.conf: bind = $mainMod, T, global, quickshell:launcher).
Singleton {
    id: root

    // Name of the screen where the launcher is open, "" when it is closed
    property string screenName: ""

    function toggle() {
        screenName = screenName ? "" : (Hyprland.focusedMonitor?.name ?? "");
    }

    function close() {
        screenName = "";
    }

    GlobalShortcut {
        name: "launcher"
        description: "Open or close the app launcher"
        onPressed: root.toggle()
    }
}
