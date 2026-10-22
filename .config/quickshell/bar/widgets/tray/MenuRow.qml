import "root:/config"
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts

Rectangle {
    id: menuRow
    property QsMenuEntry entry: null
    property string label
    property bool active: !entry || entry.enabled
    // The tray sets this from one HoverHandler, because Qt can lose the enter and leave events of a row
    property bool hovered: mouse.containsMouse
    signal clicked

    implicitWidth: Math.max(rowContent.implicitWidth + 12, 150)
    implicitHeight: 22
    radius: 6
    // Transparent white when off, so the fade does not go through gray
    color: hovered && active ? Colors.workspaceCircleActive : Qt.rgba(1, 1, 1, 0)

    Behavior on color {
        ColorAnimation {
            duration: 120
            easing.type: Easing.InOutQuad
        }
    }

    RowLayout {
        id: rowContent
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6

        // Check box
        Rectangle {
            id: checkBox
            readonly property int checkState: menuRow.entry?.checkState ?? Qt.Unchecked
            readonly property bool checked: checkState === Qt.Checked
            visible: menuRow.entry?.buttonType === QsMenuButtonType.CheckBox
            implicitWidth: 14
            implicitHeight: 14
            radius: 4
            color: checkState === Qt.Unchecked ? "transparent" : Colors.text.color
            border.width: checkState === Qt.Unchecked ? 1.5 : 0
            border.color: Colors.text.secondary

            // Check mark, or a dash when partly checked
            Shape {
                anchors.fill: parent
                visible: checkBox.checkState !== Qt.Unchecked
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: 2
                    strokeColor: Colors.backgrounds.panel
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin

                    startX: 3.5
                    startY: checkBox.checked ? 7.5 : 7
                    PathLine {
                        x: checkBox.checked ? 6 : 7
                        y: checkBox.checked ? 10 : 7
                    }
                    PathLine {
                        x: 10.5
                        y: checkBox.checked ? 4 : 7
                    }
                }
            }
        }

        // Radio button
        Rectangle {
            readonly property bool checked: menuRow.entry?.checkState === Qt.Checked
            visible: menuRow.entry?.buttonType === QsMenuButtonType.RadioButton
            implicitWidth: 14
            implicitHeight: 14
            radius: 7
            color: "transparent"
            border.width: 1.5
            border.color: checked ? Colors.text.color : Colors.text.secondary

            Rectangle {
                visible: parent.checked
                anchors.centerIn: parent
                width: 6
                height: 6
                radius: 3
                color: Colors.text.color
            }
        }

        IconImage {
            visible: !!menuRow.entry?.icon
            implicitSize: 16
            source: menuRow.entry?.icon ?? ""
        }

        Text {
            Layout.fillWidth: true
            text: menuRow.label
            color: menuRow.active ? Colors.text.color : Colors.text.disabled
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }

        Text {
            visible: !!menuRow.entry?.hasChildren
            text: "›"
            color: Colors.text.color
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: menuRow.active
        onClicked: menuRow.clicked()
    }
}
