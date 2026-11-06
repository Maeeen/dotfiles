pragma Singleton

import "root:/config"
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Brightness and the other picture settings of each monitor.
// The laptop panel uses the backlight in sysfs, the other monitors use DDC/CI with ddcutil.
// DDC is slow and fails when it gets too many commands, so the commands go one at a time,
// and a new value replaces a value that is not sent yet.
Singleton {
    id: root

    // VCP codes that the popup shows: brightness, contrast, color temperature,
    // red/green/blue gain, red/green/blue black level
    readonly property var codes: ["10", "12", "0C", "16", "18", "1A", "6C", "6E", "70"]

    // Monitor name (e.g. "HDMI-A-1") → I2C bus number, from "ddcutil detect"
    property var buses: ({})
    // Monitor name → { code: { value, max } }
    property var values: ({})

    // DDC values that are not sent yet: bus → { code: value }
    property var pending: ({})
    // Buses to read
    property var toRead: []

    // The brightness changed with the keys, or the backlight changed outside the bar. The OSD shows it.
    signal shown(string screenName, real value)

    function isLaptop(name) {
        return name === Config.laptopScreen;
    }

    // { value, max } of the code, or null when the monitor does not have it
    function get(name, code) {
        return values[name]?.[code] ?? null;
    }

    function setCached(name, code, value, max) {
        const v = Object.assign({}, values);
        v[name] = Object.assign({}, v[name]);
        v[name][code] = {
            value,
            max
        };
        values = v;
    }

    function set(name, code, value) {
        const cur = get(name, code);
        if (!cur)
            return;
        // Brightness 0 turns the laptop panel off
        value = Math.round(Math.max(isLaptop(name) ? 1 : 0, Math.min(cur.max, value)));
        if (value === cur.value)
            return;
        setCached(name, code, value, cur.max);
        if (isLaptop(name)) {
            Quickshell.execDetached(["brightnessctl", "-q", "s", String(value)]);
        } else {
            const bus = buses[name];
            pending[bus] = Object.assign({}, pending[bus]);
            pending[bus][code] = value;
            runNext();
        }
    }

    // Changes the brightness by a percent of the maximum, and shows it in the OSD
    function step(name, percent) {
        const cur = get(name, "10");
        if (!cur)
            return;
        set(name, "10", cur.value + percent * cur.max / 100);
        shown(name, get(name, "10").value / cur.max);
    }

    // Reads the DDC values again, e.g. when they were changed with the buttons of the monitor
    function refresh(name) {
        const bus = buses[name];
        if (bus !== undefined && !toRead.includes(bus)) {
            toRead.push(bus);
            runNext();
        }
    }

    function runNext() {
        if (ddc.running || detect.running)
            return;
        const bus = Object.keys(pending)[0];
        if (bus !== undefined) {
            const pairs = Object.entries(pending[bus]).reduce((a, [code, value]) => a.concat([code, String(value)]), []);
            delete pending[bus];
            ddc.start(bus, ["setvcp", "--noverify", ...pairs]);
        } else if (toRead.length > 0) {
            ddc.start(toRead.shift(), ["getvcp", "--brief", ...codes]);
        }
    }

    Process {
        id: ddc
        property string bus
        // The output and the exit can come in any order; go on when both came
        property int done: 0

        property bool reading: false

        function start(bus, args) {
            this.bus = bus;
            reading = args[0] === "getvcp";
            done = 0;
            command = ["ddcutil", "--bus", bus, ...args];
            running = true;
        }

        function finish() {
            if (++done === 2)
                root.runNext();
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const name = Object.keys(root.buses).find(n => String(root.buses[n]) === ddc.bus);
                // e.g. "VCP 10 C 100 100": code, current value, maximum
                const re = /^VCP (\w+) C (\d+) (\d+)/gm;
                let m;
                let found = 0;
                while ((m = re.exec(text)) !== null) {
                    found++;
                    // A value that waits to be sent is newer than the value read
                    if (root.pending[ddc.bus]?.[m[1]] === undefined)
                        root.setCached(name, m[1], Number(m[2]), Number(m[3]));
                }
                if (ddc.reading && found === 0)
                    retry.later();
                ddc.finish();
            }
        }
        onExited: finish()
    }

    // Finds the DDC monitors, then reads their values
    Process {
        id: detect
        running: true
        command: ["ddcutil", "detect", "--brief"]

        stdout: StdioCollector {
            onStreamFinished: {
                const b = {};
                // Blocks of a valid display start with "Display N"; "Invalid display" blocks are skipped
                for (const block of text.split(/\n(?=\S)/)) {
                    const bus = block.match(/I2C bus:\s+\/dev\/i2c-(\d+)/);
                    const connector = block.match(/DRM connector:\s+card\d+-(\S+)/);
                    if (block.startsWith("Display") && bus && connector)
                        b[connector[1]] = bus[1];
                }
                root.buses = b;
                root.toRead = Object.values(b);
                if (root.toRead.length === 0)
                    retry.later();
            }
        }
        onExited: root.runNext()
    }

    // DDC sometimes does not answer: try again a few times
    Timer {
        id: retry
        property int count: 0
        interval: 2000

        function later() {
            if (count++ < 5)
                restart();
        }

        onTriggered: {
            if (Object.keys(root.buses).length === 0) {
                detect.running = true;
                return;
            }
            for (const name of Object.keys(root.buses)) {
                if (!root.get(name, "10"))
                    root.refresh(name);
            }
        }
    }

    // sysfs does not tell when the backlight changes, so read it often
    FileView {
        id: maxBacklight
        path: Config.backlight + "/max_brightness"
        blockLoading: true
    }

    FileView {
        id: backlight
        path: Config.backlight + "/brightness"
        onLoaded: {
            const v = Number(text());
            const max = Number(maxBacklight.text());
            const cur = root.get(Config.laptopScreen, "10");
            if (cur?.value === v)
                return;
            root.setCached(Config.laptopScreen, "10", v, max);
            // The first read is not a change
            if (cur)
                root.shown(Config.laptopScreen, v / max);
        }
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: backlight.reload()
    }

    // For the brightness keys: qs -c bar ipc call brightness up
    IpcHandler {
        target: "brightness"

        function up(): void {
            root.step(Hyprland.focusedMonitor?.name ?? "", 10);
        }

        function down(): void {
            root.step(Hyprland.focusedMonitor?.name ?? "", -10);
        }
    }
}
