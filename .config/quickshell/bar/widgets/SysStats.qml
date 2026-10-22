import "root:/config"
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// CPU use and memory use, with icons drawn as Shapes.
// An icon becomes yellow, then red, when its value is high.
Item {
    id: root
    property real cpu: 0
    property real mem: 0
    // Last /proc/stat totals, to get the CPU use between two reads
    property real lastIdle: 0
    property real lastTotal: 0

    function levelColor(value, warn, high) {
        return value >= high ? Colors.text.danger : (value >= warn ? Colors.text.warning : Colors.text.color);
    }

    implicitWidth: row.implicitWidth + 12
    Layout.fillHeight: true

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
            if (root.lastTotal > 0 && total > root.lastTotal)
                root.cpu = 1 - (idle - root.lastIdle) / (total - root.lastTotal);
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
        }
    }

    // Constant text widths, so the bar does not move when the values change
    TextMetrics {
        id: percentMetrics
        text: "100%"
        font.pointSize: Colors.text.fontSize
        font.family: Colors.text.fontFamily
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
}
