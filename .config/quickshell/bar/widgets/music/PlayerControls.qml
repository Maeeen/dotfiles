import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "root:/utils"
import "root:/config"
import "root:/widgets/music"
import "root:/widgets"

Item {
    id: wrapper
    property MprisPlayer player
    // implicitHeight: Math.max(root.implicitHeight, 100)
    // implicitWidth: Math.max(root.implicitWidth, 200)
    //
    implicitHeight: Math.max(root.implicitHeight, 200)
    implicitWidth: Math.max(root.implicitWidth, 200)

    width: Math.max(root.width, 200)
    height: Math.max(root.height, 200)

    ColumnLayout {
        id: root
        property MprisPlayer player: wrapper.player
        anchors.fill: parent

        IconImage {
            Layout.alignment: Qt.AlignCenter
            width: 150
            height: 150
            source: root.player.trackArtUrl
        }

        Text {
            Layout.alignment: Qt.AlignCenter
            color: Colors.text.color
            text: root.formatTitle(root.player)
        }

        // Progress indicator
        MusicProgressBar {
            player: root.player
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.alignment: Qt.AlignCenter
            GhostButton {
                visible: !!root.player
                text: "skip_previous"
                font.family: "Material Icons"
                onClicked: {
                    root.player.previous();
                }
            }
            GhostButton {
                visible: !!root.player && ((root.player.canPause && root.player.playbackState == MprisPlaybackState.Playing) || (root.player.canPlay && root.player.playbackState == MprisPlaybackState.Paused))
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
                visible: !!root.player
                text: "skip_next"
                font.family: "Material Icons"
                onClicked: {
                    root.player.next();
                }
            }
            GhostButton {
                visible: !!root.player && root.player.canControl && root.player.loopSupported
                text: {
                    if (root.player.loopState == MprisLoopState.Track) {
                        return "repeat_one";
                    } else {
                        return "repeat";
                    }
                }
                onClicked: {
                    const arr = [MprisLoopState.None, MprisLoopState.Playlist, MprisLoopState.Track];
                    const currentIndex = arr.indexOf(root.player.loopState);
                    const nextIndex = (currentIndex + 1) % arr.length;
                    root.player.loopState = arr[nextIndex];
                }
                textColor: root.player.loopState == MprisLoopState.None ? Colors.text.disabled : Colors.text.color
                font.family: "Material Icons"
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
    }
}
