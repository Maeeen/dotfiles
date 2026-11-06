pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The color themes of the bar, and the colors that the user changed.
// The selection is saved in the state folder of the bar, so it stays after a restart.
Singleton {
    id: root

    // Each theme: bar gradient (left, right), panel background, text, and the light pill
    readonly property var themes: ({
            Sakura: {
                barStart: "#f89abd",
                barEnd: "#c9a7f5",
                panel: "#3b2630",
                text: "#fff0f5",
                pill: "#fff0f5"
            },
            Ocean: {
                barStart: "#5ec8d8",
                barEnd: "#6a8cf0",
                panel: "#1f2a3b",
                text: "#f0f8ff",
                pill: "#f0f8ff"
            },
            Sunset: {
                barStart: "#f7a35c",
                barEnd: "#ef6f9a",
                panel: "#3b2426",
                text: "#fff4ec",
                pill: "#fff4ec"
            },
            Forest: {
                barStart: "#7cc58a",
                barEnd: "#4fb3a9",
                panel: "#1f3328",
                text: "#f0fff4",
                pill: "#f0fff4"
            },
            Night: {
                barStart: "#2b2f4a",
                barEnd: "#4a3566",
                panel: "#15161f",
                text: "#e6e6f0",
                pill: "#c9c3e6"
            }
        })
    readonly property var names: Object.keys(themes)
    // Names of the colors that the user can change, in the order of the settings window
    readonly property var colorNames: [
        { key: "barStart", label: "Bar left" },
        { key: "barEnd", label: "Bar right" },
        { key: "panel", label: "Panel" },
        { key: "text", label: "Text" },
        { key: "pill", label: "Pill" }
    ]

    property string name: "Sakura"
    // Theme name → {color key: "#rrggbb"}, the colors that the user changed
    property var overrides: ({})
    // The colors in use: the theme, with the changes of the user
    readonly property var current: Object.assign({}, themes[name] ?? themes.Sakura, overrides[name] ?? {})

    property bool settingsOpen: false

    function select(n) {
        name = n;
        save();
    }

    function next() {
        select(names[(names.indexOf(name) + 1) % names.length]);
    }

    function setColor(key, hex) {
        const o = Object.assign({}, overrides);
        o[name] = Object.assign({}, o[name] ?? {});
        o[name][key] = hex;
        overrides = o;
        save();
    }

    // The colors of the current theme go back to the defaults
    function reset() {
        const o = Object.assign({}, overrides);
        delete o[name];
        overrides = o;
        save();
    }

    function save() {
        file.setText(JSON.stringify({
            theme: name,
            overrides: overrides
        }, null, 2));
    }

    FileView {
        id: file
        path: Quickshell.statePath("theme.json")
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d.theme in root.themes)
                    root.name = d.theme;
                root.overrides = d.overrides ?? {};
            } catch (e) {
                console.warn("Theme: cannot read", path);
            }
        }
    }
}
