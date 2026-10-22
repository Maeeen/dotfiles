import "root:/config"
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// Same design as the music element: constant width,
// the background is filled to the battery level.
Item {
    id: root
    property UPowerDevice device: UPower.displayDevice
    property real percentage: device.percentage
    property bool charging: device.state == UPowerDeviceState.Charging || device.state == UPowerDeviceState.FullyCharged
    readonly property bool full: Math.round(percentage * 100) >= 100
    readonly property color backgroundColor: percentage <= 0.1 ? Colors.backgrounds.batteryCritical : (percentage <= 0.2 ? Colors.backgrounds.batteryLow : Colors.backgrounds.battery)
    // Deep tint of the background, like the music title
    readonly property color textColor: Colors.textOn(backgroundColor)

    visible: device.ready && device.isLaptopBattery
    implicitWidth: 64
    Layout.fillHeight: true

    // Charged part
    Rectangle {
        id: level
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: parent.width * root.percentage
        color: root.backgroundColor
        clip: true

        Behavior on width {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        // Charging: a light that slides over the charged part
        Rectangle {
            visible: root.charging && !root.full
            width: 40
            height: parent.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.35) }
                GradientStop { position: 1.0; color: "transparent" }
            }

            NumberAnimation on x {
                running: root.charging && !root.full
                from: -40
                to: root.width
                duration: 1500
                loops: Animation.Infinite
            }
        }
    }

    // Empty part
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: level.right
        anchors.right: parent.right
        color: Qt.darker(root.backgroundColor, 1.2)
    }

    Text {
        visible: !root.full
        anchors.centerIn: parent
        text: `${Math.round(root.percentage * 100)}%`
        color: root.textColor
        font.weight: Font.Medium
        font.pointSize: Colors.text.fontSize
        font.family: Colors.text.fontFamily
    }

    // Full: a small filled battery, not "100%"
    Item {
        visible: root.full
        anchors.centerIn: parent
        width: 18
        height: 9

        Rectangle {
            width: 16
            height: parent.height
            radius: 2
            color: "transparent"
            border.width: 1
            border.color: root.textColor

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 1
                color: root.textColor
            }
        }

        // Terminal
        Rectangle {
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: 4
            color: root.textColor
        }
    }
}
