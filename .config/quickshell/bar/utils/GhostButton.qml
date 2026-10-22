import "root:/config"
import QtQuick
import QtQuick.Controls

Button {
    id: btn
    property color color: Colors.text.color
    property color textColor: Colors.text.color
    hoverEnabled: true
    clip: true
    padding: 4
    palette.buttonText: textColor

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    background: Rectangle {
        implicitHeight: 24
        implicitWidth: 24
        color: btn.down ? Qt.rgba(1, 1, 1, 0.25) : (btn.hovered ? Qt.rgba(1, 1, 1, 0.15) : "transparent")
    }
}
