import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "transparent"

    property var selectedIndex: 0

    clip: true

    default property alias content: actualContent.data

    property real sImplicitWidth: (actualContent.children[selectedIndex]) ? actualContent.children[selectedIndex].implicitWidth : 0
    property real sImplicitHeight: (actualContent.children[selectedIndex]) ? actualContent.children[selectedIndex].implicitHeight : 0
    property real sWidth: (actualContent.children[selectedIndex]) ? actualContent.children[selectedIndex].width : 0
    property real sHeight: (actualContent.children[selectedIndex]) ? actualContent.children[selectedIndex].height : 0

    implicitWidth: sImplicitWidth
    implicitHeight: sImplicitHeight

    Component.onCompleted: {
        Qt.callLater(() => {
            sImplicitWidth = (actualContent.children[selectedIndex]) ? actualContent.children[selectedIndex].implicitWidth : 0;
            sImplicitHeight = (actualContent.children[selectedIndex]) ? actualContent.children[selectedIndex].implicitHeight : 0;
            sWidth = (actualContent.children[selectedIndex]) ? actualContent.children[selectedIndex].width : 0;
            sHeight = (actualContent.children[selectedIndex]) ? actualContent.children[selectedIndex].height : 0;
        });
    }

    width: Math.min(100, sWidth)
    height: Math.min(100, sHeight)

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    RowLayout {
        id: actualContent
        x: (actualContent.children[root.selectedIndex] ? -actualContent.children[root.selectedIndex].x : 0)

        width: root.width
        height: root.height

        Behavior on x {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }
    }
}
