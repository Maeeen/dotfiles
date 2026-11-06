import "root:/config"
import "root:/serv"
import "root:/utils"
import "root:/widgets/audio"
import "root:/widgets/display"
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

// Shows the volume or the brightness for a short time when it changes, e.g. with the media keys.
PopupWrapper {
    id: root
    property PwNode sink
    // No OSD while the audio popup is open: its sliders already show the volume
    property bool suppressed: false
    // "volume" or "brightness"
    property string kind: "volume"
    // Last brightness of this screen, from 0 to 1
    property real brightness: 0

    readonly property PwNodeAudio audio: sink?.audio ?? null
    readonly property bool muted: kind === "volume" && (audio?.muted ?? false)
    readonly property real value: kind === "volume" ? (audio?.volume ?? 0) : brightness

    requestOpen: hold.running

    function show(newKind) {
        if (!started.ready || suppressed)
            return;
        kind = newKind;
        hold.restart();
    }

    Timer {
        id: hold
        interval: 1500
    }

    // The volume is set when the node is bound at start; that is not a change to show
    Timer {
        id: started
        property bool ready: false
        interval: 1000
        running: true
        onTriggered: ready = true
    }

    // The volume is the same on all screens: show it on the focused one
    Connections {
        target: root.audio
        function onVolumeChanged() {
            if (Hyprland.focusedMonitor?.name === root.screen?.name)
                root.show("volume");
        }
        function onMutedChanged() {
            if (Hyprland.focusedMonitor?.name === root.screen?.name)
                root.show("volume");
        }
    }

    // Each screen has its own brightness
    Connections {
        target: Brightness
        function onShown(screenName, value) {
            if (screenName !== root.screen?.name)
                return;
            root.brightness = value;
            root.show("brightness");
        }
    }

    RowLayout {
        width: 220
        spacing: 8

        Item {
            implicitWidth: 16
            implicitHeight: 16

            SpeakerIcon {
                anchors.fill: parent
                visible: root.kind === "volume"
                muted: root.muted
                volume: root.value
            }

            SunIcon {
                anchors.fill: parent
                visible: root.kind === "brightness"
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Colors.workspaceDot

            Rectangle {
                width: parent.width * Math.min(1, root.value)
                height: parent.height
                radius: parent.radius
                color: root.muted ? Colors.text.disabled : Colors.workspacePill

                Behavior on width {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Text {
            Layout.preferredWidth: 26
            horizontalAlignment: Text.AlignRight
            text: Math.round(root.value * 100)
            color: root.muted ? Colors.text.disabled : Colors.text.color
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }
    }
}
