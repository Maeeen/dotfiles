pragma Singleton

import Quickshell

Singleton {
    id: root

    readonly property real barHeight: 35
    // Time in ms before a popup closes after the mouse leaves it
    readonly property int popupCloseDelay: 300
    // Background of the lock screen, blurred
    readonly property string lockWallpaper: "/home/maeeen/wallpapers/kawai.jpg"
    // Backlight device of the laptop panel. The other monitors use DDC/CI (ddcutil).
    readonly property string backlight: "/sys/class/backlight/intel_backlight"
    readonly property string laptopScreen: "eDP-1"
    // Thunderbird folder: the calendar shows the events of the calendar cache of its default profile
    readonly property string thunderbirdDir: "/home/maeeen/.thunderbird"
}
