import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Wayland
import "root:/utils"

Item {
    id: root
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    // width: content.implicitWidth
    // height: parent.height

    property var screen

    Text {
        id: content
        text: Hyprland.activeToplevel.title
        anchors.centerIn: parent

        MouseArea {
            anchors.fill: parent
            onClicked: {
                popup.requestOpen = !popup.requestOpen;
            }
        }
    }

    PopupWrapper {
        id: popup
        screen: root.screen
        requestOpen: false
        anchors.top: root.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        GridLayout {
            columns: 3
            Repeater {
                model: Hyprland.toplevels

                Item {
                    id: window
                    property var toplevel: modelData
                    width: 300
                    height: 200
                    clip: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            window.toplevel.wayland.activate();
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent

                        ScreencopyView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            captureSource: window.toplevel.wayland
                            live: true
                        }

                        Text {
                            text: window.toplevel.title
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }
    }

    PopupEdges {
        popout: popup
        anchors.top: root.bottom
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
