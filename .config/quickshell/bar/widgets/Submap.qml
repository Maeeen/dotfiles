import "root:/config"
import "root:/utils"
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// Name of the active Hyprland submap (for example "resize"), in a pill.
// Hidden when no submap is active.
Item {
    id: root
    property string submap: ""
    // Last name, kept while the pill shrinks out
    property string name: ""

    // Grows in and shrinks out: hidden only when the width is 0
    readonly property bool shown: submap !== ""
    readonly property real fullWidth: pill.width + 8
    visible: Layout.preferredWidth > 0
    opacity: shown ? 1 : 0
    Layout.preferredWidth: shown ? fullWidth : 0
    // Takes the layout spacing away while it shrinks, so the next items do not jump at the end
    Layout.leftMargin: parent.spacing * (Layout.preferredWidth / fullWidth - 1)
    Layout.fillHeight: true
    clip: true

    Behavior on Layout.preferredWidth {
        WidthAnimation {}
    }

    Behavior on opacity {
        WidthAnimation {}
    }

    Connections {
        target: Hyprland
        // data is the submap name, or "" when the submap is reset
        function onRawEvent(event) {
            if (event.name !== "submap")
                return;
            root.submap = event.data;
            if (event.data)
                root.name = event.data;
        }
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: label.implicitWidth + 16
        height: 18
        radius: height / 2
        color: Colors.workspacePill

        Text {
            id: label
            anchors.centerIn: parent
            text: root.name
            color: Colors.workspaceNumber
            font.pointSize: 9
            font.bold: true
            font.family: Colors.text.fontFamily
        }
    }
}
