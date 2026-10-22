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

        Region {
            id: panelRegion
            item: notifPanel.panel
        }

        mask: Region {
            regions: [baseRegion, panelRegion, ...regions.instances]
        }

        implicitHeight: modelData.height

        // First child, so it is under the bar and its popups
        NotifPanel {
            id: notifPanel
            shown: Notifs.panelOpen && window.screen === Notifs.screen
            anchors.right: parent.right
            y: barHeight
            height: window.height - barHeight
        }

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
                    Layout.fillHeight: true

                    // Workaround for a Qt 6.12 bug: RowLayout wrongly caches that all its children
                    // stay in its bounds, so it drops hover events on popups below the bar.
                    // The margin puts this item out of bounds, which stops the wrong caching.
                    HoverHandler {
                        margin: 1
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Item {
                    Layout.fillWidth: true
                }

                Right {
                    currentScreen: modelData
                    Layout.alignment: Qt.AlignRight

                    // Same Qt 6.12 workaround as on Left.
                    HoverHandler {
                        margin: 1
                    }
                }
            }

            Center {
                currentScreen: modelData
                anchors.centerIn: parent
            }
        }
    }
}
