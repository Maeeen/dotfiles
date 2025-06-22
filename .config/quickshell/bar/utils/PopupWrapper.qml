import Quickshell.Widgets
import QtQuick
import "root:/config"

Rectangle {
    id: root
    HoverHandler {
        id: nested
    }

    color: Colors.backgrounds.color
    default property alias content: root.data
    property bool requestOpen

    onRequestOpenChanged: {
        if (requestOpen) {
            PopupsState.open(this);
        }
    }

    onOpenedChanged: {
        if (!opened) {
            PopupsState.close(this);
        }
    }

    property bool opened: requestOpen || nested.hovered

    width: childrenRect.width
    height: opened ? childrenRect.height : 0
    clip: true
    bottomLeftRadius: opened ? 20 : 0
    bottomRightRadius: opened ? 20 : 0

    Behavior on height {
        NumberAnimation {
            duration: 400
            easing.type: Easing.InOutQuad
        }
    }


    Behavior on bottomRightRadius {
        NumberAnimation {
            duration: 400
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on bottomLeftRadius {
        NumberAnimation {
            duration: 400
            easing.type: Easing.InOutQuad
        }
    }

}
