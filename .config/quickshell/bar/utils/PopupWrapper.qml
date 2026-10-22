import Quickshell.Widgets
import QtQuick
import QtQuick.Shapes
import "root:/config"
import "root:/utils"

Item {
    id: root
    HoverHandler {
        id: nested
    }

    property bool requestOpen

    Component.onDestruction: {
        PopupsState.close(screen, this);
    }

    onOpenedChanged: {
        if (opened) {
            PopupsState.open(screen, this);
        } else if (!opened) {
            PopupsState.close(screen, this);
        }
    }

    // Stays open a short time after the mouse leaves the popup
    property bool hoverHold: false
    property bool opened: requestOpen || hoverHold

    Connections {
        target: nested
        function onHoveredChanged() {
            if (nested.hovered) {
                hoverClose.stop();
                root.hoverHold = true;
            } else {
                hoverClose.restart();
            }
        }
    }

    Timer {
        id: hoverClose
        interval: Config.popupCloseDelay
        onTriggered: root.hoverHold = false
    }

    // Closes at once, also when the mouse is on the popup (e.g. a close button)
    function close() {
        hoverClose.stop();
        hoverHold = false;
    }
    property real margins: 14
    property var screen

    // Radius of the bottom corners, and of the inverted corners that join the popup to the bar.
    property real radius: 20
    // The radii follow the height, so the shape stays correct while the popup opens and closes.
    readonly property real cornerRadius: Math.min(radius, height / 2, width / 2)
    readonly property real edgeRadius: Math.min(radius, Math.max(0, height - cornerRadius))

    width: (actualContent.width + margins * 2)
    height: opened ? (actualContent.height + margins * 2) : 0
    visible: height > 0

    default property alias content: actualContent.data

    // The body and the inverted corners are one path, so there is no seam between them.
    // It goes out of the item on the left and right by `radius`, for the inverted corners.
    Shape {
        id: background
        x: -root.radius
        width: root.width + root.radius * 2
        height: root.height
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            // Same color as the bar at the top, so the popup joins the bar.
            // A small white tint at the bottom gives depth.
            fillGradient: LinearGradient {
                x1: 0
                y1: 0
                x2: 0
                y2: root.height
                GradientStop {
                    position: 0.0
                    color: Colors.backgrounds.color
                }
                GradientStop {
                    position: 1.0
                    color: Qt.tint(Colors.backgrounds.color, Qt.rgba(1, 1, 1, 0.12))
                }
            }

            startX: root.radius - root.edgeRadius
            startY: 0

            // Inverted corner, top left
            PathArc {
                x: root.radius
                y: root.edgeRadius
                radiusX: root.edgeRadius
                radiusY: root.edgeRadius
            }
            PathLine {
                x: root.radius
                y: root.height - root.cornerRadius
            }
            // Bottom left corner
            PathArc {
                x: root.radius + root.cornerRadius
                y: root.height
                radiusX: root.cornerRadius
                radiusY: root.cornerRadius
                direction: PathArc.Counterclockwise
            }
            PathLine {
                x: root.radius + root.width - root.cornerRadius
                y: root.height
            }
            // Bottom right corner
            PathArc {
                x: root.radius + root.width
                y: root.height - root.cornerRadius
                radiusX: root.cornerRadius
                radiusY: root.cornerRadius
                direction: PathArc.Counterclockwise
            }
            PathLine {
                x: root.radius + root.width
                y: root.edgeRadius
            }
            // Inverted corner, top right
            PathArc {
                x: root.radius + root.width + root.edgeRadius
                y: 0
                radiusX: root.edgeRadius
                radiusY: root.edgeRadius
            }
        }
    }

    Item {
        id: body
        anchors.fill: parent
        clip: true

        Item {
            id: actualContent
            x: root.margins
            y: root.margins + (root.opened ? 0 : -6)
            width: childrenRect.width
            height: childrenRect.height
            opacity: root.opened ? 1 : 0

            Behavior on y {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Behavior on width {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }
}
