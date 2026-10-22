import "root:/config"
import QtQuick
import QtQuick.Shapes

// A microphone, crossed out when muted.
// Drawn on a 16 x 16 grid, scaled to the size of the item.
Item {
    id: icon
    property color color: Colors.text.color
    property bool muted: false
    readonly property real k: width / 16

    implicitWidth: 16
    implicitHeight: 16

    // Head
    Rectangle {
        x: 5.5 * icon.k
        y: 1 * icon.k
        width: 5 * icon.k
        height: 8.5 * icon.k
        radius: width / 2
        color: icon.color
    }

    // Holder, stem and base
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 1.5 * icon.k
            strokeColor: icon.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 3 * icon.k
            startY: 7.5 * icon.k
            PathArc {
                x: 13 * icon.k
                y: 7.5 * icon.k
                radiusX: 5 * icon.k
                radiusY: 5 * icon.k
                direction: PathArc.Counterclockwise
            }
            PathMove { x: 8 * icon.k; y: 12.5 * icon.k }
            PathLine { x: 8 * icon.k; y: 15 * icon.k }
            PathMove { x: 5 * icon.k; y: 15 * icon.k }
            PathLine { x: 11 * icon.k; y: 15 * icon.k }
        }
    }

    // Slash
    Shape {
        anchors.fill: parent
        visible: icon.muted
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 1.5 * icon.k
            strokeColor: icon.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 2 * icon.k
            startY: 2 * icon.k
            PathLine { x: 14 * icon.k; y: 14 * icon.k }
        }
    }
}
