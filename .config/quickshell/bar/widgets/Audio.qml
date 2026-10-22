import "root:/config"
import "root:/utils"
import "root:/widgets/audio"
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

// Volume of the default output. Scroll to change it.
// A left click opens a popup to select the output and input devices and to set their volume,
// a right click opens the volume of each application, like pavucontrol.
Item {
    id: root
    property var screen
    property bool open: false
    // "devices" or "playback"
    property string page: "devices"

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    // Hardware devices only, not the streams of the applications
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)
    // Streams of the applications that play audio
    readonly property var streams: Pipewire.nodes.values.filter(n => n.audio && n.isSink && n.isStream)

    Layout.preferredWidth: button.width
    implicitHeight: parent.height

    // The audio properties (volume, muted) are only valid on bound nodes
    PwObjectTracker {
        objects: root.sinks.concat(root.sources, root.streams)
    }

    function nodeName(node) {
        return node.nickname || node.description || node.name;
    }

    // Wheel up and down change the volume by 5%
    function scrollVolume(audio, wheel) {
        if (audio && wheel.angleDelta.y !== 0) {
            audio.volume = Math.max(0, Math.min(1, audio.volume + Math.sign(wheel.angleDelta.y) * 0.05));
        }
    }

    // Icon of the stream, else of the desktop entry of the application.
    // Empty if the icon theme has neither.
    function streamIcon(node) {
        const props = node.properties;
        const name = props["application.process.binary"] || props["application.name"] || "";
        const icon = [props["application.icon-name"], Icons.getDesktopEntry(name)?.icon].find(i => i && (i.startsWith("/") || Quickshell.hasThemeIcon(i)));
        return icon ? Quickshell.iconPath(icon) : "";
    }

    function streamName(node) {
        return node.properties["application.name"] || nodeName(node);
    }

    // Opens the page, or closes the popup if the page is already open
    function toggle(page) {
        if (open && root.page === page) {
            open = false;
        } else {
            root.page = page;
            open = true;
        }
    }

    // Close the popup when the mouse is on neither the button nor the popup
    property bool dragging: false
    property bool hovered: buttonHover.hovered || popupHover.hovered || dragging
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
            readonly property bool muted: !root.sink?.audio || root.sink.audio.muted

            SpeakerIcon {
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 14
                muted: label.muted
                volume: root.sink?.audio?.volume ?? 0
            }

            Text {
                visible: !label.muted
                anchors.verticalCenter: parent.verticalCenter
                text: `${Math.round((root.sink?.audio?.volume ?? 0) * 100)}%`
                color: Colors.text.color
                font.pointSize: Colors.text.fontSize
                font.family: Colors.text.fontFamily
            }
        }

        HoverArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => root.toggle(mouse.button === Qt.RightButton ? "playback" : "devices")
            onWheel: wheel => root.scrollVolume(root.sink?.audio, wheel)
        }
    }

    PopupWrapper {
        id: popup
        requestOpen: root.open
        anchors.right: button.right
        anchors.top: button.bottom
        screen: root.screen

        // A layout ignores the hidden page, so the popup has the size of the visible one
        ColumnLayout {
            width: Math.max(implicitWidth, 260)

            ColumnLayout {
                visible: root.page === "devices"
                Layout.fillWidth: true
                spacing: 2

                SectionTitle {
                    text: "Output"
                }

                Repeater {
                    model: root.sinks

                    DeviceRow {
                        required property PwNode modelData
                        Layout.fillWidth: true
                        label: root.nodeName(modelData)
                        checked: modelData === root.sink
                        onClicked: Pipewire.preferredDefaultAudioSink = modelData
                    }
                }

                VolumeRow {
                    Layout.fillWidth: true
                    node: root.sink
                }

                Divider {}

                SectionTitle {
                    text: "Input"
                }

                Repeater {
                    model: root.sources

                    DeviceRow {
                        required property PwNode modelData
                        Layout.fillWidth: true
                        label: root.nodeName(modelData)
                        checked: modelData === root.source
                        onClicked: Pipewire.preferredDefaultAudioSource = modelData
                    }
                }

                VolumeRow {
                    Layout.fillWidth: true
                    node: root.source
                    input: true
                }
            }

            ColumnLayout {
                visible: root.page === "playback"
                Layout.fillWidth: true
                spacing: 2

                SectionTitle {
                    text: "Playback"
                }

                SectionTitle {
                    visible: root.streams.length === 0
                    text: "No application plays audio"
                    color: Colors.text.disabled
                }

                Repeater {
                    model: root.streams

                    ColumnLayout {
                        required property PwNode modelData
                        Layout.fillWidth: true
                        spacing: 0

                        RowLayout {
                            Layout.leftMargin: 6
                            spacing: 6

                            IconImage {
                                id: appIcon
                                visible: source != ""
                                implicitSize: 16
                                source: root.streamIcon(modelData)
                            }

                            SpeakerIcon {
                                visible: !appIcon.visible
                                width: 16
                                height: 16
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.maximumWidth: 300
                                text: root.streamName(modelData)
                                elide: Text.ElideRight
                                color: Colors.text.color
                                font.pointSize: Colors.text.fontSize
                                font.family: Colors.text.fontFamily
                            }
                        }

                        VolumeRow {
                            Layout.fillWidth: true
                            node: modelData
                        }
                    }
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

    component SectionTitle: Text {
        Layout.leftMargin: 6
        Layout.bottomMargin: 2
        color: Colors.text.secondary
        font.pointSize: Colors.text.fontSize
        font.family: Colors.text.fontFamily
        font.weight: Font.Medium
    }

    component Divider: Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        implicitHeight: 1
        color: Colors.workspaceCircle
    }

    // A device, with a radio button that shows if it is the default
    component DeviceRow: Rectangle {
        id: row
        property string label
        property bool checked
        signal clicked

        implicitWidth: rowContent.implicitWidth + 12
        implicitHeight: 22
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

            Rectangle {
                implicitWidth: 14
                implicitHeight: 14
                radius: 7
                color: "transparent"
                border.width: 1.5
                border.color: row.checked ? Colors.text.color : Colors.text.secondary

                Rectangle {
                    visible: row.checked
                    anchors.centerIn: parent
                    width: 6
                    height: 6
                    radius: 3
                    color: Colors.text.color
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.maximumWidth: 320
                text: row.label
                elide: Text.ElideRight
                color: Colors.text.color
                font.pointSize: Colors.text.fontSize
                font.family: Colors.text.fontFamily
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }
    }

    // Mute button, volume bar and volume in percent of a node
    component VolumeRow: RowLayout {
        id: volumeRow
        property PwNode node
        // Shows a microphone, not a speaker
        property bool input: false
        readonly property PwNodeAudio audio: node?.audio ?? null

        visible: audio !== null
        spacing: 6
        Layout.leftMargin: 2
        Layout.rightMargin: 6

        Rectangle {
            id: muteButton
            implicitWidth: 22
            implicitHeight: 22
            radius: 6
            color: root.isUnderMouse(muteButton) ? Colors.workspaceCircleActive : Qt.rgba(1, 1, 1, 0)

            Behavior on color {
                ColorAnimation {
                    duration: 120
                    easing.type: Easing.InOutQuad
                }
            }

            SpeakerIcon {
                visible: !volumeRow.input
                anchors.centerIn: parent
                width: 14
                height: 14
                muted: volumeRow.audio?.muted ?? false
                volume: volumeRow.audio?.volume ?? 0
            }

            MicIcon {
                visible: volumeRow.input
                anchors.centerIn: parent
                width: 14
                height: 14
                muted: volumeRow.audio?.muted ?? false
            }

            MouseArea {
                id: muteMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: volumeRow.audio.muted = !volumeRow.audio.muted
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 22

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Colors.workspaceCircle

                Rectangle {
                    width: parent.width * Math.min(1, volumeRow.audio?.volume ?? 0)
                    height: parent.height
                    radius: parent.radius
                    color: volumeRow.audio?.muted ? Colors.text.disabled : Colors.text.color
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => setVolume(mouse.x)
                onPositionChanged: mouse => setVolume(mouse.x)
                onPressedChanged: root.dragging = pressed
                onWheel: wheel => root.scrollVolume(volumeRow.audio, wheel)

                function setVolume(x) {
                    volumeRow.audio.volume = Math.max(0, Math.min(1, x / width));
                }
            }
        }

        Text {
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignRight
            text: `${Math.round((volumeRow.audio?.volume ?? 0) * 100)}%`
            color: Colors.text.color
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }
    }
}
