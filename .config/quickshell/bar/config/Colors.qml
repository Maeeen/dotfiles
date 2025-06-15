pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property Text text: Text {}
    readonly property Backgrounds backgrounds: Backgrounds {}

    component Text: QtObject {
        readonly property color color: "#ffffff"
        readonly property color activeColor: "#0fffff"
        readonly property int fontSize: 11
    }

    readonly property color workspaceCircle: Qt.rgba(1, 1, 1, 0.2)
    readonly property color workspaceCircleActive: Qt.rgba(1, 1, 1, 0.4)
    readonly property color workspaceCircleUrgent: Qt.rgba(1, 0, 0, 0.4)
    readonly property color workspaceText: Qt.rgba(1, 1, 1, 0.2)
    readonly property color workspaceTextActive: Qt.rgba(1, 1, 1, 1)
    component Backgrounds: QtObject {
        readonly property Gradient gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.rgba(0.6, 0.4, 1, 1.0)
            }
            GradientStop {
                position: 1.0
                color: "transparent"
            }
        }
    }
}
