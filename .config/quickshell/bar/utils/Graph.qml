import "root:/config"
import QtQuick
import QtQuick.Shapes

// Line graph with a soft fill under it. The values are 0 to 1, the newest is on the right.
// `count` is the number of samples that fill the full width.
// An Item, not a Shape: a Shape sets its implicit size from the path, so a flat line made it too low.
Item {
    id: root
    property var values: []
    property int count: 60
    property color color: Colors.text.color

    readonly property var points: {
        const step = width / Math.max(1, count - 1);
        const first = count - values.length;
        return values.map((v, i) => Qt.point((first + i) * step, height - Math.max(0, Math.min(1, v)) * height));
    }

    implicitHeight: 60

    // Background with a middle line
    Rectangle {
        anchors.fill: parent
        radius: 6
        color: Colors.workspaceCircle
        opacity: 0.5
    }

    Rectangle {
        y: parent.height / 2
        width: parent.width
        height: 1
        color: Colors.workspaceCircle
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillGradient: LinearGradient {
                y1: 0
                y2: root.height
                GradientStop {
                    position: 0
                    color: Qt.alpha(root.color, 0.35)
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(root.color, 0.02)
                }
            }

            // The line, closed along the bottom
            PathPolyline {
                path: root.points.length ? [Qt.point(root.points[0].x, root.height)].concat(root.points, [Qt.point(root.width, root.height)]) : []
            }
        }

        ShapePath {
            strokeWidth: 1.5
            strokeColor: root.points.length > 1 ? root.color : "transparent"
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap

            PathPolyline {
                path: root.points
            }
        }
    }
}
