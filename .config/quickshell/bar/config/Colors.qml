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

    // Text on the bar and its popups
    readonly property Text text: Text {
        dark: false
        base: root.t(Theme.current.text, 1)
    }
    // Text on the dark panels (notification panel and cards, settings, lock screen): always light
    readonly property Text panelText: Text {
        dark: false
        base: root.t(Theme.current.text, 1)
    }

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
        // Dark text on a light background; the status colors are then deeper
        property bool dark: false
        property color base
        readonly property color color: base
        readonly property color disabled: dark ? Qt.alpha(base, 0.45) : t("#cccccc", 1)
        // Less important text, like the app name of a notification
        readonly property color secondary: Qt.alpha(base, 0.75)
        readonly property color activeColor: dark ? t("#006d7a", 1) : t("#0fffff", 1)
        readonly property color danger: dark ? t("#b3261e", 1) : t("#ff6b6b", 1)
        readonly property color warning: dark ? t("#8a5a00", 1) : t("#ffd166", 1)
        // Symbols for icons; set it on the Text so Qt does not use the emoji font
        readonly property string iconFont: "Noto Sans Symbols 2"
        // Font of all the text of the bar
        readonly property string fontFamily: "Iosevka Nerd Font"
        readonly property int fontSize: 11
    }

    readonly property color workspaceCircle: t("#ffffff", 0.2)
    readonly property color workspaceCircleActive: t("#ffffff", 0.4)
    readonly property color workspaceCircleUrgent: t("#ff0000", 0.4)
    // Workspace indicator: light shapes with deep numbers in the bar hue, easy to read on the bar
    readonly property color workspacePill: t(Theme.current.pill, 0.9)
    readonly property color workspaceDot: t("#ffffff", 0.35)
    readonly property color workspaceDotHover: t("#ffffff", 0.6)
    readonly property color workspaceDotUrgent: t("#ff4d4d", 0.6)
    readonly property color workspaceNumber: textOn(backgrounds.color)

    // Music

    component Backgrounds: QtObject {
        id: backgrounds
        readonly property color spotify: t("#1cb852", 1)
        readonly property color music: t("#f5c542", 1)
        readonly property color battery: t("#7dd18c", 1)
        readonly property color batteryLow: t("#fab045", 1)
        readonly property color batteryCritical: t("#f05c5c", 1)
        // An application records the microphone or the screen
        readonly property color privacy: t("#ff9f43", 1)

        // Left and right ends of the bar gradient (from the theme)
        property color color: t(Theme.current.barStart, hovered ? 0.9 : 0.8)
        property color colorEnd: t(Theme.current.barEnd, hovered ? 0.9 : 0.8)
        // Darker variant of the bar color, for large panels
        readonly property color panel: t(Theme.current.panel, 0.75)

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        Behavior on colorEnd {
            ColorAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        // Bar background: the theme gradient, left to right
        readonly property Gradient gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: backgrounds.color
            }
            GradientStop {
                position: 1.0
                color: backgrounds.colorEnd
            }
        }
    }
}
