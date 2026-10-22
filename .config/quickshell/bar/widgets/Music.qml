import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
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

    // Feedback overlay state: "playpause", "next", "previous" or "volume"
    property string flashKind: ""

    // Hidden when no music player is detected
    visible: root.players.length > 0
    Layout.preferredWidth: content.width
    Layout.fillHeight: true

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onEntered: {
            closeDelay.stop();
            root.requestOpen = true;
        }
        onExited: {
            // Give the popup time to get hovered before it closes and leaves the input mask.
            closeDelay.restart();
        }
        onClicked: mouse => {
            const p = root.current;
            if (!p)
                return;
            if (mouse.button == Qt.LeftButton && p.canTogglePlaying) {
                p.togglePlaying();
                root.flash("playpause");
            } else if (mouse.button == Qt.MiddleButton && p.canGoPrevious) {
                p.previous();
                root.flash("previous");
            } else if (mouse.button == Qt.RightButton && p.canGoNext) {
                p.next();
                root.flash("next");
            }
        }
        onWheel: wheel => {
            const audio = Pipewire.defaultAudioSink?.audio;
            if (!audio)
                return;
            audio.volume = Math.max(0, Math.min(1, audio.volume + wheel.angleDelta.y / 120 * 0.05));
            root.flash("volume");
        }
    }

    // Keeps the default sink bound, so its volume can be read and set.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Timer {
        id: closeDelay
        interval: Config.popupCloseDelay
        onTriggered: root.requestOpen = false
    }

    // Back
    Rectangle {
        id: back
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        implicitWidth: content.implicitWidth
        implicitHeight: parent.height
        clip: true
        color: root.current?.positionSupported ? "transparent" : root.getBackgroundColor(root.current)

        Rectangle {
            visible: !!root.current?.positionSupported
            color: root.getBackgroundColor(root.current)
            anchors.left: parent.left

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            implicitWidth: (root.current?.position / root.current?.length) * parent.width
        }

        Rectangle {
            visible: !!root.current?.positionSupported
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: Qt.darker(root.getBackgroundColor(root.current), 1.2)
            anchors.right: parent.right
            implicitWidth: (1 - (root.current?.position / root.current?.length)) * parent.width
        }
    }

    // Text
    Rectangle {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        implicitWidth: Math.min(Math.max(title.implicitWidth + 20, 150), 300)
        color: "transparent"
        clip: true

        RowLayout {
            id: actualContent
            anchors.fill: parent

            Text {
                id: title
                Layout.alignment: Qt.AlignCenter
                // Long titles are cut with "…" at the maximum width of the element.
                Layout.maximumWidth: 280
                elide: Text.ElideRight

                // Deep tint of the background, easier to read than plain black.
                color: Colors.textOn(root.getBackgroundColor(root.current))
                font.family: Colors.text.fontFamily
                font.weight: Font.Medium

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

    // Short feedback for clicks and wheel on the bar widget
    Rectangle {
        id: overlay
        anchors.fill: content
        color: Qt.rgba(0, 0, 0, 0.55)
        opacity: 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        MediaIcon {
            id: overlayIcon
            anchors.centerIn: parent
            visible: root.flashKind != "volume"
            kind: root.flashKind
            playing: !!root.current?.isPlaying
            color: Colors.lightTextOn(root.getBackgroundColor(root.current))
        }

        RowLayout {
            anchors.centerIn: parent
            visible: root.flashKind == "volume"
            spacing: 8

            Rectangle {
                implicitWidth: 90
                implicitHeight: 4
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.3)

                Rectangle {
                    width: parent.width * Math.min(1, Pipewire.defaultAudioSink?.audio?.volume ?? 0)
                    height: parent.height
                    radius: 2
                    color: Colors.lightTextOn(root.getBackgroundColor(root.current))

                    Behavior on width {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }

            Text {
                text: `${Math.round((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100)}%`
                color: Colors.lightTextOn(root.getBackgroundColor(root.current))
                font.family: Colors.text.fontFamily
            }
        }
    }

    Timer {
        id: flashHide
        interval: 1000
        onTriggered: overlay.opacity = 0
    }

    function flash(kind) {
        flashKind = kind;
        overlay.opacity = 1;
        flashHide.restart();
        if (kind != "volume")
            overlayIcon.animate();
    }

    PopupWrapper {
        id: popup
        requestOpen: root.requestOpen && root.visible
        anchors.left: content.left
        anchors.top: content.bottom
        screen: root.screen

        onOpenedChanged: {
            if (opened) {
                const p = MusicState.pickPlayer(root.players);
                if (p)
                    MusicState.mainPlayer = p;
            }
        }

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
                visible: root.players.length > 1
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
                            color: btn.player == current ? Colors.t("#eeeeee", 0.68) : (btn.hovered ? Colors.t("#dddddd", 0.5) : Colors.t("#dddddd", 0.31))

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

                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }

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

    function getBackgroundColor(player) {
        if (player?.identity == "Spotify") {
            return Colors.backgrounds.spotify;
        }
        return Colors.backgrounds.music;
    }

    // Behavior
    Timer {
        // only emit the signal when the position is actually changing.
        running: root.current?.playbackState == MprisPlaybackState.Playing
        // Make sure the position updates at least once per second.
        interval: 1000
        repeat: true
        // emit the positionChanged signal every second.
        onTriggered: {
            root.current.positionChanged();
        }
    }
}
