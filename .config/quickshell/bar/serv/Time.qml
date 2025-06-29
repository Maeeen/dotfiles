pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    readonly property string time: {
        Qt.formatDateTime(clock.date, "hh:mm:ss");
    }

    readonly property string date: {
        Qt.formatDateTime(clock.date, "ddd MMM d");
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
