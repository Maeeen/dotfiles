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

    onShownChanged: {
        if (shown) {
            CalendarEvents.refresh();
            calendar.reset();
        }
    }

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
                    color: Colors.panelText.color
                    font.pointSize: Colors.panelText.fontSize
                    font.family: Colors.panelText.fontFamily
                }

                GhostButton {
                    textColor: Colors.panelText.color
                    visible: Notifs.list.length > 0
                    text: "Clear all"
                    onClicked: Notifs.clear()
                }

                GhostButton {
                    textColor: Colors.panelText.color
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
                    color: Colors.panelText.secondary
                    font.pointSize: Colors.panelText.fontSize
                    font.family: Colors.panelText.fontFamily

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.InCubic
                        }
                    }
                }
            }

            MonthCalendar {
                id: calendar
                Layout.fillWidth: true
                Layout.topMargin: 10
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
                color: Colors.panelText.secondary
                font.pointSize: Colors.panelText.fontSize
                font.family: Colors.panelText.fontFamily
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
                        color: Idle.inhibit ? Colors.panelText.activeColor : Colors.panelText.color
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Stay awake"
                        color: Colors.panelText.color
                        font.pointSize: Colors.panelText.fontSize
                        font.family: Colors.panelText.fontFamily
                    }

                    Text {
                        text: Idle.inhibit ? "On" : "Off"
                        color: Idle.inhibit ? Colors.panelText.activeColor : Colors.panelText.secondary
                        font.pointSize: Colors.panelText.fontSize
                        font.family: Colors.panelText.fontFamily
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

            // Theme: a click selects the next theme; "Edit…" opens the settings window
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: 8
                color: Colors.workspaceCircle

                // Under the row, so the "Edit…" button gets its own clicks
                HoverArea {
                    anchors.fill: parent
                    radius: parent.radius
                    onClicked: Theme.next()
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 6
                    spacing: 8

                    // Half-filled circle in the bar gradient
                    Rectangle {
                        implicitWidth: 16
                        implicitHeight: 16
                        radius: 8
                        border.width: 1.5
                        border.color: Colors.panelText.color
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                position: 0
                                color: Theme.current.barStart
                            }
                            GradientStop {
                                position: 1
                                color: Theme.current.barEnd
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Theme"
                        color: Colors.panelText.color
                        font.pointSize: Colors.panelText.fontSize
                        font.family: Colors.panelText.fontFamily
                    }

                    Text {
                        text: Theme.name
                        color: Colors.panelText.secondary
                        font.pointSize: Colors.panelText.fontSize
                        font.family: Colors.panelText.fontFamily
                        font.weight: Font.Medium
                    }

                    Rectangle {
                        implicitWidth: editText.implicitWidth + 16
                        implicitHeight: 24
                        radius: 6
                        color: Colors.workspaceCircle

                        Text {
                            id: editText
                            anchors.centerIn: parent
                            text: "Edit…"
                            color: Colors.panelText.color
                            font.pointSize: Colors.panelText.fontSize - 1
                            font.family: Colors.panelText.fontFamily
                        }

                        HoverArea {
                            anchors.fill: parent
                            radius: parent.radius
                            onClicked: {
                                Notifs.panelOpen = false;
                                Theme.settingsOpen = true;
                            }
                        }
                    }
                }
            }

            // Session: each button asks for confirmation first
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                ConfirmButton {
                    Layout.fillWidth: true
                    icon: "lock"
                    iconColor: Colors.panelText.warning
                    sureColor: Colors.panelText.warning
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
                    iconColor: Colors.panelText.danger
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
