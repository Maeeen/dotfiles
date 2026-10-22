import "root:/config"
import "root:/utils"
import "root:/widgets/tray"
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // Tray item whose menu is open, and the submenus entered from it
    property SystemTrayItem openItem: null
    property var menuStack: []
    property var screen
    // Largest menu size since the menu opened. Submenus never make the popup smaller,
    // so the mouse stays on the popup and it does not close.
    property real menuMinWidth: 0
    property real menuMinHeight: 0
    // Popup size before each submenu opened, so "Back" gives the parent menu its size again
    property var menuSizeStack: []

    Layout.preferredWidth: content.width
    implicitHeight: parent.height

    function toggleMenu(item) {
        if (openItem === item) {
            openItem = null;
        } else {
            openItem = item;
            menuStack = [item.menu];
            menuSizeStack = [];
            menuMinWidth = 0;
            menuMinHeight = 0;
        }
    }

    // Close the menu when the mouse is on neither the tray nor the popup
    property bool hovered: trayHover.hovered || popupHover.hovered
    onHoveredChanged: {
        if (hovered) {
            closeDelay.stop();
        } else if (openItem !== null) {
            closeDelay.restart();
        }
    }

    Timer {
        id: closeDelay
        // Give the mouse time to move from the tray to the popup
        interval: Config.popupCloseDelay
        onTriggered: root.openItem = null
    }

    RowLayout {
        id: content
        anchors.centerIn: parent

        HoverHandler {
            id: trayHover
        }

        Repeater {
            model: SystemTray.items

            Item {
                id: menuRoot
                width: icon.width + 8
                height: 16

                IconImage {
                    id: icon
                    anchors.centerIn: parent
                    width: 16
                    height: width
                    source: modelData.icon
                }

                HoverArea {
                    anchors.centerIn: parent
                    width: parent.width
                    height: root.height
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: function (mouse) {
                        if (mouse.button === Qt.MiddleButton) {
                            modelData.secondaryActivate();
                        } else if (modelData.hasMenu && (mouse.button === Qt.LeftButton || modelData.onlyMenu)) {
                            root.toggleMenu(modelData);
                        } else {
                            modelData.activate();
                        }
                    }
                }
            }
        }
    }

    QsMenuOpener {
        id: opener
        menu: root.menuStack.length ? root.menuStack[root.menuStack.length - 1] : null
    }

    // Keeps every menu of the stack open. Quickshell unloads a menu that no opener holds,
    // and that deletes its entries, so a submenu would disappear when the opener above
    // moves from the parent to it. ScriptModel keeps the existing openers.
    Instantiator {
        model: ScriptModel {
            values: root.menuStack
        }

        QsMenuOpener {
            required property QsMenuHandle modelData
            menu: modelData
        }
    }

    PopupWrapper {
        id: popup
        requestOpen: root.openItem !== null
        anchors.right: content.right
        anchors.top: content.bottom
        anchors.topMargin: (root.height - content.height) / 2
        screen: root.screen

        ColumnLayout {
            spacing: 2
            width: Math.max(implicitWidth, root.menuMinWidth)
            height: Math.max(implicitHeight, root.menuMinHeight)
            onImplicitWidthChanged: root.menuMinWidth = Math.max(root.menuMinWidth, implicitWidth)
            onImplicitHeightChanged: root.menuMinHeight = Math.max(root.menuMinHeight, implicitHeight)

            MenuRow {
                id: backRow
                Layout.fillWidth: true
                visible: root.menuStack.length > 1
                label: "‹ Back"
                hovered: root.isUnderMouse(backRow)
                onClicked: {
                    // Change the menu first: the submenu content must be gone before the size is set
                    root.menuStack = root.menuStack.slice(0, -1);
                    const size = root.menuSizeStack[root.menuSizeStack.length - 1];
                    root.menuSizeStack = root.menuSizeStack.slice(0, -1);
                    root.menuMinWidth = size.width;
                    root.menuMinHeight = size.height;
                }
            }

            Repeater {
                model: opener.children

                Item {
                    id: entryRoot
                    required property QsMenuEntry modelData
                    Layout.fillWidth: true
                    implicitWidth: modelData.isSeparator ? 0 : row.implicitWidth
                    implicitHeight: modelData.isSeparator ? 5 : row.implicitHeight

                    Rectangle {
                        visible: entryRoot.modelData.isSeparator
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 1
                        color: Colors.workspaceCircle
                    }

                    MenuRow {
                        id: row
                        visible: !entryRoot.modelData.isSeparator
                        width: parent.width
                        entry: entryRoot.modelData
                        label: entryRoot.modelData.text
                        hovered: root.isUnderMouse(row)
                        onClicked: {
                            if (entry.hasChildren) {
                                root.menuSizeStack = root.menuSizeStack.concat([{ width: root.menuMinWidth, height: root.menuMinHeight }]);
                                root.menuStack = root.menuStack.concat([entry]);
                            } else {
                                entry.triggered();
                                root.openItem = null;
                            }
                        }
                    }
                }
            }

            // Takes the extra height, so the rows stay at the top
            Item {
                Layout.fillHeight: true
            }
        }
    }

    // A menu row is lit when the mouse position of the popup HoverHandler is in it.
    // Qt can lose the enter and leave events of the rows, so they do not use their own hover state.
    function isUnderMouse(item) {
        if (!popupHover.hovered)
            return false;
        return item.contains(item.mapFromItem(popupCover, popupHover.point.position));
    }

    // Covers the popup with its margins, without taking the clicks
    Item {
        id: popupCover
        anchors.fill: popup

        HoverHandler {
            id: popupHover
        }
    }
}
