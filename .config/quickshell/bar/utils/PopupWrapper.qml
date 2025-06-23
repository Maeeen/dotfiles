import Quickshell.Widgets
import QtQuick
import "root:/config"

Rectangle {
    id: root
    HoverHandler {
        id: nested
    }

    color: Colors.backgrounds.color
    property bool requestOpen

    Component.onDestruction: {
        PopupsState.close(this);
    }

    onOpenedChanged: {
        if (opened) {
            console.log("PopupWrapper opened");
            PopupsState.open(this);
        } else if (!opened) {

            console.log("PopupWrapper closed");
            PopupsState.close(this);
        }
    }

    property bool opened: requestOpen || nested.hovered
    property real margins: 10

    width: (actualContent.width + margins * 2)
    height: opened ? (actualContent.height + margins * 2) : 0
    clip: true
    bottomLeftRadius: opened ? 20 : 0
    bottomRightRadius: opened ? 20 : 0

    default property alias content: actualContent.data

    Rectangle {
        id: actualContent
        color: "transparent"
        x: margins
        y: margins
        width: childrenRect.width
        height: childrenRect.height
    }

    Behavior on width {
        NumberAnimation {
            duration: 400
            easing.type: Easing.InOutQuad
        }
    }
    

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
