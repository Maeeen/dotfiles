import QtQuick
import QtQuick.Shapes

// Lock, log out, reboot, power and stay-awake icons, drawn as Shapes on an 18x18 grid.
Item {
    id: root
    // "lock", "logout", "reboot", "softreboot", "power" or "awake"
    property string name
    property color color

    implicitWidth: 18
    implicitHeight: 18

    // Lock: shackle and body
    Shape {
        visible: root.name === "lock"
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 1.8
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            startX: 5.5
            startY: 8
            PathLine { x: 5.5; y: 5.5 }
            PathArc { x: 12.5; y: 5.5; radiusX: 3.5; radiusY: 3.5 }
            PathLine { x: 12.5; y: 8 }
        }

        ShapePath {
            strokeWidth: -1
            fillColor: root.color

            PathRectangle { x: 3; y: 8; width: 12; height: 8.5; radius: 2 }
        }
    }

    // Log out: open door frame with an arrow going out
    Shape {
        visible: root.name === "logout"
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 1.8
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            // Frame
            PathMove { x: 10; y: 3 }
            PathLine { x: 4; y: 3 }
            PathLine { x: 4; y: 15 }
            PathLine { x: 10; y: 15 }

            // Arrow
            PathMove { x: 8; y: 9 }
            PathLine { x: 16; y: 9 }
            PathMove { x: 13; y: 6 }
            PathLine { x: 16; y: 9 }
            PathLine { x: 13; y: 12 }
        }
    }

    // Reboot: open circle with an arrow head at the top
    Shape {
        visible: root.name === "reboot" || root.name === "softreboot"
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 1.8
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            startX: 9
            startY: 3.5
            PathArc { x: 14.2; y: 6.5; radiusX: 6; radiusY: 6; useLargeArc: true; direction: PathArc.Counterclockwise }
        }

        ShapePath {
            strokeWidth: -1
            fillColor: root.color

            startX: 12
            startY: 3.5
            PathLine { x: 8.5; y: 0.9 }
            PathLine { x: 8.5; y: 6.1 }
            PathLine { x: 12; y: 3.5 }
        }
    }

    // Soft reboot: the reboot icon with a dot in the center
    Shape {
        visible: root.name === "softreboot"
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: root.color

            startX: 7.2
            startY: 9.5
            PathArc { x: 10.8; y: 9.5; radiusX: 1.8; radiusY: 1.8 }
            PathArc { x: 7.2; y: 9.5; radiusX: 1.8; radiusY: 1.8 }
        }
    }

    // Power: open circle with a line through the gap
    Shape {
        visible: root.name === "power"
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 1.8
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            startX: 4.8
            startY: 5
            PathArc { x: 13.2; y: 5; radiusX: 6.5; radiusY: 6.5; useLargeArc: true; direction: PathArc.Counterclockwise }
            PathMove { x: 9; y: 2 }
            PathLine { x: 9; y: 9 }
        }
    }

    // Stay awake: coffee cup with steam
    Shape {
        visible: root.name === "awake"
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 1.8
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            // Cup
            PathMove { x: 3; y: 8 }
            PathLine { x: 13; y: 8 }
            PathLine { x: 13; y: 13 }
            PathArc { x: 10; y: 16; radiusX: 3; radiusY: 3 }
            PathLine { x: 6; y: 16 }
            PathArc { x: 3; y: 13; radiusX: 3; radiusY: 3 }
            PathLine { x: 3; y: 8 }

            // Handle
            PathMove { x: 13; y: 9.5 }
            PathArc { x: 13; y: 13.5; radiusX: 2; radiusY: 2 }

            // Steam
            PathMove { x: 6; y: 2.5 }
            PathLine { x: 6; y: 5 }
            PathMove { x: 10; y: 2.5 }
            PathLine { x: 10; y: 5 }
        }
    }
}
