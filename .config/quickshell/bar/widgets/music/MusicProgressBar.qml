import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "root:/utils"
import "root:/config"

RowLayout {
    property MprisPlayer player
    height: 20

    HoverHandler {
        id: hover
    }

    function formatDuration(seconds) {
        return `${Math.floor(seconds / 60).toString().padStart(1, '0')}:${(Math.floor(seconds) % 60).toString().padStart(2, '0')}`;
    }

    Text {
        text: parent.formatDuration(root.player.position)
        color: Colors.text.color
    }

    Item {
        id: sliderWhole
        property MouseEvent lastMouseEvent: null

        Layout.fillWidth: true
        Layout.preferredHeight: 14
        MouseArea {
            id: oops
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: function (m) {
                sliderWhole.lastMouseEvent = m;
                if (oops.containsPress) updatePosition();
            }
            onClicked: {
                updatePosition();
            }

            function updatePosition() {
                if (root.player.positionSupported) {
                    const newPosition = (sliderWhole.lastMouseEvent.x / parent.width) * root.player.length;
                    root.player.position = newPosition;
                }
            }
        }
        Rectangle {
            color: Colors.c("#ffffff69")
            height: 3
            topLeftRadius: 3
            topRightRadius: 3
            bottomLeftRadius: 3
            bottomRightRadius: 3
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
        }

        Rectangle {
            id: left
            color: Colors.c("#ffffffff")
            height: 3
            topLeftRadius: 3
            topRightRadius: 3
            bottomLeftRadius: 3
            bottomRightRadius: 3
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            width: (root.player.position / root.player.length) * parent.width
        }

        Rectangle {
            id: ball
            Layout.preferredHeight: 3
            width: hover.hovered ? 6 : 0
            height: hover.hovered ? 6 : 0
            color: Colors.c("#ffffffff")
            radius: 3
            anchors.verticalCenter: left.verticalCenter
            anchors.left: left.right

            Behavior on height {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }

            Behavior on width {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    Text {
        text: parent.formatDuration(root.player.length)
        color: Colors.text.color
    }
}
