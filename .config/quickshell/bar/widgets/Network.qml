import "root:/config"
import "root:/utils"
import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// Network icon: the Wi-Fi signal, or a cable when only the wired network is connected.
// A click opens a popup to turn Wi-Fi on and off, and to connect to or disconnect from a network.
// A new network with a password shows a password field.
Item {
    id: root
    property var screen
    property bool open: false

    readonly property var devices: Networking.devices.values
    readonly property WifiDevice wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property WiredDevice wired: devices.find(d => d.type === DeviceType.Wired) ?? null
    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property var wifiNetworks: wifi?.networks.values ?? []
    readonly property WifiNetwork current: wifiNetworks.find(n => n.connected) ?? null
    // Connected first, then known, then by signal
    readonly property var networks: wifiNetworks.filter(n => n.name).sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength)).slice(0, 12)

    // Network that shows the password field, null when none
    property WifiNetwork passwordFor: null
    property string error: ""

    visible: wifi !== null || wired !== null
    Layout.preferredWidth: button.width
    implicitHeight: parent.height

    Behavior on Layout.preferredWidth {
        WidthAnimation {}
    }

    // Scan while the popup is open
    onOpenChanged: {
        if (wifi)
            wifi.scannerEnabled = open;
        if (!open) {
            passwordFor = null;
            error = "";
        }
    }

    // The password field needs the keyboard
    onPasswordForChanged: PopupsState.keyboardScreen = passwordFor ? (screen?.name ?? "") : ""

    function isOpen(n) {
        return n.security === WifiSecurityType.Open || n.security === WifiSecurityType.Owe;
    }

    function activate(n) {
        error = "";
        if (n.connected)
            n.disconnect();
        else if (n.known || isOpen(n))
            n.connect();
        else
            passwordFor = passwordFor === n ? null : n;
    }

    function status(n) {
        if (n.state === ConnectionState.Connecting)
            return "Connecting…";
        if (n.state === ConnectionState.Disconnecting)
            return "Disconnecting…";
        return "";
    }

    // Close the popup when the mouse is on neither the button nor the popup.
    // It stays open while the password field shows.
    property bool hovered: buttonHover.hovered || popupHover.hovered || passwordFor !== null
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

    // A wrong or missing password: ask for it
    Instantiator {
        model: root.wifiNetworks

        Connections {
            required property WifiNetwork modelData
            target: modelData
            function onConnectionFailed(reason) {
                if (reason === ConnectionFailReason.NoSecrets) {
                    root.error = "Wrong password";
                    root.passwordFor = modelData;
                } else {
                    root.error = "Cannot connect";
                }
            }
        }
    }

    Rectangle {
        id: button
        anchors.centerIn: parent
        implicitWidth: icon.width + 12
        implicitHeight: root.height
        color: root.open ? Colors.workspaceCircleActive : "transparent"

        HoverHandler {
            id: buttonHover
        }

        Item {
            id: icon
            anchors.centerIn: parent
            width: 14
            height: 14

            WiredIcon {
                visible: !root.current && (root.wired?.connected ?? false)
                anchors.fill: parent
            }

            WifiIcon {
                visible: !(!root.current && (root.wired?.connected ?? false))
                anchors.fill: parent
                strength: root.current?.signalStrength ?? 0
                color: root.wifiOn ? Colors.text.color : Colors.text.disabled
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

            // Wired network, when there is a wired device
            RowLayout {
                visible: root.wired !== null
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.bottomMargin: 4
                spacing: 6

                WiredIcon {
                    implicitWidth: 16
                    implicitHeight: 16
                }

                Text {
                    Layout.fillWidth: true
                    text: "Ethernet"
                    color: Colors.text.color
                    font.pointSize: Colors.text.fontSize
                    font.family: Colors.text.fontFamily
                }

                Text {
                    text: root.wired?.connected ? "Connected" : (root.wired?.hasLink ? "Not connected" : "No cable")
                    color: Colors.text.secondary
                    font.pointSize: Colors.text.fontSize
                    font.family: Colors.text.fontFamily
                }
            }

            RowLayout {
                visible: root.wifi !== null
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.bottomMargin: 2

                Text {
                    Layout.fillWidth: true
                    text: "Wi-Fi"
                    color: Colors.text.secondary
                    font.pointSize: Colors.text.fontSize
                    font.family: Colors.text.fontFamily
                    font.weight: Font.Medium
                }

                // On and off switch
                Rectangle {
                    implicitWidth: 30
                    implicitHeight: 16
                    radius: 8
                    color: root.wifiOn ? Colors.workspaceCircleActive : Colors.workspaceCircle

                    Rectangle {
                        x: root.wifiOn ? parent.width - width - 2 : 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12
                        height: 12
                        radius: 6
                        color: root.wifiOn ? Colors.text.color : Colors.text.disabled

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
                        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }
            }

            Text {
                visible: root.wifi !== null && (!root.wifiOn || root.networks.length === 0)
                Layout.leftMargin: 6
                text: !root.wifiOn ? "Wi-Fi is off" : "Scanning…"
                color: Colors.text.disabled
                font.pointSize: Colors.text.fontSize
                font.family: Colors.text.fontFamily
            }

            Repeater {
                model: root.wifiOn ? root.networks : []

                ColumnLayout {
                    id: entry
                    required property WifiNetwork modelData
                    Layout.fillWidth: true
                    spacing: 2

                    NetworkRow {
                        Layout.fillWidth: true
                        network: entry.modelData
                    }

                    // Password of a new network. Enter connects, Escape cancels.
                    Rectangle {
                        visible: root.passwordFor === entry.modelData
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        Layout.rightMargin: 6
                        implicitHeight: 26
                        radius: 6
                        color: Colors.workspaceCircle

                        onVisibleChanged: {
                            if (visible) {
                                password.text = "";
                                password.forceActiveFocus();
                            }
                        }

                        TextInput {
                            id: password
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            echoMode: TextInput.Password
                            color: Colors.text.color
                            selectionColor: Colors.workspaceCircleActive
                            font.pointSize: Colors.text.fontSize
                            font.family: Colors.text.fontFamily

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (text) {
                                        root.error = "";
                                        entry.modelData.connectWithPsk(text);
                                        root.passwordFor = null;
                                    }
                                } else if (event.key === Qt.Key_Escape) {
                                    root.passwordFor = null;
                                } else {
                                    return;
                                }
                                event.accepted = true;
                            }

                            Text {
                                visible: !password.text
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.error || "Password"
                                color: root.error ? Colors.text.warning : Colors.text.secondary
                                font: password.font
                            }
                        }
                    }
                }
            }

            Text {
                visible: root.error !== "" && root.passwordFor === null
                Layout.leftMargin: 6
                text: root.error
                color: Colors.text.warning
                font.pointSize: Colors.text.fontSize
                font.family: Colors.text.fontFamily
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

    // A Wi-Fi network: signal, name, a lock when it needs a password. A click connects or disconnects it.
    component NetworkRow: Rectangle {
        id: row
        property WifiNetwork network

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

            WifiIcon {
                implicitWidth: 16
                implicitHeight: 16
                strength: row.network.signalStrength
            }

            Text {
                Layout.fillWidth: true
                Layout.maximumWidth: 260
                text: row.network.name
                elide: Text.ElideRight
                color: Colors.text.color
                font.pointSize: Colors.text.fontSize
                font.family: Colors.text.fontFamily
                font.weight: row.network.connected ? Font.Medium : Font.Normal
            }

            Text {
                text: root.status(row.network)
                color: Colors.text.secondary
                font.pointSize: Colors.text.fontSize
                font.family: Colors.text.fontFamily
            }

            LockIcon {
                visible: !row.network.known && !root.isOpen(row.network)
                implicitWidth: 12
                implicitHeight: 12
            }

            // Shows that the network is connected
            Rectangle {
                visible: row.network.connected
                implicitWidth: 6
                implicitHeight: 6
                radius: 3
                color: Colors.text.color
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activate(row.network)
        }
    }

    // Three bars; the signal strength (0 to 1) sets how many are lit
    component WifiIcon: Item {
        id: wifiIcon
        property real strength: 0
        property color color: Colors.text.color
        readonly property int lit: strength > 0.66 ? 3 : (strength > 0.33 ? 2 : (strength > 0 ? 1 : 0))
        readonly property real k: width / 16

        Repeater {
            model: 3

            Rectangle {
                required property int index
                x: (1 + index * 5) * wifiIcon.k
                width: 4 * wifiIcon.k
                height: (6 + index * 4) * wifiIcon.k
                y: wifiIcon.height - height - 1 * wifiIcon.k
                radius: 1.5 * wifiIcon.k
                color: wifiIcon.color
                opacity: index < wifiIcon.lit ? 1 : 0.3
            }
        }
    }

    // A network port, drawn on a 16 x 16 grid
    component WiredIcon: Shape {
        id: wiredIcon
        property color color: Colors.text.color
        readonly property real k: width / 16

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 1.5 * wiredIcon.k
            strokeColor: wiredIcon.color
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            startX: 2 * wiredIcon.k
            startY: 14 * wiredIcon.k
            PathLine { x: 2 * wiredIcon.k; y: 6 * wiredIcon.k }
            PathLine { x: 5 * wiredIcon.k; y: 6 * wiredIcon.k }
            PathLine { x: 5 * wiredIcon.k; y: 3 * wiredIcon.k }
            PathLine { x: 11 * wiredIcon.k; y: 3 * wiredIcon.k }
            PathLine { x: 11 * wiredIcon.k; y: 6 * wiredIcon.k }
            PathLine { x: 14 * wiredIcon.k; y: 6 * wiredIcon.k }
            PathLine { x: 14 * wiredIcon.k; y: 14 * wiredIcon.k }
            PathLine { x: 2 * wiredIcon.k; y: 14 * wiredIcon.k }
        }
    }

    // A padlock, drawn on a 12 x 12 grid
    component LockIcon: Shape {
        id: lockIcon
        readonly property real k: width / 12

        preferredRendererType: Shape.CurveRenderer

        // Shackle
        ShapePath {
            strokeWidth: 1.3 * lockIcon.k
            strokeColor: Colors.text.secondary
            fillColor: "transparent"
            startX: 3.5 * lockIcon.k
            startY: 5.5 * lockIcon.k
            PathLine { x: 3.5 * lockIcon.k; y: 4 * lockIcon.k }
            PathArc { x: 8.5 * lockIcon.k; y: 4 * lockIcon.k; radiusX: 2.5 * lockIcon.k; radiusY: 2.5 * lockIcon.k }
            PathLine { x: 8.5 * lockIcon.k; y: 5.5 * lockIcon.k }
        }

        // Body
        ShapePath {
            strokeWidth: -1
            fillColor: Colors.text.secondary
            startX: 2 * lockIcon.k
            startY: 5.5 * lockIcon.k
            PathLine { x: 10 * lockIcon.k; y: 5.5 * lockIcon.k }
            PathLine { x: 10 * lockIcon.k; y: 11 * lockIcon.k }
            PathLine { x: 2 * lockIcon.k; y: 11 * lockIcon.k }
            PathLine { x: 2 * lockIcon.k; y: 5.5 * lockIcon.k }
        }
    }
}
