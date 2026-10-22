import "root:/config"
import "root:/utils"
import Quickshell
import Quickshell.Widgets
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// Bluetooth icon, with the name of the connected device.
// A click opens a popup to turn Bluetooth on and off, to scan,
// and to connect, disconnect or pair the devices.
Item {
    id: root
    property var screen
    property bool open: false

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter?.enabled ?? false
    readonly property var allDevices: adapter?.devices.values ?? []
    readonly property var connected: allDevices.filter(d => d.connected)
    // Connected first, then paired. The other devices only show during a scan.
    readonly property var devices: allDevices.filter(d => d.paired || d.connected || adapter.discovering).sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || deviceName(a).localeCompare(deviceName(b)))

    visible: adapter !== null
    Layout.preferredWidth: button.width
    implicitHeight: parent.height

    function deviceName(device) {
        return device.name || device.deviceName || device.address;
    }

    function deviceStatus(device) {
        if (device.pairing)
            return "Pairing…";
        if (device.state === BluetoothDeviceState.Connecting)
            return "Connecting…";
        if (device.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting…";
        if (device.connected && device.batteryAvailable)
            return `${Math.round(device.battery * 100)}%`;
        return "";
    }

    function activate(device) {
        if (!device.paired) {
            device.trusted = true;
            device.pair();
        } else if (device.connected) {
            device.disconnect();
        } else {
            device.connect();
        }
    }

    // Stop the scan when the popup closes
    onOpenChanged: {
        if (!open && adapter?.discovering)
            adapter.discovering = false;
    }

    // Close the popup when the mouse is on neither the button nor the popup
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

            BluetoothIcon {
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 14
                color: root.powered ? Colors.text.color : Colors.text.disabled
            }

            Text {
                visible: root.connected.length > 0
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 120)
                elide: Text.ElideRight
                text: root.connected.length > 1 ? `${root.connected.length} devices` : (root.connected.length === 1 ? root.deviceName(root.connected[0]) : "")
                color: Colors.text.color
                font.pointSize: Colors.text.fontSize
                font.family: Colors.text.fontFamily
            }
        }

        HoverArea {
            anchors.fill: parent
            onClicked: root.open = !root.open
        }
    }

    PopupWrapper {
        id: popup
        requestOpen: root.open
        anchors.right: button.right
        anchors.top: button.bottom
        screen: root.screen

        ColumnLayout {
            width: Math.max(implicitWidth, 260)
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.bottomMargin: 2

                Text {
                    Layout.fillWidth: true
                    text: "Bluetooth"
                    color: Colors.text.secondary
                    font.pointSize: Colors.text.fontSize
                    font.family: Colors.text.fontFamily
                    font.weight: Font.Medium
                }

                // Scan for new devices
                Rectangle {
                    id: scanButton
                    visible: root.powered
                    implicitWidth: scanText.implicitWidth + 12
                    implicitHeight: 20
                    radius: 6
                    color: root.adapter?.discovering || root.isUnderMouse(scanButton) ? Colors.workspaceCircleActive : Qt.rgba(1, 1, 1, 0)

                    Text {
                        id: scanText
                        anchors.centerIn: parent
                        text: root.adapter?.discovering ? "Scanning…" : "Scan"
                        color: Colors.text.color
                        font.pointSize: Colors.text.fontSize
                        font.family: Colors.text.fontFamily
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.adapter.discovering = !root.adapter.discovering
                    }
                }

                // On and off switch
                Rectangle {
                    implicitWidth: 30
                    implicitHeight: 16
                    radius: 8
                    color: root.powered ? Colors.workspaceCircleActive : Colors.workspaceCircle

                    Rectangle {
                        x: root.powered ? parent.width - width - 2 : 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12
                        height: 12
                        radius: 6
                        color: root.powered ? Colors.text.color : Colors.text.disabled

                        Behavior on x {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.adapter.enabled = !root.adapter.enabled
                    }
                }
            }

            Text {
                visible: !root.powered || root.devices.length === 0
                Layout.leftMargin: 6
                text: !root.powered ? "Bluetooth is off" : "No device"
                color: Colors.text.disabled
                font.pointSize: Colors.text.fontSize
                font.family: Colors.text.fontFamily
            }

            Repeater {
                model: root.powered ? root.devices : []

                DeviceRow {
                    required property BluetoothDevice modelData
                    Layout.fillWidth: true
                    device: modelData
                }
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

    // A device: icon, name and status. A click connects, disconnects or pairs it.
    component DeviceRow: Rectangle {
        id: row
        property BluetoothDevice device

        implicitWidth: rowContent.implicitWidth + 12
        implicitHeight: 24
        radius: 6
        // Transparent white when off, so the fade does not go through gray
        color: root.isUnderMouse(row) ? Colors.workspaceCircleActive : Qt.rgba(1, 1, 1, 0)

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
            spacing: 6

            IconImage {
                id: deviceIcon
                visible: source != ""
                implicitSize: 16
                source: row.device.icon && Quickshell.hasThemeIcon(row.device.icon) ? Quickshell.iconPath(row.device.icon) : ""
            }

            BluetoothIcon {
                visible: !deviceIcon.visible
                width: 16
                height: 16
            }

            Text {
                Layout.fillWidth: true
                Layout.maximumWidth: 260
                text: root.deviceName(row.device)
                elide: Text.ElideRight
                color: row.device.paired ? Colors.text.color : Colors.text.secondary
                font.pointSize: Colors.text.fontSize
                font.family: Colors.text.fontFamily
                font.weight: row.device.connected ? Font.Medium : Font.Normal
            }

            Text {
                text: root.deviceStatus(row.device)
                color: Colors.text.secondary
                font.pointSize: Colors.text.fontSize
                font.family: Colors.text.fontFamily
            }

            // Shows that the device is connected
            Rectangle {
                visible: row.device.connected
                implicitWidth: 6
                implicitHeight: 6
                radius: 3
                color: Colors.text.color
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activate(row.device)
        }
    }

    // The Bluetooth rune, drawn on a 16 x 16 grid and scaled to the size of the item
    component BluetoothIcon: Shape {
        id: icon
        property color color: Colors.text.color
        readonly property real k: width / 16

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 1.5 * icon.k
            strokeColor: icon.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 4 * icon.k
            startY: 5 * icon.k
            PathLine { x: 12 * icon.k; y: 11 * icon.k }
            PathLine { x: 8 * icon.k; y: 14.5 * icon.k }
            PathLine { x: 8 * icon.k; y: 1.5 * icon.k }
            PathLine { x: 12 * icon.k; y: 5 * icon.k }
            PathLine { x: 4 * icon.k; y: 11 * icon.k }
        }
    }
}
