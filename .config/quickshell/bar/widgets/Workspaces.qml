import "root:/config"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
    required property ShellScreen screen

    Text {
        Layout.leftMargin: 10
        font.pointSize: Colors.text.fontSize
        color: Colors.text.color
    }

    Repeater {
        model: Hyprland.workspaces.values.filter(s => s != null && s.monitor != null && s.id > 0).filter(workspace => workspace.monitor.name === screen.name)

        WorkspaceItem {}
    }

    component WorkspaceItem: Item {
        required property HyprlandWorkspace modelData
        property bool urgent: modelData.urgent
        property bool active: mouseArea.containsMouse || modelData.active
        property int circleSize: active ? 16 : 12
        property real textOpacity: active ? 1 : 0.4
        property real textSize: active ? 10 : 5

        Behavior on circleSize {
            NumberAnimation {
                duration: 100
                easing.type: Easing.InOutQuad
            }
        }
        Behavior on textSize {
            NumberAnimation {
                duration: 100
                easing.type: Easing.InOutQuad
            }
        }
        Behavior on textOpacity {
            NumberAnimation {
                duration: 100
                easing.type: Easing.InOutQuad
            }
        }

        height: 16
        width: circleSize
        Layout.preferredWidth: circleSize

        Rectangle {
            id: rect
            anchors.centerIn: parent
            width: circleSize
            height: circleSize
            color: urgent ? Colors.workspaceCircleUrgent : (active ? Colors.workspaceCircleActive : Colors.workspaceCircle)
            radius: width / 2

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: function () {
                    modelData.activate();
                }
            }

            Text {
                opacity: textOpacity
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignRight
                text: modelData.id
                color: active ? Colors.workspaceTextActive : Colors.workspaceText
                font.pointSize: textSize
            }
        }
    }
}
