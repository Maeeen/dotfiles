import "root:/config"
import QtQuick
import QtQuick.Shapes

// A speaker with sound waves for the volume, or a cross when muted.
// Drawn on a 16 x 16 grid, scaled to the size of the item.
Item {
    id: icon
    property color color: Colors.text.color
    property bool muted: false
    property real volume: 1
    readonly property real k: width / 16

    implicitWidth: 16
    implicitHeight: 16

    // Body and cone
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: icon.color
            startX: 1 * icon.k
            startY: 6 * icon.k
            PathLine { x: 4 * icon.k; y: 6 * icon.k }
            PathLine { x: 8 * icon.k; y: 2.5 * icon.k }
            PathLine { x: 8 * icon.k; y: 13.5 * icon.k }
            PathLine { x: 4 * icon.k; y: 10 * icon.k }
            PathLine { x: 1 * icon.k; y: 10 * icon.k }
            PathLine { x: 1 * icon.k; y: 6 * icon.k }
        }
    }

    // Small wave
    Shape {
        anchors.fill: parent
        visible: !icon.muted && icon.volume > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 1.5 * icon.k
            strokeColor: icon.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 10.5 * icon.k
            startY: 5.5 * icon.k
            PathArc {
                x: 10.5 * icon.k
                y: 10.5 * icon.k
                radiusX: 3.5 * icon.k
                radiusY: 3.5 * icon.k
            }
        }
    }

    // Large wave
    Shape {
        anchors.fill: parent
        visible: !icon.muted && icon.volume > 0.5
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 1.5 * icon.k
            strokeColor: icon.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 12.5 * icon.k
            startY: 3.5 * icon.k
            PathArc {
                x: 12.5 * icon.k
                y: 12.5 * icon.k
                radiusX: 6.4 * icon.k
                radiusY: 6.4 * icon.k
            }
        }
    }

    // Cross
    Shape {
        anchors.fill: parent
        visible: icon.muted
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 1.5 * icon.k
            strokeColor: icon.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 10.5 * icon.k
            startY: 5.5 * icon.k
            PathLine { x: 15 * icon.k; y: 10.5 * icon.k }
            PathMove { x: 15 * icon.k; y: 5.5 * icon.k }
            PathLine { x: 10.5 * icon.k; y: 10.5 * icon.k }
        }
    }
}
