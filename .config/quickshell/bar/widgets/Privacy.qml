import "root:/config"
import "root:/utils"
import "root:/widgets/audio"
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// An orange pill while an application records the microphone or the screen.
// Hover shows the names of the applications.
Item {
    id: root
    property var screen

    // Applications that record audio. "Stream/Input/Audio/Internal" (Bluetooth) is not an application.
    readonly property var micStreams: Pipewire.nodes.values.filter(n => n.properties["media.class"] === "Stream/Input/Audio")
    // The screen share node of xdg-desktop-portal-hyprland. Webcams are also "Video/Source", so use the name.
    readonly property var screenNodes: Pipewire.nodes.values.filter(n => n.properties["media.class"] === "Video/Source" && n.properties["node.name"] === "xdg-desktop-portal-hyprland")
    readonly property bool screenShared: screenNodes.length > 0
    // Applications that read a video source (the screen share)
    readonly property var videoStreams: Pipewire.nodes.values.filter(n => n.properties["media.class"] === "Stream/Input/Video")
    readonly property bool micUsed: micStreams.length > 0

    function appNames(nodes) {
        return [...new Set(nodes.map(n => n.properties["application.name"] || n.properties["node.name"] || "Unknown"))].join(", ");
    }

    // The properties are only valid on bound nodes. Sinks never record.
    PwObjectTracker {
        objects: Pipewire.nodes.values.filter(n => !n.isSink)
    }

    // Grows in and shrinks out: hidden only when the width is 0
    readonly property bool shown: micUsed || screenShared
    visible: Layout.preferredWidth > 0
    opacity: shown ? 1 : 0
    Layout.preferredWidth: shown ? pill.width + 8 : 0
    // Takes the layout spacing away while it shrinks, so the next items do not jump at the end
    Layout.leftMargin: parent.spacing * (Layout.preferredWidth / (pill.width + 8) - 1)
    implicitHeight: parent.height

    Behavior on Layout.preferredWidth {
        WidthAnimation {}
    }

    Behavior on opacity {
        WidthAnimation {}
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        implicitWidth: icons.implicitWidth + 14
        implicitHeight: 22
        radius: height / 2
        color: Colors.backgrounds.privacy

        HoverHandler {
            id: buttonHover
        }

        Row {
            id: icons
            anchors.centerIn: parent
            spacing: 4

            MicIcon {
                visible: root.micUsed
                width: 14
                height: 14
                color: Colors.textOn(pill.color)
            }

            ScreenIcon {
                visible: root.screenShared
                width: 14
                height: 14
                color: Colors.textOn(pill.color)
            }
        }
    }

    PopupWrapper {
        requestOpen: buttonHover.hovered
        anchors.horizontalCenter: pill.horizontalCenter
        anchors.top: parent.bottom
        screen: root.screen

        GridLayout {
            columns: 3
            columnSpacing: 10
            rowSpacing: 4

            Label {
                visible: root.micUsed
                text: "Microphone"
                color: Colors.text.secondary
            }
            Label {
                visible: root.micUsed
                text: root.appNames(root.micStreams)
            }
            Item {
                visible: root.micUsed
            }
            Label {
                visible: root.screenShared
                text: "Screen"
                color: Colors.text.secondary
            }
            Label {
                visible: root.screenShared
                text: root.videoStreams.length > 0 ? root.appNames(root.videoStreams) : "Unknown"
            }

            // Ends the share: without its node, the application sees the stream end
            Rectangle {
                visible: root.screenShared
                implicitWidth: stopLabel.implicitWidth + 16
                implicitHeight: 20
                radius: 6
                color: Colors.workspaceCircle

                Text {
                    id: stopLabel
                    anchors.centerIn: parent
                    text: "Stop"
                    color: Colors.text.danger
                    font.pointSize: Colors.text.fontSize
                    font.family: Colors.text.fontFamily
                }

                HoverArea {
                    anchors.fill: parent
                    radius: parent.radius
                    onClicked: {
                        for (const n of root.screenNodes)
                            Quickshell.execDetached(["pw-cli", "destroy", String(n.id)]);
                    }
                }
            }
        }
    }

    component Label: Text {
        Layout.maximumWidth: 300
        elide: Text.ElideRight
        color: Colors.text.color
        font.pointSize: Colors.text.fontSize
        font.family: Colors.text.fontFamily
    }

    // A monitor on a stand, on a 16 x 16 grid
    component ScreenIcon: Shape {
        id: screenIcon
        property color color: Colors.text.color
        readonly property real k: width / 16
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 1.5 * screenIcon.k
            strokeColor: screenIcon.color
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            startX: 1.5 * screenIcon.k
            startY: 2.5 * screenIcon.k
            PathLine { x: 14.5 * screenIcon.k; y: 2.5 * screenIcon.k }
            PathLine { x: 14.5 * screenIcon.k; y: 11 * screenIcon.k }
            PathLine { x: 1.5 * screenIcon.k; y: 11 * screenIcon.k }
            PathLine { x: 1.5 * screenIcon.k; y: 2.5 * screenIcon.k }
            PathMove { x: 8 * screenIcon.k; y: 11 * screenIcon.k }
            PathLine { x: 8 * screenIcon.k; y: 14 * screenIcon.k }
            PathMove { x: 5 * screenIcon.k; y: 14 * screenIcon.k }
            PathLine { x: 11 * screenIcon.k; y: 14 * screenIcon.k }
        }
    }
}
