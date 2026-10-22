import "root:/config"
import "root:/serv"
import "root:/utils"
import QtQuick

// Opens or closes the notification panel.
// A list icon when there are no notifications, a bell and the count when there are.
Rectangle {
    readonly property int count: Notifs.list.length

    implicitWidth: row.implicitWidth + 12
    implicitHeight: 20
    radius: height / 2
    color: Notifs.panelOpen ? Colors.workspaceCircleActive : (count > 0 ? Colors.workspaceCircle : "transparent")

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: count > 0 ? "\u{1F56D}" : "☰"
            color: Colors.text.color
            font.family: Colors.text.iconFont
            font.pointSize: Colors.text.fontSize
        }

        Text {
            visible: count > 0
            anchors.verticalCenter: parent.verticalCenter
            text: count
            color: Colors.text.color
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }
    }

    HoverArea {
        anchors.fill: parent
        radius: parent.radius
        onClicked: Notifs.panelOpen = !Notifs.panelOpen
    }
}
