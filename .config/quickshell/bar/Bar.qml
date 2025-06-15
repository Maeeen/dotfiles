import "root:/config"
import "root:/widgets"
import "root:/serv"
import "root:/groups"
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window
        property var modelData
        color: "transparent"
        screen: modelData
        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 30

        Rectangle {
            id: gradient
            gradient: Colors.backgrounds.gradient
            anchors.fill: parent
        }

    Text {
        text: Hyprland.clients.values.filter(s => s.active)[0].title + " windows"
    }

        RowLayout {
            anchors.fill: parent
            Left {
                currentScreen: modelData
                Layout.alignment: Qt.AlignLeft
            }
            Item {
                Layout.fillWidth: true
            }
            Center {
                Layout.alignment: Qt.AlignCenter
            }
            Item {
                Layout.fillWidth: true
            }
            Right {
                Layout.alignment: Qt.AlignRight
            }
        }
    }
}
