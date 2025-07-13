import "root:/config"
import "root:/widgets"
import "root:/serv"
import "root:/groups"
import "root:/utils"
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Variants {
    property real barHeight: Config.barHeight
    model: Quickshell.screens

    PanelWindow {
        id: window
        property var modelData

        color: "transparent"
        screen: modelData
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            left: true
            right: true
        }

        Region {
            id: baseRegion
            item: Rectangle {
                width: window.width
                height: barHeight
            }
        }

        Variants {
            id: regions
            model: PopupsState.popups[window.screen] || []
            Region {
                required property Item modelData
                item: modelData
            }
        }

        mask: Region {
            regions: [baseRegion, ...regions.instances]
        }

        implicitHeight: modelData.height

        Rectangle {
            id: gradient
            gradient: Colors.backgrounds.gradient
            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: barHeight
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    Colors.hovered = true;
                } else {
                    Colors.hovered = false;
                }
            }
        }

        Item {
            width: parent.width
            height: barHeight

            RowLayout {
                anchors.fill: parent
                height: barHeight

                Left {
                    currentScreen: modelData
                    Layout.alignment: Qt.AlignLeft
                }

                Item {
                    Layout.fillWidth: true
                }

                Item {
                    Layout.fillWidth: true
                }

                Right {
                    Layout.alignment: Qt.AlignRight
                }
            }

            Center {
                currentScreen: modelData
                anchors.centerIn: parent
            }
        }
    }
}
