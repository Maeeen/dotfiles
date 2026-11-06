import "root:/config"
import "root:/utils"
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

RowLayout {
    id: workspaces
    required property ShellScreen screen

    Behavior on width {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }

    Text {
        Layout.leftMargin: 10
        font.pointSize: Colors.text.fontSize
        font.family: Colors.text.fontFamily
        color: Colors.text.color
    }

    // Name of the special workspace shown on this monitor, or "" when none is shown.
    property string shownSpecial: ""

    Component.onCompleted: shownSpecial = Hyprland.monitorFor(screen)?.lastIpcObject?.specialWorkspace?.name ?? ""

    Connections {
        target: Hyprland
        // data is "special:name,MONITOR", or ",MONITOR" when the special workspace is hidden.
        function onRawEvent(event) {
            if (event.name !== "activespecial")
                return;
            const [name, monitor] = event.data.split(",");
            if (monitor === screen.name)
                shownSpecial = name;
        }
    }

    Repeater {
        // ScriptModel keeps the existing items, so only new workspaces animate in.
        model: ScriptModel {
            values: {
                const onScreen = Hyprland.workspaces.values.filter(s => s != null && s.monitor != null && s.monitor.name === screen.name);
                // Special workspaces have negative ids. Show them after the normal ones.
                return onScreen.filter(s => s.id > 0).concat(onScreen.filter(s => s.id < 0));
            }
        }

        WorkspaceItem {}
    }

    component WorkspaceItem: Item {
        id: workspaceItem
        required property HyprlandWorkspace modelData
        property bool special: modelData.id < 0
        property bool urgent: modelData.urgent
        property bool active: special ? shownSpecial === modelData.name : modelData.active
        property bool hovered: mouseArea.containsMouse
        // Stays true a short time after the mouse leaves the pill
        property bool open: false

        onHoveredChanged: {
            if (hovered) {
                closeDelay.stop();
                open = true;
            } else {
                closeDelay.restart();
            }
        }

        Timer {
            id: closeDelay
            // Give the mouse time to move from the pill to the popup
            interval: Config.popupCloseDelay
            onTriggered: workspaceItem.open = false
        }
        // Windows of the workspace: {title, icon}. The icon is "" when the theme does not have it.
        readonly property var windows: modelData.toplevels.values.map(t => {
            const appId = t.wayland?.appId ?? t.lastIpcObject?.class ?? "";
            const entry = appId ? DesktopEntries.heuristicLookup(appId) : null;
            return {
                title: t.title || appId,
                icon: Quickshell.iconPath(entry?.icon || appId, true)
            };
        })
        // App icons of the windows, each app one time (at most 4)
        readonly property var appIcons: special ? [] : [...new Set(windows.map(w => w.icon).filter(i => i))].slice(0, 4)
        // With one app only, the pill or circle shows its icon and no number
        readonly property bool iconOnly: appIcons.length === 1
        // The active pill shows all the icons; a circle shows the icon only when there is one app
        readonly property var icons: active || iconOnly ? appIcons : []
        // The active workspace is a wide pill, the others are circles
        property int itemWidth: active ? (iconOnly ? 28 : 28 + icons.length * 17) : 18
        readonly property int itemHeight: 18
        readonly property color textColor: urgent ? "white" : (active ? Colors.workspaceNumber : Qt.alpha(Colors.workspaceNumber, 0.7))

        Behavior on itemWidth {
            NumberAnimation {
                duration: 150
                easing.type: Easing.InOutQuad
            }
        }

        // Goes from 0 to 1 when the item is created, so a new workspace grows in.
        property real appear: 0
        Component.onCompleted: appear = 1

        Behavior on appear {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        height: itemHeight
        width: itemWidth * appear
        Layout.preferredWidth: itemWidth * appear
        // The negative part cancels the RowLayout spacing until the item has appeared.
        // Special workspaces get a small extra gap from the normal ones.
        Layout.leftMargin: ((special ? 6 : 0) + parent.spacing) * appear - parent.spacing

        Rectangle {
            id: rect
            anchors.centerIn: parent
            width: itemWidth
            height: itemHeight
            color: urgent ? Colors.workspaceDotUrgent : (active ? Colors.workspacePill : (hovered ? Colors.workspaceDotHover : Colors.workspaceDot))
            radius: special ? 5 : height / 2
            scale: appear
            opacity: appear

            Behavior on color {
                ColorAnimation {
                    duration: 150
                    easing.type: Easing.InOutQuad
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: function () {
                    if (special) {
                        Hyprland.dispatch(`hl.dsp.workspace.toggle_special("${modelData.name.replace("special:", "")}")`);
                    } else {
                        modelData.activate();
                    }
                }
            }

            Row {
                visible: !special
                anchors.centerIn: parent
                spacing: 4

                Text {
                    visible: !iconOnly
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    text: modelData.id
                    color: textColor
                    font.pointSize: active ? 9 : 8
                    font.bold: active
                    font.family: Colors.text.fontFamily
                }

                Repeater {
                    model: icons

                    IconImage {
                        required property string modelData
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 13
                        source: modelData
                    }
                }
            }

            // Four-point star for special workspaces. A Shape, not a "✦" glyph,
            // because the glyph is not vertically centered in its font.
            Shape {
                id: star
                visible: special
                anchors.centerIn: parent
                width: itemHeight * 0.6
                height: width
                preferredRendererType: Shape.CurveRenderer

                readonly property real c: width / 2
                readonly property real inner: width * 0.12

                ShapePath {
                    strokeWidth: -1
                    fillColor: textColor

                    startX: star.c
                    startY: 0
                    PathLine { x: star.c + star.inner; y: star.c - star.inner }
                    PathLine { x: star.width; y: star.c }
                    PathLine { x: star.c + star.inner; y: star.c + star.inner }
                    PathLine { x: star.c; y: star.height }
                    PathLine { x: star.c - star.inner; y: star.c + star.inner }
                    PathLine { x: 0; y: star.c }
                    PathLine { x: star.c - star.inner; y: star.c - star.inner }
                    PathLine { x: star.c; y: 0 }
                }
            }
        }

        // On hover: the windows of the workspace, with icon and title
        PopupWrapper {
            requestOpen: open && windows.length > 0
            anchors.left: rect.left
            anchors.top: rect.bottom
            // From the pill down to the bottom of the bar
            anchors.topMargin: (Config.barHeight - itemHeight) / 2
            screen: workspaces.screen

            ColumnLayout {
                spacing: 4

                Text {
                    text: special ? modelData.name.replace("special:", "") : `Workspace ${modelData.id}`
                    color: Colors.text.secondary
                    font.pointSize: Colors.text.fontSize
                    font.family: Colors.text.fontFamily
                    font.weight: Font.Medium
                }

                Repeater {
                    model: windows

                    RowLayout {
                        required property var modelData
                        spacing: 8

                        IconImage {
                            implicitSize: 16
                            source: modelData.icon
                        }

                        Text {
                            Layout.maximumWidth: 320
                            text: modelData.title
                            elide: Text.ElideRight
                            color: Colors.text.color
                            font.pointSize: Colors.text.fontSize
                            font.family: Colors.text.fontFamily
                        }
                    }
                }

                // Move the workspace to another screen
                RowLayout {
                    visible: !special && otherScreens.length > 0
                    spacing: 4

                    readonly property var otherScreens: Quickshell.screens.filter(s => s.name !== workspaces.screen.name)

                    Text {
                        text: "Move to"
                        color: Colors.text.secondary
                        font.pointSize: Colors.text.fontSize
                        font.family: Colors.text.fontFamily
                    }

                    Repeater {
                        model: parent.otherScreens

                        GhostButton {
                            required property ShellScreen modelData
                            text: modelData.name
                            font.family: Colors.text.fontFamily
                            onClicked: Hyprland.dispatch(`hl.dsp.workspace.move({ workspace = "${workspaceItem.modelData.id}", monitor = "${modelData.name}" })`)
                        }
                    }
                }
            }
        }
    }
}
