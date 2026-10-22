import "root:/widgets"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
    implicitHeight: parent.height
    required property ShellScreen currentScreen

    Tray {
        screen: currentScreen

        // Same Qt 6.12 workaround as in Bar.qml: this RowLayout also caches that its
        // children stay in its bounds, and drops hover events on the tray popup.
        HoverHandler {
            margin: 1
        }
    }
    Audio {
        screen: currentScreen

        // Same Qt 6.12 workaround as on Tray.
        HoverHandler {
            margin: 1
        }
    }
    Bluetooth {
        screen: currentScreen

        // Same Qt 6.12 workaround as on Tray.
        HoverHandler {
            margin: 1
        }
    }
    SysStats {}
    Battery {}
    ClockWidget {}
}
