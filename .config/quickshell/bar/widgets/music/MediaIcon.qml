import QtQuick
import QtQuick.Shapes
import "root:/config"

// Media icons drawn with shapes on a 24x24 grid, so no icon font is needed.
// kind: "playpause", "next", "previous", "repeat"
Item {
    id: root
    property string kind: "playpause"
    property bool playing: false // playpause: true shows pause
    property bool one: false // repeat: true shows the "1"
    property color color: Colors.text.color

    implicitWidth: 18
    implicitHeight: 18

    // 0 = play triangle, 1 = pause bars
    property real morph: playing ? 1 : 0
    Behavior on morph {
        NumberAnimation {
            duration: 250
            easing.type: Easing.InOutCubic
        }
    }

    property real shift: 0
    property real spin: 0
    property real pop: 1

    // Plays the click animation of this kind of icon.
    function animate() {
        if (kind == "next" || kind == "previous")
            nudge.restart();
        else if (kind == "repeat")
            spinAnim.restart();
        else
            popAnim.restart();
    }

    function lerp(a, b) {
        return a + (b - a) * morph;
    }

    function poly(points) {
        return points.map(p => Qt.point(p[0], p[1]));
    }

    SequentialAnimation {
        id: nudge
        NumberAnimation {
            target: root
            property: "shift"
            to: 4
            duration: 90
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "shift"
            to: 0
            duration: 260
            easing.type: Easing.OutBack
        }
    }

    NumberAnimation {
        id: spinAnim
        target: root
        property: "spin"
        from: 0
        to: 360
        duration: 450
        easing.type: Easing.InOutCubic
    }

    SequentialAnimation {
        id: popAnim
        NumberAnimation {
            target: root
            property: "pop"
            to: 0.75
            duration: 80
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "pop"
            to: 1
            duration: 280
            easing.type: Easing.OutBack
        }
    }

    Shape {
        width: 24
        height: 24
        anchors.centerIn: parent
        scale: Math.min(root.width, root.height) / 24 * root.pop
        rotation: root.spin
        preferredRendererType: Shape.CurveRenderer
        transform: Translate {
            x: root.kind == "previous" ? -root.shift : root.shift
        }

        // Play/pause: the triangle splits in two halves that become the two bars.
        ShapePath {
            fillColor: root.kind == "playpause" ? root.color : "transparent"
            strokeWidth: -1
            PathPolyline {
                path: root.poly([[root.lerp(6.5, 5.5), root.lerp(3.5, 4)], [root.lerp(13.5, 10), root.lerp(7.8, 4)], [root.lerp(13.5, 10), root.lerp(16.2, 20)], [root.lerp(6.5, 5.5), root.lerp(20.5, 20)]])
            }
        }
        ShapePath {
            fillColor: root.kind == "playpause" ? root.color : "transparent"
            strokeWidth: -1
            PathPolyline {
                path: root.poly([[root.lerp(13.5, 14), root.lerp(7.8, 4)], [root.lerp(20.5, 18.5), root.lerp(12, 4)], [root.lerp(20.5, 18.5), root.lerp(12, 20)], [root.lerp(13.5, 14), root.lerp(16.2, 20)]])
            }
        }

        // Next / previous: a triangle and a bar, mirrored for previous.
        ShapePath {
            fillColor: (root.kind == "next" || root.kind == "previous") ? root.color : "transparent"
            strokeWidth: -1
            PathPolyline {
                path: root.kind == "previous" ? root.poly([[18.5, 4.5], [8, 12], [18.5, 19.5]]) : root.poly([[5.5, 4.5], [16, 12], [5.5, 19.5]])
            }
        }
        ShapePath {
            fillColor: (root.kind == "next" || root.kind == "previous") ? root.color : "transparent"
            strokeWidth: -1
            PathPolyline {
                path: root.kind == "previous" ? root.poly([[5, 4.5], [7.5, 4.5], [7.5, 19.5], [5, 19.5]]) : root.poly([[16.5, 4.5], [19, 4.5], [19, 19.5], [16.5, 19.5]])
            }
        }

        // Repeat: two rounded arrows, plus a "1" for repeat one.
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.kind == "repeat" ? root.color : "transparent"
            strokeWidth: 2
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                path: "M 4 11 V 9.5 A 3.5 3.5 0 0 1 7.5 6 H 19 M 16 3 L 19 6 L 16 9 M 20 13 V 14.5 A 3.5 3.5 0 0 1 16.5 18 H 5 M 8 15 L 5 18 L 8 21"
            }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.kind == "repeat" ? Qt.rgba(root.color.r, root.color.g, root.color.b, root.one ? 1 : 0) : "transparent"
            strokeWidth: 1.6
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                path: "M 10.8 10.4 L 12.4 9.4 V 14.6"
            }
        }
    }
}
