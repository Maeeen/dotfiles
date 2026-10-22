import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "root:/config"

// Swiss railway (SBB) clock. Shapes from the SBB Lyne sbb-clock component, 105x105 grid.
// The second hand turns in 58.5 s and waits at 12 until the minute hand jumps.
// A click switches between the bar colors and the white SBB dial.
Item {
    id: root
    property real size: 160
    readonly property bool white: clockState.white
    property color dialColor: white ? Colors.t("#ffffff", 1) : Qt.rgba(1, 1, 1, 0.08)
    property color faceColor: white ? Colors.t("#000000", 1) : Colors.text.color
    property color secondsColor: white ? Colors.t("#eb0000", 1) : "#f89abd"

    // Keeps the choice in a JSON file, also after a restart
    FileView {
        path: Quickshell.statePath("sbb-clock.json")
        // Read at once, so a new clock does not show the default colors first
        blockLoading: true
        // Write the file when the choice changes
        onAdapterUpdated: writeAdapter()
        // First start: make the file with the default values
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: clockState
            property bool white: false
        }
    }

    Behavior on dialColor {
        ColorAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on faceColor {
        ColorAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on secondsColor {
        ColorAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: clockState.white = !clockState.white
    }

    implicitWidth: size
    implicitHeight: size

    property real secondsAngle: 0
    // Start at the current time, so the minute hand does not jump from 0
    property int minutes: new Date().getMinutes()
    property int hours: new Date().getHours() % 12

    function update() {
        const now = new Date();
        const ms = now.getSeconds() * 1000 + now.getMilliseconds();
        secondsAngle = Math.min(ms / 58500, 1) * 360;
        minutes = now.getMinutes();
        hours = now.getHours() % 12;
    }

    Component.onCompleted: update()

    // Runs only while the clock is visible
    FrameAnimation {
        running: root.visible
        onTriggered: root.update()
    }

    Item {
        width: 105
        height: 105
        anchors.centerIn: parent
        scale: root.size / 105

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: root.dialColor
                strokeWidth: -1
                PathAngleArc {
                    centerX: 52.5
                    centerY: 52.5
                    radiusX: 52.5
                    radiusY: 52.5
                    sweepAngle: 360
                }
            }
            ShapePath {
                fillColor: root.faceColor
                strokeWidth: -1
                PathSvg {
                    path: "M50.75 4h3.5v12h-3.5zM50.75 89h3.5v12h-3.5zM75.233 9.623l3.03 1.75-6 10.392-3.03-1.75zM32.734 83.233l3.03 1.75-6 10.392-3.03-1.75zM93.628 26.732l1.75 3.031-10.392 6-1.75-3.03zM20.017 69.234l1.75 3.031-10.392 6-1.75-3.03zM101 50.75v3.5H89v-3.5zM16 50.75v3.5H4v-3.5zM95.379 75.232l-1.75 3.031-10.392-6 1.75-3.03zM21.766 32.734l-1.75 3.031-10.392-6 1.75-3.03zM78.267 93.63l-3.03 1.75-6-10.393 3.03-1.75zM35.766 20.015l-3.03 1.75-6-10.392 3.03-1.75z"
                }
            }
            ShapePath {
                fillColor: root.faceColor
                strokeWidth: -1
                PathSvg {
                    path: "M56.873 4.19l1.392.147-.366 3.48-1.392-.145zM47.101 97.177l1.393.146-.366 3.481-1.392-.146zM61.896 4.914l1.37.29-.728 3.424-1.37-.29zM42.458 96.366l1.37.29-.728 3.424-1.37-.291zM66.825 6.157l1.332.432-1.082 3.33-1.331-.434zM37.931 95.085l1.332.432-1.082 3.33-1.331-.433zM71.584 7.906l1.28.569-1.424 3.197-1.28-.57zM33.56 93.32l1.278.569-1.423 3.197-1.28-.57zM80.44 12.852l1.133.823-2.058 2.831-1.132-.823zM25.481 88.494l1.133.822-2.057 2.832-1.133-.823zM84.43 15.986l1.04.937-2.342 2.6-1.04-.936zM21.87 85.469l1.04.936-2.341 2.601-1.04-.937zM88.072 19.522l.937 1.04-2.6 2.343-.937-1.04zM18.593 82.088l.937 1.04-2.601 2.342-.937-1.04zM91.328 23.425l.823 1.133-2.832 2.057-.823-1.132zM15.684 78.385l.823 1.132-2.832 2.058-.822-1.133zM96.52 32.128l.57 1.279-3.198 1.423-.57-1.278zM11.109 70.161l.569 1.279-3.197 1.423-.57-1.279zM98.407 36.85l.433 1.332-3.33 1.081-.432-1.331zM9.483 65.74l.432 1.33-3.329 1.082-.432-1.331zM99.795 41.726l.291 1.37-3.423.727-.29-1.37zM8.34 61.17l.292 1.37-3.424.728-.29-1.37zM100.66 46.73l.146 1.393-3.48.366-.147-1.392zM7.674 56.506l.146 1.392-3.48.366-.147-1.392zM100.811 56.873l-.146 1.392-3.48-.365.145-1.393zM7.821 47.101l-.146 1.392-3.48-.365.145-1.393zM100.09 61.895l-.291 1.369-3.424-.728.291-1.369zM8.631 42.46l-.291 1.37-3.423-.728.29-1.37zM98.84 66.827l-.432 1.331-3.329-1.081.433-1.332zM9.918 37.93l-.433 1.331-3.329-1.082.433-1.331zM97.098 71.585l-.569 1.28-3.197-1.424.57-1.28zM11.677 33.558l-.57 1.28-3.197-1.424.57-1.279zM92.149 80.439l-.823 1.133-2.832-2.058.823-1.132zM16.506 25.482l-.823 1.133-2.831-2.057.823-1.133zM89.017 84.431l-.937 1.04-2.6-2.341.936-1.04zM19.528 21.869l-.936 1.04-2.601-2.342.936-1.04zM85.48 88.076l-1.041.936-2.342-2.6 1.04-.937zM22.91 18.59l-1.04.937-2.341-2.601 1.04-.937zM81.574 91.328l-1.133.823-2.057-2.831 1.132-.823zM26.617 15.684l-1.133.823-2.057-2.832 1.132-.823zM72.873 96.524l-1.279.57-1.423-3.198 1.278-.57zM34.838 11.105l-1.279.57-1.423-3.198 1.279-.57zM68.151 98.405l-1.331.432-1.082-3.329 1.332-.432zM39.259 9.485l-1.332.433-1.081-3.33 1.331-.432zM63.272 99.799l-1.369.29-.728-3.422 1.37-.291zM43.83 8.337l-1.369.291-.727-3.423 1.37-.291zM58.27 100.662l-1.393.146-.366-3.48 1.393-.147zM48.494 7.672l-1.392.147-.366-3.481 1.392-.147z"
                }
            }
        }

        Hand {
            path: "M55.7 64.5h-6.4l.6-44h5.2z"
            color: root.faceColor
            rotation: root.hours * 30 + root.minutes * 0.5
        }

        Hand {
            path: "M55.1,64.5h-5.2l0.8-58h3.6L55.1,64.5z"
            color: root.faceColor
            rotation: root.minutes * 6

            // The jump with a small overshoot, like the original
            Behavior on rotation {
                RotationAnimation {
                    direction: RotationAnimation.Clockwise
                    duration: 200
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.4, 2.08, 0.55, 0.44, 1, 1]
                }
            }
        }

        Hand {
            path: "M57.8,21.3c0-2.9-2.4-5.2-5.2-5.2s-5.3,2.3-5.3,5.2c0,2.7,2,4.8,4.5,5.2V69h1.5V26.5C55.8,26.2,57.8,24,57.8,21.3z"
            color: root.secondsColor
            rotation: root.secondsAngle
        }
    }

    component Hand: Shape {
        id: hand
        property string path
        property color color
        width: 105
        height: 105
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: hand.color
            strokeWidth: -1
            PathSvg {
                path: hand.path
            }
        }
    }
}
