import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "root:/config"
import "root:/serv"
import "root:/utils"

// The time; a click opens or closes the right panel.
// A bell and the count show when there are notifications.
Item {
    readonly property int count: Notifs.list.length

    implicitWidth: row.implicitWidth + 12
    // Full bar height, so the hover area matches the bar
    Layout.fillHeight: true

    Rectangle {
        anchors.fill: parent
        color: Notifs.panelOpen ? Colors.workspaceCircle : "transparent"
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        // Bell, drawn as a Shape so it is sharp and centered (the font glyph was not)
        Shape {
            visible: count > 0
            anchors.verticalCenter: parent.verticalCenter
            width: 12
            height: 13
            preferredRendererType: Shape.CurveRenderer

            // Dome, sides and rim
            ShapePath {
                strokeWidth: -1
                fillColor: Colors.text.color

                startX: 1
                startY: 10
                PathLine { x: 2.5; y: 8.5 }
                PathLine { x: 2.5; y: 5.5 }
                PathCubic { x: 6; y: 1.5; control1X: 2.5; control1Y: 3.2; control2X: 4; control2Y: 1.5 }
                PathCubic { x: 9.5; y: 5.5; control1X: 8; control1Y: 1.5; control2X: 9.5; control2Y: 3.2 }
                PathLine { x: 9.5; y: 8.5 }
                PathLine { x: 11; y: 10 }
                PathLine { x: 1; y: 10 }
            }

            // Knob on top
            ShapePath {
                strokeWidth: -1
                fillColor: Colors.text.color

                startX: 5
                startY: 1.5
                PathArc { x: 7; y: 1.5; radiusX: 1; radiusY: 1 }
            }

            // Clapper
            ShapePath {
                strokeWidth: -1
                fillColor: Colors.text.color

                startX: 4.6
                startY: 11
                PathArc { x: 7.4; y: 11; radiusX: 1.4; radiusY: 1.4; direction: PathArc.Counterclockwise }
            }
        }

        Text {
            visible: count > 0
            anchors.verticalCenter: parent.verticalCenter
            rightPadding: 4
            text: count
            color: Colors.text.color
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.time
            color: Colors.text.color
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }
    }

    HoverArea {
        anchors.fill: parent
        onClicked: Notifs.panelOpen = !Notifs.panelOpen
    }
}
