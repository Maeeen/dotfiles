import "root:/config"
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    Layout.preferredWidth: content.width
    implicitHeight: parent.height

    RowLayout {
        id: content
        anchors.centerIn: parent
        Repeater {
            model: SystemTray.items

            Item {
                id: menuRoot
                width: icon.width + 8
                height: 16

                IconImage {
                    id: icon
                    width: 16
                    height: width
                    source: modelData.icon
                }

                QsMenuOpener {
                    id: menuopener
                    menu: modelData.menu
                }
            }
        }
    }
}
