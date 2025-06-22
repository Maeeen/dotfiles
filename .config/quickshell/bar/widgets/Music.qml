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

Item {
    id: root
    property list<MprisPlayer> players: Mpris.players.values
    property MprisPlayer currentPlayer: pickPlayer(players)
    property MprisPlayer player: currentPlayer

    property bool requestOpen: true
    property bool isHovered: false

    Layout.preferredWidth: content.width
    implicitHeight: parent.height

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            root.isHovered = true;
            openTimer.restart();
        }
        onExited: {
            root.isHovered = false;
            openTimer.stop();
            root.requestOpen = false;
        }
    }

    Timer {
        id: openTimer
        interval: 200
        running: false
        repeat: false
        onTriggered: {
            root.requestOpen = true;
        }
    }

    Rectangle {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        implicitWidth: Math.max(title.implicitWidth + 20, 150)
        color: getBackgroundColor(currentPlayer)
        clip: true

        RowLayout {
            id: actualContent
            anchors.fill: parent

            Text {
                id: title
                Layout.alignment: Qt.AlignCenter

                text: formatTitle(currentPlayer)
            }
        }

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }
    }

    function formatTitle(player) {
        if (!player)
            return "Not today :(";
        const title = player.trackTitle;
        const artist = player.trackArtist;
        if (title && artist) {
            return `${title} ⋅ ${artist}`;
        }
        return title || artist || "…";
    }

    function pickPlayer(players) {
        // Priority, pick one that plays
        const playing = players.filter(p => p.isPlaying);
        if (playing)
            return playing[0];
        const spotify = players.filter(p => p.identity == "Spotify");
        if (spotify)
            return spotify[0];
    }

    function getBackgroundColor(player) {
        if (player.identity == "Spotify") {
            return Colors.backgrounds.spotify;
        }
        return Colors.backgrounds.music;
    }

    PopupWrapper {
        id: popup
        requestOpen: root.requestOpen
        anchors.left: content.left
        anchors.top: content.bottom

        ColumnLayout {
            IconImage {
                Layout.alignment: Qt.AlignCenter
                width: 100
                height: 100
                source: root.currentPlayer.trackArtUrl
            }

            Text {
                Layout.alignment: Qt.AlignCenter
                color: Colors.text.color
                text: formatTitle(currentPlayer)
            }

            // Progress indicator
            ProgressBar {
                value: root.currentPlayer.position
                implicitWidth: 200
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignCenter
                from: 0
                to: root.currentPlayer.length
            }

            RowLayout {
                Layout.alignment: Qt.AlignCenter
                GhostButton {
                    text: "skip_previous"
                    font.family: "Material Icons"
                    onClicked: {
                        root.player.previous();
                    }
                }
                GhostButton {
                    text: root.player.playbackState == MprisPlaybackState.Playing ? "pause" : "play_arrow"
                    font.family: "Material Icons"
                    onClicked: {
                        if (root.player.playbackState == MprisPlaybackState.Playing) {
                            root.player.pause();
                        } else {
                            root.player.play();
                        }
                    }
                }
                GhostButton {
                    text: "skip_next"
                    font.family: "Material Icons"
                    onClicked: {
                        root.player.next();
                    }
                }
                GhostButton {
                    text: {
                        if (root.player.loopStatus == MprisLoopStatus.None) {
                            console.log("none")
                            return "play_arrow";
                        } else if (root.player.loopStatus == MprisLoopStatus.Track) {
                            console.log("track")
                            return "pause";
                        } else {
                            console.log("playlist")
                            return "play_arrow";
                        }
                    }
                    font.family: "Material Icons"
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
                            color: btn.player == currentPlayer ? Colors.c("#eeeeeeae") : Colors.c("#dddddd4e")
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
                                root.currentPlayer = btn.player;
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        // only emit the signal when the position is actually changing.
        running: currentPlayer.playbackState == MprisPlaybackState.Playing
        // Make sure the position updates at least once per second.
        interval: 1000
        repeat: true
        // emit the positionChanged signal every second.
        onTriggered: {
            currentPlayer.positionChanged();
        }
    }

    PopupEdges {
        popout: popup
        anchors.top: content.bottom
    }
}
