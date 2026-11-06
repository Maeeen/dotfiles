import "root:/config"
import "root:/serv"
import "root:/utils"
import QtQuick
import QtQuick.Layouts

// Weather icon and temperature. A click opens a popup with the weather now and the next days.
// Hidden when there is no weather data.
Item {
    id: root
    property var screen
    property bool open: false

    // Grows in and shrinks out: hidden only when the width is 0
    readonly property bool shown: Forecast.ready
    readonly property real fullWidth: row.implicitWidth + 12
    visible: Layout.preferredWidth > 0
    opacity: shown ? 1 : 0
    Layout.preferredWidth: shown ? fullWidth : 0
    // Takes the layout spacing away while it shrinks, so the next items do not jump at the end
    Layout.leftMargin: parent.spacing * (Layout.preferredWidth / fullWidth - 1)
    Layout.fillHeight: true

    Behavior on Layout.preferredWidth {
        WidthAnimation {}
    }

    Behavior on opacity {
        WidthAnimation {}
    }

    // "Today", "Tomorrow", else the day name
    function dayName(date) {
        const today = new Date();
        today.setHours(12, 0, 0, 0);
        const n = Math.round((date - today) / 86400000);
        return n === 0 ? "Today" : (n === 1 ? "Tomorrow" : Qt.formatDate(date, "dddd"));
    }

    // Close the popup when the mouse is on neither the button nor the popup
    property bool hovered: buttonHover.hovered || popupHover.hovered
    onHoveredChanged: {
        if (hovered) {
            closeDelay.stop();
        } else if (open) {
            closeDelay.restart();
        }
    }

    Timer {
        id: closeDelay
        // Give the mouse time to move from the button to the popup
        interval: Config.popupCloseDelay
        onTriggered: root.open = false
    }

    Rectangle {
        anchors.fill: parent
        clip: true
        color: root.open ? Colors.workspaceCircleActive : "transparent"

        HoverHandler {
            id: buttonHover
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Forecast.icon(Forecast.code, Forecast.night)
                color: Colors.text.color
                font.pointSize: Colors.text.fontSize + 1
                font.family: Colors.text.fontFamily
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: `${Forecast.temp}°`
                color: Colors.text.color
                font.pointSize: Colors.text.fontSize
                font.family: Colors.text.fontFamily
            }
        }

        HoverArea {
            anchors.fill: parent
            onClicked: root.open = !root.open
        }
    }

    PopupWrapper {
        id: popup
        requestOpen: root.open && root.shown
        anchors.right: parent.right
        anchors.top: parent.bottom
        screen: root.screen

        ColumnLayout {
            width: 280
            spacing: 4

            Text {
                text: Forecast.place
                color: Colors.text.secondary
                font.pointSize: Colors.text.fontSize
                font.family: Colors.text.fontFamily
                font.weight: Font.Medium
            }

            RowLayout {
                spacing: 10

                Text {
                    text: Forecast.icon(Forecast.code, Forecast.night)
                    color: Colors.text.color
                    font.pointSize: 26
                    font.family: Colors.text.fontFamily
                }

                ColumnLayout {
                    spacing: 0

                    Text {
                        text: `${Forecast.temp}° · ${Forecast.description}`
                        color: Colors.text.color
                        font.pointSize: Colors.text.fontSize + 2
                        font.family: Colors.text.fontFamily
                        font.weight: Font.Medium
                    }

                    Text {
                        text: `Feels like ${Forecast.feelsLike}° · Wind ${Forecast.wind} km/h`
                        color: Colors.text.secondary
                        font.pointSize: Colors.text.fontSize - 1
                        font.family: Colors.text.fontFamily
                    }

                    Text {
                        text: `Rain ${Forecast.rain} mm · Humidity ${Forecast.humidity}%`
                        color: Colors.text.secondary
                        font.pointSize: Colors.text.fontSize - 1
                        font.family: Colors.text.fontFamily
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: 2
                implicitHeight: 1
                color: Colors.workspaceCircle
            }

            Repeater {
                model: Forecast.days

                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        text: root.dayName(modelData.date)
                        color: Colors.text.color
                        font.pointSize: Colors.text.fontSize
                        font.family: Colors.text.fontFamily
                    }

                    Text {
                        text: Forecast.icon(modelData.code, false)
                        color: Colors.text.color
                        font.pointSize: Colors.text.fontSize + 2
                        font.family: Colors.text.fontFamily
                    }

                    Text {
                        Layout.preferredWidth: 70
                        horizontalAlignment: Text.AlignRight
                        text: `${modelData.min}° / ${modelData.max}°`
                        color: Colors.text.secondary
                        font.pointSize: Colors.text.fontSize
                        font.family: Colors.text.fontFamily
                    }
                }
            }
        }
    }

    // Covers the popup with its margins, so the mouse on it keeps it open
    Item {
        anchors.fill: popup

        HoverHandler {
            id: popupHover
        }
    }
}
