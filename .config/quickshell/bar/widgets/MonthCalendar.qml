import "root:/config"
import "root:/serv"
import "root:/utils"
import Quickshell
import QtQuick
import QtQuick.Layouts

// Month grid with a dot for each calendar that has events on a day,
// and the events of the selected day below it. Click the month name to go back to today.
ColumnLayout {
    id: root

    // Midnight of today. Hours precision is enough to see the new day.
    readonly property var today: {
        const d = clock.date;
        return new Date(d.getFullYear(), d.getMonth(), d.getDate());
    }
    // First day of the shown month
    property var month: new Date(today.getFullYear(), today.getMonth(), 1)
    property var selected: today

    // Six full weeks, from the Monday on or before the first day of the month
    readonly property var gridStart: new Date(month.getFullYear(), month.getMonth(), 1 - (month.getDay() + 6) % 7)
    readonly property var days: Array.from({
            length: 42
        }, (_, i) => new Date(gridStart.getFullYear(), gridStart.getMonth(), gridStart.getDate() + i))
    readonly property var occurrences: CalendarEvents.occurrences(days[0], nextDay(days[41]))
    readonly property var selectedEvents: eventsOn(selected)

    spacing: 6

    function reset() {
        month = new Date(today.getFullYear(), today.getMonth(), 1);
        selected = today;
    }

    function nextDay(d) {
        return new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1);
    }

    function eventsOn(day) {
        const next = nextDay(day);
        return occurrences.filter(o => o.start < next && (o.end > day || o.start >= day));
    }

    function select(day) {
        selected = day;
        month = new Date(day.getFullYear(), day.getMonth(), 1);
    }

    // "10:00–11:00", "All day"; "…" when the event starts or ends on another day
    function timeText(o, day) {
        if (o.allDay)
            return "All day";
        const a = o.start >= day ? Qt.formatTime(o.start, "hh:mm") : "…";
        const b = o.end <= nextDay(day) ? Qt.formatTime(o.end, "hh:mm") : "…";
        return a + "–" + b;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    RowLayout {
        Layout.fillWidth: true

        GhostButton {
            textColor: Colors.panelText.color
            text: "‹"
            onClicked: root.month = new Date(root.month.getFullYear(), root.month.getMonth() - 1, 1)
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDate(root.month, "MMMM yyyy")
            font.bold: true
            color: Colors.panelText.color
            font.pointSize: Colors.panelText.fontSize
            font.family: Colors.panelText.fontFamily

            HoverArea {
                anchors.centerIn: parent
                width: parent.contentWidth + 16
                height: parent.height + 4
                radius: 6
                onClicked: root.reset()
            }
        }

        GhostButton {
            textColor: Colors.panelText.color
            text: "›"
            onClicked: root.month = new Date(root.month.getFullYear(), root.month.getMonth() + 1, 1)
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        columnSpacing: 0
        rowSpacing: 0

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

            Text {
                required property string modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Colors.panelText.secondary
                font.pointSize: Colors.panelText.fontSize - 2
                font.family: Colors.panelText.fontFamily
            }
        }

        Repeater {
            model: root.days

            Item {
                id: cell
                required property var modelData
                readonly property bool isToday: +modelData === +root.today
                readonly property bool isSelected: +modelData === +root.selected
                readonly property bool inMonth: modelData.getMonth() === root.month.getMonth()
                // One dot for each calendar with events on this day
                readonly property var colors: [...new Set(root.eventsOn(modelData).map(o => String(o.color)))].slice(0, 3)

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 36

                Rectangle {
                    id: circle
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 2
                    width: 26
                    height: 26
                    radius: 13
                    color: cell.isToday ? Colors.workspacePill : (cell.isSelected ? Colors.workspaceCircleActive : Qt.rgba(1, 1, 1, 0))

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                            easing.type: Easing.InOutQuad
                        }
                    }

                    // The selected day, when it is today
                    border.width: cell.isToday && cell.isSelected ? 2 : 0
                    border.color: Colors.workspaceCircleActive

                    Text {
                        anchors.centerIn: parent
                        text: cell.modelData.getDate()
                        color: cell.isToday ? Colors.workspaceNumber : (cell.inMonth ? Colors.panelText.color : Colors.panelText.secondary)
                        opacity: cell.inMonth ? 1 : 0.5
                        font.bold: cell.isToday
                        font.pointSize: Colors.panelText.fontSize - 1
                        font.family: Colors.panelText.fontFamily
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: circle.bottom
                    anchors.topMargin: 2
                    spacing: 3

                    Repeater {
                        model: cell.colors

                        Rectangle {
                            required property string modelData
                            width: 4
                            height: 4
                            radius: 2
                            color: modelData
                            opacity: cell.inMonth ? 1 : 0.5
                        }
                    }
                }

                HoverArea {
                    anchors.fill: circle
                    radius: circle.radius
                    onClicked: root.select(cell.modelData)
                }
            }
        }
    }

    // Agenda of the selected day
    Text {
        Layout.topMargin: 4
        text: Qt.formatDate(root.selected, "dddd d MMMM")
        color: Colors.panelText.secondary
        font.pointSize: Colors.panelText.fontSize - 1
        font.family: Colors.panelText.fontFamily
    }

    Repeater {
        model: root.selectedEvents

        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                implicitWidth: 3
                implicitHeight: 18
                radius: 1.5
                color: modelData.color
            }

            Text {
                Layout.preferredWidth: 90
                text: root.timeText(modelData, root.selected)
                color: Colors.panelText.secondary
                font.pointSize: Colors.panelText.fontSize - 1
                font.family: Colors.panelText.fontFamily
            }

            Text {
                Layout.fillWidth: true
                text: modelData.title
                elide: Text.ElideRight
                color: Colors.panelText.color
                font.pointSize: Colors.panelText.fontSize - 1
                font.family: Colors.panelText.fontFamily
            }
        }
    }

    Text {
        visible: root.selectedEvents.length === 0
        text: "No events"
        color: Colors.panelText.secondary
        opacity: 0.7
        font.pointSize: Colors.panelText.fontSize - 1
        font.family: Colors.panelText.fontFamily
    }
}
