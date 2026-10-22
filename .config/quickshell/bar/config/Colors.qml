pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // State
    property bool hovered: false

    function t(str, a) {
        return Qt.rgba(parseInt(str.slice(1, 3), 16) / 255, parseInt(str.slice(3, 5), 16) / 255, parseInt(str.slice(5, 7), 16) / 255, a);
    }

    readonly property Text text: Text {}

    // Text on a colored background: same hue, deep and saturated, easier on the eyes than black or gray
    function textOn(bg) {
        return Qt.hsla(bg.hslHue, Math.min(1, bg.hslSaturation + 0.2), 0.17, 1);
    }

    // Light text on a dark layer over a colored background
    function lightTextOn(bg) {
        return Qt.hsla(bg.hslHue, 0.8, 0.93, 1);
    }
    readonly property Backgrounds backgrounds: Backgrounds {}

    component Text: QtObject {
        // White with a light tint of the pink bar color
        readonly property color color: t("#fff0f5", 1)
        readonly property color disabled: t("#cccccc", 1)
        // Less important text, like the app name of a notification
        readonly property color secondary: t("#fff0f5", 0.75)
        readonly property color activeColor: t("#0fffff", 1)
        readonly property color danger: t("#ff6b6b", 1)
        readonly property color warning: t("#ffd166", 1)
        // Symbols for icons; set it on the Text so Qt does not use the emoji font
        readonly property string iconFont: "Noto Sans Symbols 2"
        // Font of all the text of the bar
        readonly property string fontFamily: "Iosevka Nerd Font"
        readonly property int fontSize: 11
    }

    readonly property color workspaceCircle: t("#ffffff", 0.2)
    readonly property color workspaceCircleActive: t("#ffffff", 0.4)
    readonly property color workspaceCircleUrgent: t("#ff0000", 0.4)
    readonly property color workspaceText: t("#ffffff", 0.2)
    readonly property color workspaceTextActive: text.color

    // Music

    component Backgrounds: QtObject {
        id: backgrounds
        readonly property color spotify: t("#1cb852", 1)
        readonly property color music: t("#f5c542", 1)
        readonly property color battery: t("#7dd18c", 1)
        readonly property color batteryLow: t("#fab045", 1)
        readonly property color batteryCritical: t("#f05c5c", 1)

        property color color: t("#f89abd", hovered ? 0.9 : 0.8)
        // Darker variant of the bar color, for large panels
        readonly property color panel: t("#3b2630", 0.75)

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
