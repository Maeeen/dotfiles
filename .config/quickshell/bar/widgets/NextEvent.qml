import "root:/config"
import "root:/serv"
import "root:/utils"
import Quickshell
import QtQuick
import QtQuick.Layouts

// The event that runs now, or else the next event of today, from the Thunderbird calendars.
// Hidden when there are no more events today. A click opens the right panel with the calendar.
Item {
    id: root

    readonly property var now: clock.date
    readonly property var event: {
        const end = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
        return CalendarEvents.occurrences(now, end).find(o => !o.allDay && o.end > now) ?? null;
    }
    readonly property bool running: event !== null && event.start <= now

    // Grows in and shrinks out: hidden only when the width is 0
    readonly property bool shown: event !== null
    visible: Layout.preferredWidth > 0
    opacity: shown ? 1 : 0
    Layout.preferredWidth: shown ? row.implicitWidth + 12 : 0
    // Takes the layout spacing away while it shrinks, so the next items do not jump at the end
    Layout.leftMargin: parent.spacing * (Layout.preferredWidth / (row.implicitWidth + 12) - 1)
    Layout.fillHeight: true
    clip: true

    Behavior on Layout.preferredWidth {
        WidthAnimation {}
    }

    Behavior on opacity {
        WidthAnimation {}
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Keep the events up to date while the panel is closed
    Timer {
        interval: 10 * 60000
        running: true
        repeat: true
        onTriggered: CalendarEvents.refresh()
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 7
            height: 7
            radius: 3.5
            color: root.event?.color ?? "transparent"
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.running ? "now" : Qt.formatTime(root.event?.start ?? new Date(), "hh:mm")
            color: Colors.text.secondary
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 200)
            elide: Text.ElideRight
            text: root.event?.title ?? ""
            color: Colors.text.color
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }
    }

    HoverArea {
        anchors.fill: parent
        onClicked: Notifs.panelOpen = !Notifs.panelOpen
    }
}
