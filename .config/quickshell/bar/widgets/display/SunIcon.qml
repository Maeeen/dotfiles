import "root:/config"
import QtQuick
import QtQuick.Shapes

// A sun: a disc with eight rays.
// Drawn on a 16 x 16 grid, scaled to the size of the item.
Shape {
    id: sun
    property color color: Colors.text.color
    readonly property real k: width / 16

    implicitWidth: 16
    implicitHeight: 16
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeWidth: -1
        fillColor: sun.color
        startX: 11 * sun.k
        startY: 8 * sun.k
        PathArc { x: 5 * sun.k; y: 8 * sun.k; radiusX: 3 * sun.k; radiusY: 3 * sun.k }
        PathArc { x: 11 * sun.k; y: 8 * sun.k; radiusX: 3 * sun.k; radiusY: 3 * sun.k }
    }

    ShapePath {
        strokeWidth: 1.5 * sun.k
        strokeColor: sun.color
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        startX: 8 * sun.k
        startY: 1 * sun.k
        PathLine { x: 8 * sun.k; y: 2.5 * sun.k }
        PathMove { x: 8 * sun.k; y: 13.5 * sun.k }
        PathLine { x: 8 * sun.k; y: 15 * sun.k }
        PathMove { x: 1 * sun.k; y: 8 * sun.k }
        PathLine { x: 2.5 * sun.k; y: 8 * sun.k }
        PathMove { x: 13.5 * sun.k; y: 8 * sun.k }
        PathLine { x: 15 * sun.k; y: 8 * sun.k }
        PathMove { x: 3.05 * sun.k; y: 3.05 * sun.k }
        PathLine { x: 4.1 * sun.k; y: 4.1 * sun.k }
        PathMove { x: 11.9 * sun.k; y: 11.9 * sun.k }
        PathLine { x: 12.95 * sun.k; y: 12.95 * sun.k }
        PathMove { x: 3.05 * sun.k; y: 12.95 * sun.k }
        PathLine { x: 4.1 * sun.k; y: 11.9 * sun.k }
        PathMove { x: 11.9 * sun.k; y: 4.1 * sun.k }
        PathLine { x: 12.95 * sun.k; y: 3.05 * sun.k }
    }
}
