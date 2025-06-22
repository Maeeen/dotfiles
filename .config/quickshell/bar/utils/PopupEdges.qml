import QtQuick
import QtQuick.Shapes
import "root:/config"

Rectangle {
    id: root
    property var popout

    readonly property real edgeWidth: 30
    readonly property real edgeHeight: 30
    readonly property real radius: 30

    x: -edgeWidth
    height: edgeHeight
    width: popout.width + edgeWidth * 2
    color: "transparent"

    Shape {
        clip: true
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 0
            fillColor: Colors.backgrounds.color
            fillRule: ShapePath.OddEvenFill

            startX: 0
            startY: 0

            PathArc {
                x: root.edgeWidth
                y: Math.min(root.popout.height, root.edgeHeight)
                radiusX: root.radius
                radiusY: root.radius
            }

            PathLine {
                x: root.edgeWidth
                y: 0
            }
        }
    }

    Shape {
        clip: true
        anchors.fill: parent
        x: root.popout.width
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 0
            fillColor: Colors.backgrounds.color
            fillRule: ShapePath.OddEvenFill

            startX: root.popout.width + root.edgeWidth * 2
            startY: 0

            PathArc {
                x: root.popout.width + root.edgeWidth
                y: Math.min(root.popout.height, root.edgeHeight)
                radiusX: root.radius
                radiusY: root.radius
                // Clockwise
                direction: PathArc.Counterclockwise
            }

            PathLine {
                x: root.popout.width + root.edgeWidth
                y: 0
            }
        }
    }
}
