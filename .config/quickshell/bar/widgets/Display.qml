import "root:/config"
import "root:/serv"
import "root:/utils"
import "root:/widgets/display"
import QtQuick
import QtQuick.Layouts

// Brightness of this screen. Scroll to change it.
// A click opens a popup with the brightness and, on an external monitor (DDC/CI),
// the contrast and the colors, then the layout of the monitors (Screens).
Item {
    id: root
    property var screen
    property bool open: false
    // The color part of the popup is open
    property bool colorsOpen: false
    readonly property string name: screen?.name ?? ""
    readonly property var brightness: Brightness.get(name, "10")

    // Grows in and shrinks out: hidden only when the width is 0.
    // Always shown: the popup also has the layout of the monitors.
    readonly property bool shown: true
    visible: Layout.preferredWidth > 0
    opacity: shown ? 1 : 0
    Layout.preferredWidth: shown ? button.width : 0
    // Takes the layout spacing away while it shrinks, so the next items do not jump at the end
    Layout.leftMargin: parent.spacing * (Layout.preferredWidth / button.width - 1)
    implicitHeight: parent.height

    Behavior on Layout.preferredWidth {
        WidthAnimation {}
    }

    Behavior on opacity {
        WidthAnimation {}
    }

    // The values can change with the buttons of the monitor
    onOpenChanged: {
        if (open) {
            Brightness.refresh(name);
            Monitors.refresh();
            screens.edits = {};
            screens.selected = name;
        }
    }

    function percent(v) {
        return v ? Math.round(v.value / v.max * 100) : 0;
    }

    // Wheel up and down change the value by 5% of its maximum
    function scroll(code, wheel) {
        const v = Brightness.get(name, code);
        if (v && wheel.angleDelta.y !== 0)
            Brightness.set(name, code, v.value + Math.sign(wheel.angleDelta.y) * v.max * 0.05);
    }

    // Close the popup when the mouse is on neither the button nor the popup
    property bool dragging: false
    property bool hovered: buttonHover.hovered || popupHover.hovered || dragging || screens.dragging
    onHoveredChanged: {
        if (hovered) {
            closeDelay.stop();
        } else if (open) {
            closeDelay.restart();
        }
    }

    Timer {
        id: closeDelay
        // Give the mouse time to move from the button to the popup
        interval: Config.popupCloseDelay
        onTriggered: root.open = false
    }

    Rectangle {
        id: button
        anchors.centerIn: parent
        implicitWidth: label.implicitWidth + 12
        implicitHeight: root.height
        color: root.open ? Colors.workspaceCircleActive : "transparent"

        HoverHandler {
            id: buttonHover
        }

        Row {
            id: label
            anchors.centerIn: parent
            spacing: 4

            SunIcon {
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 14
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.brightness !== null
                text: `${root.percent(root.brightness)}%`
                color: Colors.text.color
                font.pointSize: Colors.text.fontSize
                font.family: Colors.text.fontFamily
            }
        }

        HoverArea {
            anchors.fill: parent
            onClicked: root.open = !root.open
            onWheel: wheel => root.scroll("10", wheel)
        }
    }

    PopupWrapper {
        id: popup
        requestOpen: root.open
        anchors.right: button.right
        anchors.top: button.bottom
        screen: root.screen

        ColumnLayout {
            width: 300
            spacing: 2

            SectionTitle {
                text: root.screen?.model || root.name
            }

            Slider {
                code: "10"
                label: "Brightness"
            }

            Slider {
                code: "12"
                label: "Contrast"
            }

            // Opens and closes the color part
            Rectangle {
                id: colorToggle
                visible: Brightness.get(root.name, "0C") !== null || Brightness.get(root.name, "16") !== null
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: 22
                radius: 6
                // Transparent white when off, so the fade does not go through gray
                color: root.isUnderMouse(colorToggle) ? Colors.workspaceCircleActive : Qt.rgba(1, 1, 1, 0)

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                        easing.type: Easing.InOutQuad
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 6
                    spacing: 6

                    Text {
                        text: "›"
                        rotation: root.colorsOpen ? 90 : 0
                        color: Colors.text.color
                        font.pointSize: Colors.text.fontSize
                        font.family: Colors.text.fontFamily

                        Behavior on rotation {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    Text {
                        text: "Color"
                        color: Colors.text.color
                        font.pointSize: Colors.text.fontSize
                        font.family: Colors.text.fontFamily
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.colorsOpen = !root.colorsOpen
                }
            }

            ColumnLayout {
                visible: root.colorsOpen && colorToggle.visible
                Layout.fillWidth: true
                spacing: 2

                Slider {
                    code: "0C"
                    label: "Temperature"
                }

                SectionTitle {
                    Layout.topMargin: 4
                    text: "Gain"
                }

                Slider {
                    code: "16"
                    label: "Red"
                }

                Slider {
                    code: "18"
                    label: "Green"
                }

                Slider {
                    code: "1A"
                    label: "Blue"
                }

                SectionTitle {
                    Layout.topMargin: 4
                    text: "Black level"
                }

                Slider {
                    code: "6C"
                    label: "Red"
                }

                Slider {
                    code: "6E"
                    label: "Green"
                }

                Slider {
                    code: "70"
                    label: "Blue"
                }
            }

            SectionTitle {
                Layout.topMargin: 8
                text: "Screens"
            }

            Screens {
                id: screens
                Layout.fillWidth: true
                screenName: root.name
                isUnderMouse: item => root.isUnderMouse(item)
            }
        }
    }

    // An item of the popup is lit when the mouse position of the popup HoverHandler is in it.
    // Qt can lose the enter and leave events of the items, so they do not use their own hover state.
    function isUnderMouse(item) {
        if (!popupHover.hovered)
            return false;
        return item.contains(item.mapFromItem(popupCover, popupHover.point.position));
    }

    // Covers the popup with its margins, without taking the clicks
    Item {
        id: popupCover
        anchors.fill: popup

        HoverHandler {
            id: popupHover
        }
    }

    component SectionTitle: Text {
        Layout.leftMargin: 6
        Layout.bottomMargin: 2
        color: Colors.text.secondary
        font.pointSize: Colors.text.fontSize
        font.family: Colors.text.fontFamily
        font.weight: Font.Medium
    }

    // Name, bar and value in percent of a VCP code. Hidden when the monitor does not have the code.
    component Slider: RowLayout {
        id: slider
        property string code
        property string label
        readonly property var current: Brightness.get(root.name, code)

        visible: current !== null
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        spacing: 8

        Text {
            Layout.preferredWidth: 84
            text: slider.label
            color: Colors.text.color
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 22

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Colors.workspaceCircle

                Rectangle {
                    width: parent.width * root.percent(slider.current) / 100
                    height: parent.height
                    radius: parent.radius
                    color: Colors.text.color
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => setValue(mouse.x)
                onPositionChanged: mouse => setValue(mouse.x)
                onPressedChanged: root.dragging = pressed
                onWheel: wheel => root.scroll(slider.code, wheel)

                function setValue(x) {
                    Brightness.set(root.name, slider.code, Math.max(0, Math.min(1, x / width)) * slider.current.max);
                }
            }
        }

        Text {
            Layout.preferredWidth: 30
            horizontalAlignment: Text.AlignRight
            text: `${root.percent(slider.current)}%`
            color: Colors.text.color
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }
    }
}
