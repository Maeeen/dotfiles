import "root:/widgets"
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
    required property ShellScreen currentScreen;
    Workspaces { screen: currentScreen }
}
