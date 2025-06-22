import "root:/widgets"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    implicitHeight: parent.height
    Text {
        text: Hyprland.activeToplevel.title
    }
    ClockWidget {}
}
