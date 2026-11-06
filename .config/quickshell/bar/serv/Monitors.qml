pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// The monitors of Hyprland, also the disabled ones, from "hyprctl monitors all -j".
// Changes go to Hyprland with hl.monitor() in "hyprctl eval". They stay until Hyprland
// reloads its config (e.g. "hyprctl reload"), which sets the monitors_<host>.lua layout again.
Singleton {
    id: root

    // One object for each monitor:
    // { name, model, width, height, refresh, x, y, scale, transform, disabled, mirror, modes }
    // mirror: name of the mirrored monitor, or "". modes: [{ width, height, refresh }]
    property var list: []

    function refresh() {
        query.running = true;
    }

    function get(name) {
        return list.find(m => m.name === name) ?? null;
    }

    // Size in the layout: the scale divides it, and a 90° or 270° rotation turns it
    function logicalSize(m) {
        const w = Math.round(m.width / m.scale);
        const h = Math.round(m.height / m.scale);
        return m.transform % 2 === 1 ? [h, w] : [w, h];
    }

    // Sends the full rule of each monitor in the array: a rule without a field does not keep it
    function apply(monitors) {
        const rules = monitors.map(m => `hl.monitor({ output = "${m.name}", mode = "${m.width}x${m.height}@${m.refresh.toFixed(2)}", position = "${Math.round(m.x)}x${Math.round(m.y)}", scale = ${m.scale}, transform = ${m.transform}, disabled = ${m.disabled}, mirror = "${m.mirror || "none"}" })`);
        Quickshell.execDetached(["hyprctl", "eval", rules.join("\n")]);
        // Hyprland sends no event for these changes
        refreshLater.restart();
    }

    Component.onCompleted: refresh()

    Timer {
        id: refreshLater
        interval: 700
        onTriggered: root.refresh()
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name.startsWith("monitoradded") || event.name.startsWith("monitorremoved") || event.name === "configreloaded")
                refreshLater.restart();
        }
    }

    Process {
        id: query
        command: ["hyprctl", "monitors", "all", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                const raw = JSON.parse(text);
                // mirrorOf is the id of the mirrored monitor, or "none"
                const names = {};
                for (const m of raw)
                    names[String(m.id)] = m.name;
                root.list = raw.map(m => ({
                            name: m.name,
                            model: m.model.trim() || m.description,
                            width: m.width,
                            height: m.height,
                            refresh: m.refreshRate,
                            x: m.x,
                            y: m.y,
                            scale: m.scale,
                            transform: m.transform,
                            disabled: m.disabled,
                            mirror: names[m.mirrorOf] ?? "",
                            // e.g. "3840x2160@60.00Hz"
                            modes: m.availableModes.map(s => {
                                const p = s.match(/(\d+)x(\d+)@([\d.]+)/);
                                return {
                                    width: Number(p[1]),
                                    height: Number(p[2]),
                                    refresh: Number(p[3])
                                };
                            })
                        }));
            }
        }
    }
}
