import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
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

        // Cover with rounded corners and a soft shadow
        Item {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 4
            Layout.bottomMargin: 8
            implicitWidth: 150
            implicitHeight: 150

            RectangularShadow {
                anchors.fill: cover
                radius: cover.radius
                offset.y: 6
                blur: 20
                color: Qt.rgba(0, 0, 0, 0.25)
            }

            ClippingRectangle {
                id: cover
                anchors.fill: parent
                radius: 12
                color: "transparent"

                Image {
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    sourceSize.width: 300
                    sourceSize.height: 300
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignCenter
            color: Colors.text.color
            text: root.formatTitle(root.player)
            font.family: Colors.text.fontFamily
        }

        // Progress indicator
        MusicProgressBar {
            player: root.player
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.alignment: Qt.AlignCenter
            GhostButton {
                id: prevButton
                visible: !!root.player
                contentItem: MediaIcon {
                    id: prevIcon
                    kind: "previous"
                    color: prevButton.textColor
                }
                onClicked: {
                    prevIcon.animate();
                    root.player.previous();
                }
            }
            GhostButton {
                id: playButton
                visible: !!root.player && ((root.player.canPause && root.player.playbackState == MprisPlaybackState.Playing) || (root.player.canPlay && root.player.playbackState == MprisPlaybackState.Paused))
                contentItem: MediaIcon {
                    id: playIcon
                    kind: "playpause"
                    playing: root.player?.playbackState == MprisPlaybackState.Playing
                    color: playButton.textColor
                }
                onClicked: {
                    playIcon.animate();
                    if (root.player.playbackState == MprisPlaybackState.Playing) {
                        root.player.pause();
                    } else {
                        root.player.play();
                    }
                }
            }
            GhostButton {
                id: nextButton
                visible: !!root.player
                contentItem: MediaIcon {
                    id: nextIcon
                    kind: "next"
                    color: nextButton.textColor
                }
                onClicked: {
                    nextIcon.animate();
                    root.player.next();
                }
            }
            GhostButton {
                id: repeatButton
                visible: !!root.player && root.player.canControl && root.player.loopSupported
                contentItem: MediaIcon {
                    id: repeatIcon
                    kind: "repeat"
                    one: root.player?.loopState == MprisLoopState.Track
                    color: repeatButton.textColor
                }
                onClicked: {
                    repeatIcon.animate();
                    const arr = [MprisLoopState.None, MprisLoopState.Playlist, MprisLoopState.Track];
                    const currentIndex = arr.indexOf(root.player.loopState);
                    const nextIndex = (currentIndex + 1) % arr.length;
                    root.player.loopState = arr[nextIndex];
                }
                textColor: root.player.loopState == MprisLoopState.None ? Colors.text.disabled : Colors.text.color
            }
        }

        function formatTitle(player) {
            if (!player)
                return "";
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
