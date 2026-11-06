pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Weather from wttr.in, read each 30 minutes. wttr.in finds the location from the IP address.
// `ready` is false when there is no data: no network, or no answer for 3 hours.
Singleton {
    id: root

    property bool ready: false
    property double updatedAt: 0
    property string place: ""
    property string description: ""
    property int temp: 0
    property int feelsLike: 0
    property int code: 0
    property int wind: 0
    property real rain: 0
    property int humidity: 0
    property bool night: false
    // The next days: {date, min, max, code}, with the weather at noon
    property var days: []

    // Nerd Font weather glyph for a wttr.in (WWO) weather code
    function icon(code, night) {
        const snow = [179, 182, 185, 227, 230, 281, 284, 311, 314, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377];
        if (code === 113)
            return night ? "" : "";
        if (code === 116)
            return night ? "" : "";
        if (code === 119 || code === 122)
            return "";
        if ([143, 248, 260].includes(code))
            return "";
        if ([200, 386, 389, 392, 395].includes(code))
            return "";
        if (snow.includes(code))
            return "";
        if ([176, 263, 353].includes(code))
            return "";
        return "";
    }

    // "07:08 AM" today
    function timeToday(s) {
        const m = /(\d+):(\d+) (AM|PM)/.exec(s);
        const d = new Date();
        if (m)
            d.setHours(+m[1] % 12 + (m[3] === "PM" ? 12 : 0), +m[2], 0, 0);
        return d;
    }

    function parse(text) {
        let d;
        try {
            d = JSON.parse(text);
        } catch (e) {
            return false;
        }
        const c = d.current_condition?.[0];
        if (!c)
            return false;
        place = d.nearest_area?.[0]?.areaName?.[0]?.value ?? "";
        description = c.weatherDesc?.[0]?.value ?? "";
        temp = +c.temp_C;
        feelsLike = +c.FeelsLikeC;
        code = +c.weatherCode;
        wind = +c.windspeedKmph;
        rain = +c.precipMM;
        humidity = +c.humidity;
        const sun = d.weather?.[0]?.astronomy?.[0];
        const now = new Date();
        night = sun ? (now < timeToday(sun.sunrise) || now > timeToday(sun.sunset)) : false;
        days = (d.weather ?? []).map(w => ({
                    date: new Date(w.date + "T12:00:00"),
                    min: +w.mintempC,
                    max: +w.maxtempC,
                    code: +((w.hourly ?? []).find(h => h.time === "1200")?.weatherCode ?? 113)
                }));
        return true;
    }

    Process {
        id: proc
        command: ["curl", "-sf", "-m", "20", "https://wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.parse(text)) {
                    root.updatedAt = Date.now();
                    root.ready = true;
                } else if (Date.now() - root.updatedAt > 3 * 3600000) {
                    root.ready = false;
                }
            }
        }
    }

    Timer {
        interval: 30 * 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
