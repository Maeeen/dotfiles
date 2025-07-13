import Quickshell.Widgets
import QtQuick
import "root:/config"
import "root:/utils"

Rectangle {
    id: root
    HoverHandler {
        id: nested
    }

    color: Colors.backgrounds.color
    property bool requestOpen

    Component.onDestruction: {
        PopupsState.close(screen, this);
    }

    onOpenedChanged: {
        if (opened) {
            PopupsState.open(screen, this);
        } else if (!opened) {
            PopupsState.close(screen, this);
        }
    }

    property bool opened: requestOpen || nested.hovered
    property real margins: 10
    property var screen

    width: (actualContent.width + margins * 2)
    height: opened ? (actualContent.height + margins * 2) : 0
    clip: true
    bottomLeftRadius: opened ? 20 : 0
    bottomRightRadius: opened ? 20 : 0
    visible: height > 0

    default property alias content: actualContent.data

    Rectangle {
        id: actualContent
        color: "transparent"
        x: root.margins
        y: root.margins
        width: childrenRect.width
        height: childrenRect.height
    }

    Behavior on width {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on bottomRightRadius {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on bottomLeftRadius {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }
}
