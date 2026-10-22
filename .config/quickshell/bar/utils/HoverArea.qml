import QtQuick

// A MouseArea that shows it can be clicked: a hand cursor and a light background on hover.
MouseArea {
    id: area
    property real radius: 0

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: area.radius
        color: "white"
        opacity: area.pressed ? 0.25 : (area.containsMouse ? 0.15 : 0)

        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.InOutQuad
            }
        }
    }
}
