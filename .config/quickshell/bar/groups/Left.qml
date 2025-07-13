import "root:/widgets"
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
    implicitHeight: parent.height
    required property ShellScreen currentScreen
    Workspaces {
        screen: currentScreen
    }
    Music {
        screen: currentScreen
    }
}
