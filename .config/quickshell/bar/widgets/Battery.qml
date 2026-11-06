import "root:/config"
import "root:/utils"
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// Same design as the music element: constant width,
// the background is filled to the battery level.
// A click opens a popup with the battery graph and the power profiles.
Item {
    id: root
    property var screen
    property bool open: false
    // One sample each minute, for up to 6 hours
    readonly property int historySize: 360
    property var history: []
    // power-profiles-daemon is necessary to change the profile
    property bool profilesAvailable: false
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

    // "2 h 10 min left", "1 h 5 min to full"
    function timeText() {
        const s = charging ? device.timeToFull : device.timeToEmpty;
        if (full)
            return "Full";
        if (!(s > 0))
            return charging ? "Charging" : "";
        const h = Math.floor(s / 3600);
        const m = Math.round(s % 3600 / 60);
        return (h > 0 ? `${h} h ${m} min` : `${m} min`) + (charging ? " to full" : " left");
    }

    function durationText(minutes) {
        return minutes < 60 ? `${minutes} min` : `${(minutes / 60).toFixed(minutes < 600 ? 1 : 0)} h`;
    }

    Timer {
        interval: 60000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.history = root.history.concat([root.percentage]).slice(-root.historySize)
    }

    // Is power-profiles-daemon on the system bus?
    Process {
        running: root.open
        command: ["busctl", "--system", "status", "org.freedesktop.UPower.PowerProfiles"]
        onExited: code => root.profilesAvailable = code === 0
        stdout: StdioCollector {}
    }

    // Close the popup when the mouse is on neither the battery nor the popup
    property bool hovered: buttonHover.hovered || popupHover.hovered
    onHoveredChanged: {
        if (hovered) {
            closeDelay.stop();
        } else if (open) {
            closeDelay.restart();
        }
    }

    Timer {
        id: closeDelay
        // Give the mouse time to move from the battery to the popup
        interval: Config.popupCloseDelay
        onTriggered: root.open = false
    }

    HoverHandler {
        id: buttonHover
    }

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

    HoverArea {
        anchors.fill: parent
        onClicked: root.open = !root.open
    }

    PopupWrapper {
        id: popup
        requestOpen: root.open
        anchors.right: parent.right
        anchors.top: parent.bottom
        screen: root.screen

        ColumnLayout {
            width: 280
            spacing: 4

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: `Battery ${Math.round(root.percentage * 100)}%`
                    color: Colors.text.secondary
                    font.pointSize: Colors.text.fontSize
                    font.family: Colors.text.fontFamily
                    font.weight: Font.Medium
                }

                Text {
                    text: root.timeText()
                    color: Colors.text.color
                    font.pointSize: Colors.text.fontSize
                    font.family: Colors.text.fontFamily
                }
            }

            Graph {
                Layout.fillWidth: true
                values: root.history
                count: Math.max(2, root.history.length)
                color: root.backgroundColor
            }

            Text {
                text: root.history.length > 1 ? `Last ${root.durationText(root.history.length - 1)}` : "The graph starts in a minute"
                color: Colors.text.secondary
                font.pointSize: Colors.text.fontSize - 2
                font.family: Colors.text.fontFamily
            }

            Text {
                Layout.topMargin: 6
                text: "Power profile"
                color: Colors.text.secondary
                font.pointSize: Colors.text.fontSize
                font.family: Colors.text.fontFamily
                font.weight: Font.Medium
            }

            RowLayout {
                visible: root.profilesAvailable
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: [
                        { profile: PowerProfile.PowerSaver, label: "Saver" },
                        { profile: PowerProfile.Balanced, label: "Balanced" },
                        { profile: PowerProfile.Performance, label: "Performance" }
                    ].filter(p => p.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)

                    Rectangle {
                        required property var modelData
                        readonly property bool selected: PowerProfiles.profile === modelData.profile
                        Layout.fillWidth: true
                        implicitHeight: 26
                        radius: 6
                        color: selected ? Colors.workspacePill : Colors.workspaceCircle

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                                easing.type: Easing.InOutQuad
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.label
                            color: parent.selected ? Colors.workspaceNumber : Colors.text.color
                            font.pointSize: Colors.text.fontSize - 1
                            font.family: Colors.text.fontFamily
                            font.weight: parent.selected ? Font.Medium : Font.Normal
                        }

                        HoverArea {
                            anchors.fill: parent
                            radius: parent.radius
                            onClicked: PowerProfiles.profile = parent.modelData.profile
                        }
                    }
                }
            }

            Text {
                visible: !root.profilesAvailable
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: "power-profiles-daemon is not running"
                color: Colors.text.disabled
                font.pointSize: Colors.text.fontSize - 1
                font.family: Colors.text.fontFamily
            }
        }
    }

    // Covers the popup with its margins, so the mouse on it keeps it open
    Item {
        anchors.fill: popup

        HoverHandler {
            id: popupHover
        }
    }
}
