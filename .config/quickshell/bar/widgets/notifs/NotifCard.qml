import "root:/config"
import "root:/utils"
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property Notification notification
    signal closeClicked

    readonly property string appIcon: iconSource(notification?.appIcon)
    readonly property string image: iconSource(notification?.image)
    // The "default" action is a click on the notification, not a button
    readonly property var defaultAction: [...(notification?.actions ?? [])].find(a => a.identifier === "default") ?? null
    readonly property var buttonActions: [...(notification?.actions ?? [])].filter(a => a.identifier !== "default" && a.text !== "")

    implicitWidth: 350
    implicitHeight: layout.implicitHeight + 16
    radius: 12
    color: notification?.urgency === NotificationUrgency.Critical ? Colors.workspaceCircleUrgent : Colors.workspaceCircle

    function escapeHtml(str) {
        return (str ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    function iconSource(icon) {
        if (!icon)
            return "";
        if (icon.startsWith("/"))
            return "file://" + icon;
        if (icon.includes("://"))
            return icon;
        return Quickshell.iconPath(icon, true);
    }

    HoverArea {
        anchors.fill: parent
        radius: parent.radius
        enabled: root.defaultAction !== null
        onClicked: root.defaultAction.invoke()
    }

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 8

        RowLayout {
            spacing: 10

            // App icon, or the image when the app has no icon
            IconImage {
                visible: source != ""
                Layout.alignment: Qt.AlignTop
                implicitSize: 48
                source: root.appIcon || root.image
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                // Title, app name and close button
                RowLayout {
                    // One text, so the app name wraps to the next line before the title does
                    Text {
                        Layout.fillWidth: true
                        text: `<b>${root.escapeHtml(root.notification?.summary)}</b>&nbsp;&nbsp;<font color="${Colors.text.secondary}">${root.escapeHtml(root.notification?.appName)}</font>`
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        color: Colors.text.color
                        font.pointSize: Colors.text.fontSize
                        font.family: Colors.text.fontFamily
                    }

                    GhostButton {
                        Layout.alignment: Qt.AlignTop
                        text: "×"
                        onClicked: root.closeClicked()
                    }
                }

                Text {
                    visible: text !== ""
                    Layout.fillWidth: true
                    text: root.notification?.body ?? ""
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: 5
                    elide: Text.ElideRight
                    color: Colors.text.color
                    font.pointSize: Colors.text.fontSize
                    font.family: Colors.text.fontFamily
                }
            }

            // The image, when the app icon already takes the left side
            Image {
                visible: root.appIcon !== "" && status === Image.Ready
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignTop
                fillMode: Image.PreserveAspectFit
                source: root.appIcon !== "" ? root.image : ""
            }

            // Actions, as a list on the right
            ColumnLayout {
                visible: actions.count > 0
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 100
                spacing: 6

                Repeater {
                    id: actions
                    model: root.buttonActions

                    Rectangle {
                        required property NotificationAction modelData
                        Layout.fillWidth: true
                        implicitHeight: 28
                        radius: 6
                        color: Colors.workspaceCircle

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            text: parent.modelData.text
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            color: Colors.text.color
                            font.pointSize: Colors.text.fontSize
                            font.family: Colors.text.fontFamily
                        }

                        HoverArea {
                            anchors.fill: parent
                            onClicked: parent.modelData.invoke()
                        }
                    }
                }
            }
        }
    }
}
