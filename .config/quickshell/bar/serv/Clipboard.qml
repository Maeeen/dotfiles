pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// History of the copied text, in memory only (nothing is written to disk).
// Text that a password manager marks as secret is not kept.
Singleton {
    id: root

    // Newest first, each text one time
    property var history: []
    readonly property int size: 50
    // Longer text (for example a big file) is not kept
    readonly property int maxLength: 100000

    function add(text) {
        if (!text.trim() || text.length > maxLength)
            return;
        history = [text].concat(history.filter(t => t !== text)).slice(0, size);
    }

    function copy(text) {
        Quickshell.execDetached(["wl-copy", "--", text]);
    }

    // wl-paste runs the script for each new clipboard content. The script writes the text,
    // then a record separator (0x1E), because the text can have new lines.
    Process {
        id: watcher
        running: true
        command: ["wl-paste", "--type", "text", "--watch", "sh", "-c", `
            case "$(wl-paste --list-types)" in
                *x-kde-passwordManagerHint*) cat >/dev/null ;;
                *) cat; printf '\\036' ;;
            esac`]

        stdout: SplitParser {
            splitMarker: "\x1e"
            onRead: data => root.add(data)
        }

        // Start again if wl-paste stops
        onRunningChanged: {
            if (!running)
                restart.start();
        }
    }

    Timer {
        id: restart
        interval: 5000
        onTriggered: watcher.running = true
    }
}
