import "root:/config"
import "root:/utils"
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// CPU use and memory use, with icons drawn as Shapes.
// An icon becomes yellow, then red, when its value is high.
// A click opens a popup with the graphs of the last 2 minutes.
Item {
    id: root
    property var screen
    property bool open: false
    property real cpu: 0
    property real mem: 0
    // Memory in GiB
    property real memUsed: 0
    property real memTotal: 0
    // Samples of the last 2 minutes, one each 2 s
    readonly property int historySize: 60
    property var cpuHistory: []
    property var memHistory: []
    // Last /proc/stat totals, to get the CPU use between two reads
    property real lastIdle: 0
    property real lastTotal: 0

    function levelColor(value, warn, high) {
        return value >= high ? Colors.text.danger : (value >= warn ? Colors.text.warning : Colors.text.color);
    }

    implicitWidth: row.implicitWidth + 12
    Layout.fillHeight: true

    Behavior on implicitWidth {
        WidthAnimation {}
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            // cpu user nice system idle iowait irq softirq steal
            const f = text().split("\n")[0].split(/\s+/).slice(1, 9).map(Number);
            const idle = f[3] + f[4];
            const total = f.reduce((a, b) => a + b, 0);
            if (root.lastTotal > 0 && total > root.lastTotal) {
                root.cpu = 1 - (idle - root.lastIdle) / (total - root.lastTotal);
                root.cpuHistory = root.cpuHistory.concat([root.cpu]).slice(-root.historySize);
            }
            root.lastIdle = idle;
            root.lastTotal = total;
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const total = Number(t.match(/MemTotal:\s+(\d+)/)[1]);
            const available = Number(t.match(/MemAvailable:\s+(\d+)/)[1]);
            root.mem = 1 - available / total;
            root.memUsed = (total - available) / 1048576;
            root.memTotal = total / 1048576;
            root.memHistory = root.memHistory.concat([root.mem]).slice(-root.historySize);
        }
    }

    // Constant text widths, so the bar does not move when the values change
    TextMetrics {
        id: percentMetrics
        text: "100%"
        font.pointSize: Colors.text.fontSize
        font.family: Colors.text.fontFamily
    }

    // Close the popup when the mouse is on neither the button nor the popup
    property bool hovered: buttonHover.hovered || popupHover.hovered
    onHoveredChanged: {
        if (hovered) {
            closeDelay.stop();
        } else if (open) {
            closeDelay.restart();
        }
    }

    Timer {
        id: closeDelay
        // Give the mouse time to move from the button to the popup
        interval: Config.popupCloseDelay
        onTriggered: root.open = false
    }

    Rectangle {
        anchors.fill: parent
        color: root.open ? Colors.workspaceCircleActive : "transparent"

        HoverHandler {
            id: buttonHover
        }

        HoverArea {
            anchors.fill: parent
            onClicked: root.open = !root.open
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        // CPU: chip with pins
        Shape {
            anchors.verticalCenter: parent.verticalCenter
            width: 12
            height: 12
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 1.2
                strokeColor: root.levelColor(root.cpu, 0.5, 0.8)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathRectangle { x: 2.6; y: 2.6; width: 6.8; height: 6.8; radius: 1 }
                PathMove { x: 4.5; y: 0.6 }
                PathLine { x: 4.5; y: 2.6 }
                PathMove { x: 7.5; y: 0.6 }
                PathLine { x: 7.5; y: 2.6 }
                PathMove { x: 4.5; y: 9.4 }
                PathLine { x: 4.5; y: 11.4 }
                PathMove { x: 7.5; y: 9.4 }
                PathLine { x: 7.5; y: 11.4 }
                PathMove { x: 0.6; y: 4.5 }
                PathLine { x: 2.6; y: 4.5 }
                PathMove { x: 0.6; y: 7.5 }
                PathLine { x: 2.6; y: 7.5 }
                PathMove { x: 9.4; y: 4.5 }
                PathLine { x: 11.4; y: 4.5 }
                PathMove { x: 9.4; y: 7.5 }
                PathLine { x: 11.4; y: 7.5 }
            }

            ShapePath {
                strokeWidth: -1
                fillColor: root.levelColor(root.cpu, 0.5, 0.8)

                PathRectangle { x: 4.6; y: 4.6; width: 2.8; height: 2.8 }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: percentMetrics.width
            text: `${Math.round(root.cpu * 100)}%`
            color: Colors.text.color
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }

        // Memory: RAM stick with contacts
        Shape {
            anchors.verticalCenter: parent.verticalCenter
            width: 13
            height: 12
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 1.2
                strokeColor: root.levelColor(root.mem, 0.7, 0.9)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathRectangle { x: 0.6; y: 2.6; width: 11.8; height: 6; radius: 1 }
                PathMove { x: 3; y: 8.6 }
                PathLine { x: 3; y: 10.6 }
                PathMove { x: 5.3; y: 8.6 }
                PathLine { x: 5.3; y: 10.6 }
                PathMove { x: 7.7; y: 8.6 }
                PathLine { x: 7.7; y: 10.6 }
                PathMove { x: 10; y: 8.6 }
                PathLine { x: 10; y: 10.6 }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: percentMetrics.width
            text: `${Math.round(root.mem * 100)}%`
            color: Colors.text.color
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }
    }

    PopupWrapper {
        id: popup
        requestOpen: root.open
        anchors.right: parent.right
        anchors.top: parent.bottom
        screen: root.screen

        ColumnLayout {
            width: 260
            spacing: 4

            StatHeader {
                label: "CPU"
                value: `${Math.round(root.cpu * 100)}%`
            }

            Graph {
                Layout.fillWidth: true
                values: root.cpuHistory
                count: root.historySize
            }

            StatHeader {
                Layout.topMargin: 6
                label: "Memory"
                value: `${root.memUsed.toFixed(1)} / ${root.memTotal.toFixed(1)} GiB`
            }

            Graph {
                Layout.fillWidth: true
                values: root.memHistory
                count: root.historySize
            }

            Text {
                text: "Last 2 minutes"
                color: Colors.text.secondary
                font.pointSize: Colors.text.fontSize - 2
                font.family: Colors.text.fontFamily
            }
        }
    }

    // Covers the popup with its margins, so the mouse on it keeps it open
    Item {
        anchors.fill: popup

        HoverHandler {
            id: popupHover
        }
    }

    component StatHeader: RowLayout {
        property string label
        property string value
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: parent.label
            color: Colors.text.secondary
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
            font.weight: Font.Medium
        }

        Text {
            text: parent.value
            color: Colors.text.color
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }
    }
}
