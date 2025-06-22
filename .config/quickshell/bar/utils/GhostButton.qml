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

    background: Rectangle {
        implicitHeight: 24
        implicitWidth: 24
        radius: 6
        border.width: 1
        color: "transparent"
        border.color: btn.down ? Qt.darker(btn.color, 1.5) : (btn.hovered ? Qt.darker(btn.color, 1.25) : "transparent")
    }
}
