import "root:/config"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

RowLayout {
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
        required property HyprlandWorkspace modelData
        property bool special: modelData.id < 0
        property bool urgent: modelData.urgent
        property bool active: mouseArea.containsMouse || (special ? shownSpecial === modelData.name : modelData.active)
        property int circleSize: active ? 16 : 12
        property real textOpacity: active ? 1 : 0.4
        property real textSize: active ? 10 : 5

        Behavior on circleSize {
            NumberAnimation {
                duration: 100
                easing.type: Easing.InOutQuad
            }
        }
        Behavior on textSize {
            NumberAnimation {
                duration: 100
                easing.type: Easing.InOutQuad
            }
        }
        Behavior on textOpacity {
            NumberAnimation {
                duration: 100
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

        height: 16
        width: circleSize * appear
        Layout.preferredWidth: circleSize * appear
        // The negative part cancels the RowLayout spacing until the item has appeared.
        // Special workspaces get a small extra gap from the normal ones.
        Layout.leftMargin: ((special ? 6 : 0) + parent.spacing) * appear - parent.spacing

        Rectangle {
            id: rect
            anchors.centerIn: parent
            width: circleSize
            height: circleSize
            color: urgent ? Colors.workspaceCircleUrgent : (active ? Colors.workspaceCircleActive : Colors.workspaceCircle)
            radius: special ? 4 : width / 2
            scale: appear
            opacity: appear

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

            Text {
                visible: !special
                opacity: textOpacity
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignRight
                text: modelData.id
                color: active ? Colors.workspaceTextActive : Colors.workspaceText
                font.pointSize: textSize
                font.family: Colors.text.fontFamily
            }

            // Four-point star for special workspaces. A Shape, not a "✦" glyph,
            // because the glyph is not vertically centered in its font.
            Shape {
                id: star
                visible: special
                opacity: textOpacity
                anchors.centerIn: parent
                width: circleSize * 0.6
                height: width
                preferredRendererType: Shape.CurveRenderer

                readonly property real c: width / 2
                readonly property real inner: width * 0.12

                ShapePath {
                    strokeWidth: -1
                    fillColor: active ? Colors.workspaceTextActive : Colors.workspaceText

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
    }
}
