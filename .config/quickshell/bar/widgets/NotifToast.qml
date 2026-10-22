import "root:/config"
import "root:/serv"
import "root:/utils"
import "root:/widgets/notifs"
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Pop-up for a new notification, drops down from the middle of the bar
Item {
    id: root
    property var screen
    // Card on screen; it stays while the pop-up closes
    property Item current: null

    implicitHeight: parent.height

    Connections {
        target: Notifs
        function onToastChanged() {
            if (!Notifs.toast)
                return;
            const card = cardComponent.createObject(stack, {
                notification: Notifs.toast
            });
            const old = root.current;
            root.current = card;
            if (!old)
                return;
            if (!popup.opened) {
                old.destroy();
                return;
            }
            // Open: the old card moves down and fades, the new one comes from the top
            old.enabled = false;
            old.y = stack.height;
            old.opacity = 0;
            old.destroy(300);
            card.animate = false;
            card.y = -card.height;
            card.opacity = 0;
            card.animate = true;
            card.y = 0;
            card.opacity = 1;
        }
    }

    Component {
        id: cardComponent

        NotifCard {
            property bool animate: true

            width: stack.width
            // Dark, so the text is easy to read on the bar color; a bit lighter on hover
            color: notification?.urgency === NotificationUrgency.Critical ? Colors.workspaceCircleUrgent : (hover.hovered ? Qt.tint(Colors.backgrounds.panel, Qt.rgba(1, 1, 1, 0.08)) : Colors.backgrounds.panel)
            onCloseClicked: {
                Notifs.toast = null;
                popup.close();
            }

            HoverHandler {
                id: hover
            }

            Behavior on color {
                ColorAnimation {
                    duration: 150
                    easing.type: Easing.InOutQuad
                }
            }

            Behavior on y {
                enabled: animate
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                enabled: animate
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    PopupWrapper {
        id: popup
        requestOpen: Notifs.toast !== null && root.screen === Notifs.screen
        anchors.top: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        screen: root.screen

        Item {
            id: stack
            width: 400
            height: root.current?.height ?? 0
        }
    }
}
