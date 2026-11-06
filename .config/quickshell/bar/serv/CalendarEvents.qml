pragma Singleton

import "root:/config"
import Quickshell
import Quickshell.Io
import QtQuick
import "../utils/Recurrence.js" as Recurrence

// Events of the Thunderbird calendars, read from the calendar cache of Thunderbird.
// Thunderbird locks its database, so the script reads a private copy and then deletes it.
Singleton {
    id: root

    // Calendar id → {name, color, disabled}, from prefs.js
    // Events of a calendar that is not in prefs.js (or is disabled) are not shown
    property var calendars: ({})
    // Events with their recurrence rules, see Recurrence.prepare()
    property var items: []
    property double loadedAt: 0

    // Reads the cache again, at most one time each minute
    function refresh() {
        if (!proc.running && Date.now() - loadedAt > 60000)
            proc.running = true;
    }

    // Occurrences that touch [from, to), with the color of their calendar
    function occurrences(from, to) {
        return Recurrence.occurrences(items, from, to).map(o => Object.assign(o, {
                    color: calendars[o.cal]?.color ?? Colors.text.secondary
                }));
    }

    Process {
        id: proc
        command: ["sh", "-c", `
            # The profile that Thunderbird uses: the Default of an [Install...] section,
            # else the [Profile...] with Default=1
            p=$(awk -F= '
                /^[[]/ { install = /^[[]Install/; path = ""; def = 0 }
                /^Path=/ { path = substr($0, 6); if (def) fallback = path }
                /^Default=/ { if (install) { print substr($0, 9); found = 1; exit } if ($2 == "1") { def = 1; if (path) fallback = path } }
                END { if (!found && fallback) print fallback }' "$1/profiles.ini")
            [ -n "$p" ] || exit 1
            case "$p" in /*) ;; *) p="$1/$p" ;; esac
            set -- "$p"
            d=$(mktemp -d "$XDG_RUNTIME_DIR/qs-calendar.XXXXXX") || exit 1
            trap 'rm -rf "$d"' EXIT
            cp "$1/calendar-data/cache.sqlite" "$d/" || exit 1
            cp "$1/calendar-data/cache.sqlite-wal" "$d/" 2>/dev/null
            sqlite3 "$d/cache.sqlite" "select json_object(
                'events', (select json_group_array(json_array(cal_id, id, title, event_start, event_end, event_start_tz,
                    flags, recurrence_id, recurrence_id_tz, ical_status)) from cal_events where event_start is not null),
                'rules', (select json_group_array(json_array(cal_id, item_id, icalString)) from cal_recurrence))" || exit 1
            grep -E '"calendar[.]registry[.][^"]+[.](name|color|disabled)"' "$1/prefs.js"
        `, "sh", Config.thunderbirdDir]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                let data;
                try {
                    data = JSON.parse(lines[0]);
                } catch (e) {
                    console.warn("CalendarEvents: cannot read the Thunderbird calendar cache");
                    return;
                }
                // user_pref("calendar.registry.<id>.color", "#6bba88");
                const cals = {};
                const re = /^user_pref\("calendar\.registry\.([^"]+)\.(name|color|disabled)", (.*)\);$/;
                for (const line of lines.slice(1)) {
                    const m = re.exec(line);
                    if (m)
                        (cals[m[1]] = cals[m[1]] || {})[m[2]] = JSON.parse(m[3]);
                }
                root.calendars = cals;
                root.items = Recurrence.prepare(data.events.filter(e => cals[e[0]] && !cals[e[0]].disabled), data.rules);
                root.loadedAt = Date.now();
            }
        }
    }

    Component.onCompleted: refresh()
}
