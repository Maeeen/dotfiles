pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // State
    property bool hovered: false

    function c(str) {
        return Qt.rgba(parseInt(str.slice(1, 3), 16) / 255, parseInt(str.slice(3, 5), 16) / 255, parseInt(str.slice(5, 7), 16) / 255, parseInt(str.slice(7, 9), 16) / 255);
    }

    function t(str, a) {
        return Qt.rgba(parseInt(str.slice(1, 3), 16) / 255, parseInt(str.slice(3, 5), 16) / 255, parseInt(str.slice(5, 7), 16) / 255, a);
    }

    readonly property Text text: Text {}
    readonly property Backgrounds backgrounds: Backgrounds {}

    component Text: QtObject {
        readonly property color color: "#ffffff"
        readonly property color disabled: "#ccc"
        readonly property color activeColor: "#0fffff"
        readonly property int fontSize: 11
    }

    readonly property real barHeight: 30

    readonly property color workspaceCircle: Qt.rgba(1, 1, 1, 0.2)
    readonly property color workspaceCircleActive: Qt.rgba(1, 1, 1, 0.4)
    readonly property color workspaceCircleUrgent: Qt.rgba(1, 0, 0, 0.4)
    readonly property color workspaceText: Qt.rgba(1, 1, 1, 0.2)
    readonly property color workspaceTextActive: Qt.rgba(1, 1, 1, 1)

    // Music

    component Backgrounds: QtObject {
        id: backgrounds
        readonly property color spotify: Qt.rgba(.11, .72, .32, 1)
        readonly property color music: Qt.rgba(0.961, 0.773, 0.259, 1)

        readonly property Gradient spotifyGrad: Gradient {
            GradientStop {
                position: 0.6
                color: spotify
            }
        }

        readonly property Gradient musicGrad: Gradient {
            GradientStop {
                position: 0.6
                color: music
            }
        }

        property color color: t("#f89abd", hovered ? 0.8 : 0.6)

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        readonly property Gradient gradient: Gradient {
            GradientStop {
                position: 0.0
                color: backgrounds.color
            }
        }
    }
}
