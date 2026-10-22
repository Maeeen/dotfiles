import "root:/config"
import "root:/serv"
import "root:/utils"
import "root:/widgets"
import "root:/widgets/notifs"
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Side panel with all notifications, slides in from the right.
// It is in the bar window (not its own window), so the bar popups stay above it.
Item {
    id: root

    // Open on this screen
    property bool shown: Notifs.panelOpen
    readonly property Item panel: panel

    implicitWidth: 400

    // Stay visible until the slide-out is done
    visible: shown || panel.x < panel.width

    Rectangle {
        id: panel
        width: parent.width
        height: parent.height
        x: root.shown ? 0 : width
        color: Colors.backgrounds.panel

        Behavior on x {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10

            RowLayout {
                Text {
                    Layout.fillWidth: true
                    text: "Notifications"
                    font.bold: true
                    color: Colors.text.color
                    font.pointSize: Colors.text.fontSize
                    font.family: Colors.text.fontFamily
                }

                GhostButton {
                    visible: Notifs.list.length > 0
                    text: "Clear all"
                    onClicked: Notifs.clear()
                }

                GhostButton {
                    text: "×"
                    onClicked: Notifs.panelOpen = false
                }
            }

            // The list, and the empty text on top of it. The text is not in the layout,
            // so it does not push the list down while the cards slide out.
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: list
                    anchors.fill: parent
                    clip: true
                    spacing: 8

                    // Newest first; ScriptModel keeps delegates, so the transitions below run
                    model: ScriptModel {
                        values: [...Notifs.list].reverse()
                    }

                    delegate: NotifCard {
                        required property Notification modelData
                        width: list.width
                        notification: modelData
                        onCloseClicked: modelData.dismiss()
                    }

                    add: Transition {
                        NumberAnimation {
                            property: "x"
                            from: list.width
                            to: 0
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }

                    remove: Transition {
                        NumberAnimation {
                            property: "x"
                            to: list.width
                            duration: 200
                            easing.type: Easing.InCubic
                        }
                    }

                    displaced: Transition {
                        NumberAnimation {
                            property: "y"
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 20
                    // Fades in slowly at first, so it shows after the cards have left
                    opacity: Notifs.list.length === 0 ? 1 : 0
                    visible: opacity > 0
                    text: "No notifications"
                    color: Colors.text.secondary
                    font.pointSize: Colors.text.fontSize
                    font.family: Colors.text.fontFamily

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.InCubic
                        }
                    }
                }
            }

            SbbClock {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                size: 180
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 10
                text: Time.date
                color: Colors.text.secondary
                font.pointSize: Colors.text.fontSize
                font.family: Colors.text.fontFamily
            }

            // Stay awake: inhibits idle, so hypridle does not lock the screen
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: 8
                color: Idle.inhibit ? Colors.workspaceCircleActive : Colors.workspaceCircle

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                        easing.type: Easing.InOutQuad
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    SessionIcon {
                        name: "awake"
                        color: Idle.inhibit ? Colors.text.activeColor : Colors.text.color
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Stay awake"
                        color: Colors.text.color
                        font.pointSize: Colors.text.fontSize
                        font.family: Colors.text.fontFamily
                    }

                    Text {
                        text: Idle.inhibit ? "On" : "Off"
                        color: Idle.inhibit ? Colors.text.activeColor : Colors.text.secondary
                        font.pointSize: Colors.text.fontSize
                        font.family: Colors.text.fontFamily
                        font.weight: Font.Medium
                    }
                }

                HoverArea {
                    anchors.fill: parent
                    radius: parent.radius
                    onClicked: Idle.inhibit = !Idle.inhibit
                }

                IdleInhibitor {
                    window: root.QsWindow.window
                    enabled: Idle.inhibit
                }
            }

            // Session: each button asks for confirmation first
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                ConfirmButton {
                    Layout.fillWidth: true
                    icon: "lock"
                    iconColor: Colors.text.warning
                    sureColor: Colors.text.warning
                    text: "Lock"
                    onConfirmed: {
                        Notifs.panelOpen = false;
                        Quickshell.execDetached(["loginctl", "lock-session"]);
                    }
                }

                ConfirmButton {
                    Layout.fillWidth: true
                    icon: "logout"
                    text: "Log out"
                    onConfirmed: Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
                }

                ConfirmButton {
                    Layout.fillWidth: true
                    icon: "power"
                    iconColor: Colors.text.danger
                    text: "Power off"
                    onConfirmed: Quickshell.execDetached(["systemctl", "poweroff"])
                }

                ConfirmButton {
                    Layout.fillWidth: true
                    icon: "reboot"
                    text: "Reboot"
                    onConfirmed: Quickshell.execDetached(["systemctl", "reboot"])
                }

                ConfirmButton {
                    Layout.fillWidth: true
                    icon: "softreboot"
                    text: "Soft reboot"
                    onConfirmed: Quickshell.execDetached(["systemctl", "soft-reboot"])
                }
            }
        }
    }
}
