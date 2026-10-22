import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import "root:/config"
import "root:/utils"

Item {
    id: root
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    // width: content.implicitWidth
    // height: parent.height

    property var screen

    Text {
        id: content
        text: Hyprland.activeToplevel.title
        font.family: Colors.text.fontFamily
        anchors.horizontalCenter: parent.horizontalCenter
        // Fixed baseline from the main font: a character from a fallback font (e.g. "✳")
        // makes the line taller, and centering the line would then move the text.
        anchors.baseline: parent.top
        anchors.baselineOffset: (root.height + fm.ascent - fm.descent) / 2
    }

    FontMetrics {
        id: fm
        font: content.font
    }

    HoverArea {
        anchors.horizontalCenter: content.horizontalCenter
        anchors.verticalCenter: root.verticalCenter
        width: Math.max(content.width + 20, 60)
        height: root.height
        onClicked: {
            popup.requestOpen = !popup.requestOpen;
        }
    }

    PopupWrapper {
        id: popup
        screen: root.screen
        requestOpen: false
        anchors.top: root.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        GridLayout {
            columns: 3
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                // Only windows with a Wayland handle: Quickshell can keep old entries of closed
                // windows (e.g. hidden Spotify windows), which have no preview and no app ID
                model: Hyprland.toplevels.values.filter(t => t.wayland)

                // One card per window: preview, then app icon, title and workspace
                Rectangle {
                    id: window
                    property var toplevel: modelData
                    property var entry: Icons.getDesktopEntry(toplevel.wayland?.appId ?? "")
                    implicitWidth: 300
                    implicitHeight: 210
                    color: toplevel.activated ? Qt.rgba(0, 0, 0, 0.4) : Qt.rgba(0, 0, 0, 0.22)
                    clip: true

                    // The preview is scaled to fit this box and centered in it
                    Rectangle {
                        id: previewBox
                        x: 8
                        y: 8
                        width: parent.width - 16
                        height: 162
                        color: Qt.rgba(0, 0, 0, 0.25)

                        ScreencopyView {
                            anchors.centerIn: parent
                            width: implicitWidth
                            height: implicitHeight
                            constraintSize: Qt.size(previewBox.width, previewBox.height)
                            // Capture only while the popup shows: capturing a window that closes
                            // at the same time can make Hyprland disconnect Quickshell
                            captureSource: popup.visible ? window.toplevel.wayland : null
                            live: true
                        }
                    }

                    RowLayout {
                        anchors.top: previewBox.bottom
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        IconImage {
                            visible: !!window.entry
                            implicitSize: 16
                            source: window.entry ? Quickshell.iconPath(window.entry.icon, true) : ""
                        }

                        Text {
                            Layout.fillWidth: true
                            text: window.toplevel.title
                            elide: Text.ElideRight
                            color: Colors.text.color
                            font.pointSize: Colors.text.fontSize
                            font.family: Colors.text.fontFamily
                        }

                        Text {
                            visible: !!window.toplevel.workspace
                            // "special:magic" becomes "magic"
                            text: (window.toplevel.workspace?.name ?? "").replace(/^special:/, "")
                            color: Colors.text.secondary
                            font.pointSize: Colors.text.fontSize
                            font.family: Colors.text.fontFamily
                        }
                    }

                    // Marks the active window
                    Rectangle {
                        visible: window.toplevel.activated
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 2
                        color: Colors.text.color
                    }

                    HoverArea {
                        // Above the preview, so the highlight shows
                        z: 1
                        anchors.fill: parent
                        onClicked: {
                            window.toplevel.wayland.activate();
                        }
                    }

                    // Closes the window
                    Rectangle {
                        z: 2
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 12
                        width: 22
                        height: 22
                        radius: 11
                        color: Qt.rgba(0, 0, 0, 0.5)

                        Shape {
                            anchors.centerIn: parent
                            width: 8
                            height: 8
                            preferredRendererType: Shape.CurveRenderer

                            ShapePath {
                                strokeWidth: 1.5
                                strokeColor: Colors.text.color
                                fillColor: "transparent"
                                capStyle: ShapePath.RoundCap
                                startX: 0
                                startY: 0
                                PathLine { x: 8; y: 8 }
                                PathMove { x: 8; y: 0 }
                                PathLine { x: 0; y: 8 }
                            }
                        }

                        HoverArea {
                            anchors.fill: parent
                            radius: parent.radius
                            onClicked: window.toplevel.wayland.close()
                        }
                    }
                }
            }
        }
    }
}
