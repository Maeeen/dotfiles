import "root:/widgets"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    property var currentScreen
    implicitHeight: parent.height
    HyprWindowPicker {
        screen: currentScreen
    }
}
