import "root:/config"
import "root:/serv"
import QtQuick
import QtQuick.Layouts

// Layout of the monitors: drag a screen on the map, it snaps to an edge of another screen.
// A click on a screen selects it; the rows below change its mode, scale, rotation and mirror,
// and turn it off or on. The changes wait for "Apply".
ColumnLayout {
    id: root
    // Monitor selected at the start: the monitor of this bar
    property string screenName
    // Same hover test as the other items of the popup
    property var isUnderMouse: item => false
    readonly property bool dragging: map.dragName !== ""

    property string selected: screenName
    // Changes not applied yet: name → { field: value }
    property var edits: ({})
    readonly property var states: Monitors.list.map(m => Object.assign({}, m, edits[m.name]))
    readonly property var sel: states.find(m => m.name === selected) ?? null
    // Monitors on the map: on, and not a mirror
    readonly property var placed: states.filter(m => !m.disabled && !m.mirror)

    spacing: 4

    function edit(name, changes) {
        const e = Object.assign({}, edits);
        e[name] = Object.assign({}, e[name], changes);
        edits = e;
    }

    function apply() {
        Monitors.apply(states.filter(m => edits[m.name] !== undefined));
        edits = {};
    }

    // Puts the dragged monitor d near (x, y), against the nearest edge of another monitor.
    // On an edge, it aligns with the start or the end of that edge when it is near.
    function snap(d, x, y, near) {
        const [dw, dh] = Monitors.logicalSize(d);
        let best = null;
        for (const o of placed) {
            if (o.name === d.name)
                continue;
            const [ow, oh] = Monitors.logicalSize(o);
            const align = (v, start, len, dlen) => {
                v = Math.max(start - dlen, Math.min(start + len, v));
                for (const a of [start, start + len - dlen]) {
                    if (Math.abs(v - a) < near)
                        return a;
                }
                return v;
            };
            const ay = align(y, o.y, oh, dh);
            const ax = align(x, o.x, ow, dw);
            for (const [cx, cy] of [[o.x + ow, ay], [o.x - dw, ay], [ax, o.y + oh], [ax, o.y - dh]]) {
                const dist = Math.hypot(cx - x, cy - y);
                if (!best || dist < best.dist)
                    best = {
                        x: cx,
                        y: cy,
                        dist
                    };
            }
        }
        return best ?? {
            x,
            y
        };
    }

    // The map
    Item {
        id: map
        Layout.fillWidth: true
        implicitHeight: 110

        property string dragName: ""
        // Drag offset in map pixels
        property real dx: 0
        property real dy: 0

        // Box around the placed monitors, in layout pixels
        readonly property var box: root.placed.reduce((b, m) => {
            const [w, h] = Monitors.logicalSize(m);
            return [Math.min(b[0], m.x), Math.min(b[1], m.y), Math.max(b[2], m.x + w), Math.max(b[3], m.y + h)];
        }, [Infinity, Infinity, -Infinity, -Infinity])
        // Map pixels for each layout pixel; the space around lets a screen go to each side
        readonly property real k: Math.min(width / (box[2] - box[0]), height / (box[3] - box[1])) * 0.6
        readonly property real ox: (width - (box[2] - box[0]) * k) / 2
        readonly property real oy: (height - (box[3] - box[1]) * k) / 2

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Qt.rgba(0, 0, 0, 0.15)
        }

        Repeater {
            model: root.placed

            Rectangle {
                id: screenRect
                required property var modelData
                readonly property bool isDragged: map.dragName === modelData.name
                readonly property var size: Monitors.logicalSize(modelData)

                x: map.ox + (modelData.x - map.box[0]) * map.k + (isDragged ? map.dx : 0)
                y: map.oy + (modelData.y - map.box[1]) * map.k + (isDragged ? map.dy : 0)
                z: isDragged ? 1 : 0
                width: size[0] * map.k
                height: size[1] * map.k
                radius: 4
                color: root.selected === modelData.name ? Colors.workspaceCircleActive : Colors.workspaceCircle
                border.width: 1
                border.color: Colors.text.secondary

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 4
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: screenRect.modelData.name
                    color: Colors.text.color
                    font.pointSize: Colors.text.fontSize - 2
                    font.family: Colors.text.fontFamily
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    property point start

                    onPressed: mouse => {
                        start = mapToItem(map, mouse.x, mouse.y);
                        root.selected = screenRect.modelData.name;
                        map.dx = 0;
                        map.dy = 0;
                        map.dragName = screenRect.modelData.name;
                    }
                    onPositionChanged: mouse => {
                        const p = mapToItem(map, mouse.x, mouse.y);
                        map.dx = p.x - start.x;
                        map.dy = p.y - start.y;
                    }
                    onReleased: {
                        const m = screenRect.modelData;
                        // A small move is a click, not a drag
                        if (Math.hypot(map.dx, map.dy) > 3) {
                            const p = root.snap(m, m.x + map.dx / map.k, m.y + map.dy / map.k, 20 / map.k);
                            if (p.x !== m.x || p.y !== m.y)
                                root.edit(m.name, {
                                    x: Math.round(p.x),
                                    y: Math.round(p.y)
                                });
                        }
                        map.dragName = "";
                    }
                    onCanceled: map.dragName = ""
                }
            }
        }
    }

    // Monitors that are not on the map: off, or a mirror
    Flow {
        Layout.fillWidth: true
        Layout.leftMargin: 6
        spacing: 4
        visible: root.placed.length < root.states.length

        Repeater {
            model: root.states.filter(m => m.disabled || m.mirror)

            Rectangle {
                id: chip
                required property var modelData
                implicitWidth: chipText.implicitWidth + 12
                implicitHeight: 20
                radius: 6
                color: root.selected === modelData.name || root.isUnderMouse(chip) ? Colors.workspaceCircleActive : Colors.workspaceCircle

                Text {
                    id: chipText
                    anchors.centerIn: parent
                    text: `${chip.modelData.name} · ${chip.modelData.disabled ? "off" : "mirror of " + chip.modelData.mirror}`
                    color: Colors.text.color
                    font.pointSize: Colors.text.fontSize - 1
                    font.family: Colors.text.fontFamily
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected = chip.modelData.name
                }
            }
        }
    }

    // Settings of the selected monitor
    ColumnLayout {
        id: settings
        visible: root.sel !== null
        Layout.fillWidth: true
        Layout.topMargin: 2
        spacing: 2

        // Other monitors that stay on the map when this one goes off or becomes a mirror.
        // With none, all screens would be black.
        readonly property bool canLeave: root.placed.some(m => m.name !== root.selected)

        Text {
            Layout.leftMargin: 6
            text: root.sel ? `${root.sel.name} · ${root.sel.model}` : ""
            elide: Text.ElideRight
            Layout.fillWidth: true
            color: Colors.text.secondary
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
            font.weight: Font.Medium
        }

        Stepper {
            label: "Resolution"
            // Unique sizes, in the order of Hyprland (largest first)
            readonly property var sizes: root.sel ? root.sel.modes.map(m => `${m.width}x${m.height}`).filter((s, i, a) => a.indexOf(s) === i) : []
            value: root.sel ? `${root.sel.width}x${root.sel.height}` : ""
            values: sizes
            onPicked: v => {
                const [w, h] = v.split("x").map(Number);
                // The highest refresh rate of the new size
                const rate = Math.max(...root.sel.modes.filter(m => m.width === w && m.height === h).map(m => m.refresh));
                root.edit(root.selected, {
                    width: w,
                    height: h,
                    refresh: rate
                });
            }
        }

        Stepper {
            label: "Refresh"
            value: root.sel ? `${root.sel.refresh.toFixed(2)} Hz` : ""
            values: root.sel ? root.sel.modes.filter(m => m.width === root.sel.width && m.height === root.sel.height).map(m => `${m.refresh.toFixed(2)} Hz`).filter((s, i, a) => a.indexOf(s) === i) : []
            onPicked: v => root.edit(root.selected, {
                    refresh: parseFloat(v)
                })
        }

        Stepper {
            label: "Scale"
            // Hyprland changes a scale that does not divide the size well to a near one
            readonly property var scales: ["0.50", "0.75", "1.00", "1.25", "1.50", "1.60", "1.75", "2.00", "2.50", "3.00"]
            value: root.sel ? root.sel.scale.toFixed(2) : ""
            values: scales.includes(value) ? scales : scales.concat([value]).sort((a, b) => a - b)
            onPicked: v => root.edit(root.selected, {
                    scale: Number(v)
                })
        }

        Stepper {
            label: "Rotation"
            value: root.sel ? `${(root.sel.transform % 4) * 90}°` : ""
            values: ["0°", "90°", "180°", "270°"]
            // Keeps the flip of transforms 4 to 7
            onPicked: v => root.edit(root.selected, {
                    transform: parseInt(v) / 90 + (root.sel.transform >= 4 ? 4 : 0)
                })
        }

        Stepper {
            label: "Mirror"
            value: root.sel?.mirror || "none"
            values: ["none"].concat(settings.canLeave ? root.placed.filter(m => m.name !== root.selected).map(m => m.name) : [])
            onPicked: v => root.edit(root.selected, {
                    mirror: v === "none" ? "" : v
                })
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 4

            Button {
                text: root.sel?.disabled ? "Turn on" : "Turn off"
                enabled: root.sel?.disabled || settings.canLeave
                onClicked: root.edit(root.selected, {
                    disabled: !root.sel.disabled
                })
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "Reset"
                enabled: Object.keys(root.edits).length > 0
                onClicked: root.edits = {}
            }

            Button {
                text: "Apply"
                enabled: Object.keys(root.edits).length > 0
                onClicked: root.apply()
            }
        }
    }

    component Button: Rectangle {
        id: button
        property string text
        signal clicked

        implicitWidth: buttonText.implicitWidth + 16
        implicitHeight: 22
        radius: 6
        opacity: enabled ? 1 : 0.4
        color: enabled && root.isUnderMouse(button) ? Colors.workspaceCircleActive : Colors.workspaceCircle

        Text {
            id: buttonText
            anchors.centerIn: parent
            text: button.text
            color: Colors.text.color
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    // Name, and the value between "‹" and "›" that go to the previous and next value.
    // The wheel also changes the value.
    component Stepper: RowLayout {
        id: stepper
        property string label
        property string value
        property var values: []
        signal picked(string value)

        function step(dir) {
            const i = values.indexOf(value);
            const next = values[Math.max(0, Math.min(values.length - 1, i + dir))];
            if (next !== undefined && next !== value)
                picked(next);
        }

        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        spacing: 4

        Text {
            Layout.preferredWidth: 84
            text: stepper.label
            color: Colors.text.color
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }

        Arrow {
            text: "‹"
            onClicked: stepper.step(-1)
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: stepper.value
            color: Colors.text.color
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily

            MouseArea {
                anchors.fill: parent
                onWheel: wheel => stepper.step(wheel.angleDelta.y > 0 ? -1 : 1)
            }
        }

        Arrow {
            text: "›"
            onClicked: stepper.step(1)
        }
    }

    component Arrow: Rectangle {
        id: arrow
        property string text
        signal clicked

        implicitWidth: 22
        implicitHeight: 22
        radius: 6
        color: root.isUnderMouse(arrow) ? Colors.workspaceCircleActive : Qt.rgba(1, 1, 1, 0)

        Text {
            anchors.centerIn: parent
            text: arrow.text
            color: Colors.text.color
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: arrow.clicked()
        }
    }
}
