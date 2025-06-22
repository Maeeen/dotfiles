import "root:/config"
import QtQuick
import QtQuick.Controls

Button {
    id: btn
    hoverEnabled: true
    clip: true
    padding: 4
    palette.buttonText: Colors.text.color

    background: Rectangle {
        implicitHeight: 24
        implicitWidth: 24
        radius: 6
        border.width: 1
        color: "transparent"
        border.color: btn.down ? "#dddddd" : (btn.hovered ? "#f0f0f0" : "#ffffff")
    }
}
