import QtQuick
import "root:/config"
import "root:/serv"

Text {
    property bool isDate: false
    color: Colors.text.color
    text: isDate ? Time.date : Time.time
    font.pointSize: Colors.text.fontSize

    MouseArea {
        onClicked: function () {
            isDate = !isDate;
        }

        anchors.fill: parent
    }
}
