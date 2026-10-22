pragma Singleton

import Quickshell

Singleton {
    id: root

    readonly property real barHeight: 35
    // Time in ms before a popup closes after the mouse leaves it
    readonly property int popupCloseDelay: 300
    // Background of the lock screen, blurred
    readonly property string lockWallpaper: "/home/maeeen/wallpapers/kawai.jpg"
}
