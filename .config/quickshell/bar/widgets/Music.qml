import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "root:/config"
import "root:/utils"
import "root:/serv"
import "root:/utils"
import "root:/widgets/music"

Item {
    id: root
    property list<MprisPlayer> players: MusicState.players
    property MprisPlayer current: MusicState.mainPlayer
    property var screen

    property bool requestOpen: false

    Layout.preferredWidth: content.width
    implicitHeight: parent.height

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            root.requestOpen = true;
        }
        onExited: {
            root.requestOpen = false;
        }
    }

    // Back
    Rectangle {
        id: back
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        implicitWidth: content.implicitWidth
        implicitHeight: parent.height
        clip: true
        color: root.current.positionSupported ? "transparent" : root.getBackgroundColor(root.current)

        Rectangle {
            visible: root.current.positionSupported
            color: root.getBackgroundColor(root.current)
            anchors.left: parent.left

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            implicitWidth: (root.current.position / root.current.length) * parent.width
        }

        Rectangle {
            visible: root.current.positionSupported
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: Qt.darker(root.getBackgroundColor(root.current), 1.2)
            anchors.right: parent.right
            implicitWidth: (1 - (root.current.position / root.current.length)) * parent.width
        }
    }

    // Text
    Rectangle {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        implicitWidth: Math.max(title.implicitWidth + 20, 150)
        color: "transparent"
        clip: true

        RowLayout {
            id: actualContent
            anchors.fill: parent

            Text {
                id: title
                Layout.alignment: Qt.AlignCenter

                text: root.formatTitle(root.current)
            }
        }

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }
    }

    PopupWrapper {
        id: popup
        requestOpen: root.requestOpen
        anchors.left: content.left
        anchors.top: content.bottom
        screen: root.screen

        ColumnLayout {
            id: columnMain

            Tabulable {
                id: tabulatable
                selectedIndex: root.players.indexOf(root.current)
                Repeater {
                    model: root.players
                    PlayerControls {
                        player: modelData
                    }
                }
            }
            // Player picker
            RowLayout {
                Layout.alignment: Qt.AlignCenter

                Repeater {
                    model: root.players
                    Button {
                        id: btn
                        property MprisPlayer player: modelData

                        implicitWidth: 32
                        implicitHeight: 32

                        background: Rectangle {
                            width: btn.width
                            height: btn.height
                            radius: 6
                            border.width: 1
                            color: btn.player == current ? Colors.c("#eeeeeeae") : Colors.c("#dddddd4e")
                            border.color: btn.down ? "#dddddd" : (btn.hovered ? "#f0f0f0" : "#ffffff")

                            Image {
                                anchors.centerIn: parent
                                height: 24
                                width: 24
                                source: Icons.getPlayerIcon(btn.player)
                            }
                        }

                        hoverEnabled: true
                        clip: true
                        padding: 4

                        onClicked: {
                            if (btn.player) {
                                MusicState.mainPlayer = btn.player;
                            }
                        }
                    }
                }
            }
        }
    }

    PopupEdges {
        popout: popup
        anchors.top: content.bottom
    }

    function formatTitle(player) {
        if (!player)
            return "Not today :(";
        const title = player.trackTitle;
        const artist = player.trackArtist;
        if (title && artist) {
            return `${title} ⋅ ${artist}`;
        }
        if (title || artist)
            return title || artist;
        if (player.metadata && player.metadata["xesam:url"]) {
            // return basename
            // of the URL as a fallback title
            const url = player.metadata["xesam:url"];
            const parts = url.split("/");
            const lastPart = decodeURIComponent(parts[parts.length - 1]);
            return lastPart || "…";
        }
        return title || artist || "…";
    }

    function getBackgroundColor(player) {
        if (player.identity == "Spotify") {
            return Colors.backgrounds.spotify;
        }
        return Colors.backgrounds.music;
    }

    // Behavior
    Timer {
        // only emit the signal when the position is actually changing.
        running: root.current.playbackState == MprisPlaybackState.Playing
        // Make sure the position updates at least once per second.
        interval: 1000
        repeat: true
        // emit the positionChanged signal every second.
        onTriggered: {
            root.current.positionChanged();
        }
    }
}
