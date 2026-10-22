import "root:/config"
import QtQuick

// Button that asks "Sure?" on the first click and emits `confirmed` on the second.
// It goes back to normal when the mouse leaves, or after 1 s.
Rectangle {
    id: root
    // "lock", "logout", "reboot", "softreboot" or "power"
    property string icon
    property color iconColor: Colors.text.color
    property color sureColor: Colors.text.danger
    property string text
    property bool asking: false
    signal confirmed

    // Width does not depend on the shown text, so "Sure?" does not resize the button
    implicitWidth: Math.max(labelMetrics.width, sureMetrics.width, 18) + 24
    implicitHeight: 60
    radius: 8
    color: Colors.workspaceCircle

    Column {
        id: column
        anchors.centerIn: parent
        spacing: 6

        SessionIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: root.icon
            color: root.iconColor
        }

        Text {
            id: label
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.asking ? "Sure?" : root.text
            color: root.asking ? root.sureColor : Colors.text.color
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }
    }

    TextMetrics {
        id: labelMetrics
        font: label.font
        text: root.text
    }

    TextMetrics {
        id: sureMetrics
        font: label.font
        text: "Sure?"
    }

    Timer {
        id: reset
        interval: 1000
        onTriggered: root.asking = false
    }

    HoverArea {
        anchors.fill: parent
        onExited: root.asking = false
        onClicked: {
            if (root.asking) {
                root.asking = false;
                reset.stop();
                root.confirmed();
            } else {
                root.asking = true;
                reset.restart();
            }
        }
    }
}
