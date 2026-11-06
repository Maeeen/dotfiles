import "root:/config"
import "root:/serv"
import "root:/utils"
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "../utils/Calc.js" as Calc

// App launcher: a search field and the matching applications.
// Up and Down select, Enter starts the application, Escape closes.
// A query that starts with "=" is a calculation: Enter copies the result.
// A query that starts with "clip:" searches the clipboard history: Enter copies the entry again.
PopupWrapper {
    id: root
    readonly property bool shown: LauncherState.screenName !== "" && LauncherState.screenName === screen?.name
    property string query: ""
    // Index of the selected application in `results`
    property int current: 0
    // Index of the first shown row: the list scrolls so the selected row stays shown
    property int first: 0
    readonly property int rows: 8

    // The settings of the bar, as an entry like an application
    readonly property var settingsEntry: ({
            name: "Bar settings",
            genericName: "Theme and colors",
            comment: "Change the theme and the colors of the bar",
            id: "quickshell-bar-settings",
            icon: "preferences-desktop-theme",
            keywords: ["settings", "theme", "colors", "bar", "quickshell"],
            execute: () => Theme.settingsOpen = true
        })

    readonly property bool calcMode: query.startsWith("=")
    // "" while the expression is not complete or not valid
    readonly property string calcResult: calcMode ? Calc.evaluate(query.slice(1)) : ""

    // Read always, so the clipboard history starts to record when the bar starts
    readonly property var clipHistory: Clipboard.history
    readonly property bool clipMode: query.startsWith("clip:")
    readonly property var clipResults: {
        if (!clipMode)
            return [];
        const q = query.slice(5).trim().toLowerCase();
        return clipHistory.filter(t => t.toLowerCase().includes(q));
    }
    // Number of rows that can be selected
    readonly property int count: clipMode ? clipResults.length : results.length

    // Applications that match the query: first a match at the start of the name,
    // then at the start of a word of the name, then in the name, then in the other fields
    readonly property var results: {
        if (calcMode || clipMode)
            return [];
        const q = query.trim().toLowerCase();
        const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay).concat([settingsEntry]);
        const score = a => {
            const name = a.name.toLowerCase();
            if (name.startsWith(q))
                return 0;
            if (name.split(/\s+/).some(w => w.startsWith(q)))
                return 1;
            if (name.includes(q))
                return 2;
            const other = [a.genericName, a.comment, a.id, ...(a.keywords ?? [])].join(" ").toLowerCase();
            return other.includes(q) ? 3 : -1;
        };
        return apps.map(a => ({
                    a,
                    s: score(a)
                })).filter(x => x.s >= 0).sort((x, y) => x.s - y.s || x.a.name.localeCompare(y.a.name)).map(x => x.a);
    }

    requestOpen: shown

    onShownChanged: {
        if (shown) {
            input.text = "";
            input.forceActiveFocus();
        } else {
            // Also when the mouse is on the popup
            close();
        }
    }

    onResultsChanged: {
        current = 0;
        first = 0;
    }

    onClipResultsChanged: {
        current = 0;
        first = 0;
    }

    onCurrentChanged: {
        if (current < first)
            first = current;
        else if (current >= first + rows)
            first = current - rows + 1;
    }

    // Puts the result on the clipboard, ready to paste
    function copyResult() {
        if (!calcResult)
            return;
        Quickshell.execDetached(["wl-copy", calcResult]);
        LauncherState.close();
    }

    function copyClip(text) {
        if (text === undefined)
            return;
        Clipboard.copy(text);
        LauncherState.close();
    }

    function launch(entry) {
        if (!entry)
            return;
        entry.execute();
        LauncherState.close();
    }

    ColumnLayout {
        width: 480
        spacing: 6

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 32
            radius: 8
            color: Colors.workspaceCircle

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                color: Colors.text.color
                selectionColor: Colors.workspaceCircleActive
                font.pointSize: Colors.text.fontSize + 1
                font.family: Colors.text.fontFamily
                onTextChanged: root.query = text

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                        root.current = Math.min(root.count - 1, root.current + 1);
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                        root.current = Math.max(0, root.current - 1);
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (root.calcMode)
                            root.copyResult();
                        else if (root.clipMode)
                            root.copyClip(root.clipResults[root.current]);
                        else
                            root.launch(root.results[root.current]);
                    } else if (event.key === Qt.Key_Escape) {
                        LauncherState.close();
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

                Text {
                    visible: !input.text
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search apps, = to calculate, clip: for the clipboard"
                    color: Colors.text.secondary
                    font: input.font
                }
            }
        }

        Repeater {
            model: root.results.slice(root.first, root.first + root.rows)

            Rectangle {
                id: row
                // A DesktopEntry, or settingsEntry
                required property var modelData
                required property int index
                readonly property bool selected: root.first + index === root.current

                Layout.fillWidth: true
                implicitHeight: 32
                radius: 6
                // Transparent white when off, so the fade does not go through gray
                color: selected ? Colors.workspaceCircleActive : Qt.rgba(1, 1, 1, 0)

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                        easing.type: Easing.InOutQuad
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    // Empty space when the icon theme does not have the icon
                    IconImage {
                        implicitSize: 22
                        source: Quickshell.iconPath(row.modelData.icon, true)
                    }

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.name
                        elide: Text.ElideRight
                        color: Colors.text.color
                        font.pointSize: Colors.text.fontSize
                        font.family: Colors.text.fontFamily
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.current = root.first + row.index
                    onClicked: root.launch(row.modelData)
                }
            }
        }

        // Clipboard entries, on one line each
        Repeater {
            model: root.clipResults.slice(root.first, root.first + root.rows)

            Rectangle {
                id: clipRow
                required property string modelData
                required property int index
                readonly property bool selected: root.first + index === root.current

                Layout.fillWidth: true
                implicitHeight: 32
                radius: 6
                // Transparent white when off, so the fade does not go through gray
                color: selected ? Colors.workspaceCircleActive : Qt.rgba(1, 1, 1, 0)

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                        easing.type: Easing.InOutQuad
                    }
                }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: Text.AlignVCenter
                    text: clipRow.modelData.trim().replace(/\s+/g, " ")
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    color: Colors.text.color
                    font.pointSize: Colors.text.fontSize
                    font.family: Colors.text.fontFamily
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.current = root.first + clipRow.index
                    onClicked: root.copyClip(clipRow.modelData)
                }
            }
        }

        // Result of the calculation. Enter or a click copies it.
        Rectangle {
            visible: root.calcMode
            Layout.fillWidth: true
            implicitHeight: 40
            radius: 6
            // Transparent white when off, so the fade does not go through gray
            color: root.calcResult ? Colors.workspaceCircleActive : Qt.rgba(1, 1, 1, 0)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: root.calcResult || "…"
                    elide: Text.ElideRight
                    color: root.calcResult ? Colors.text.color : Colors.text.secondary
                    font.pointSize: Colors.text.fontSize + 4
                    font.family: Colors.text.fontFamily
                }

                Text {
                    visible: root.calcResult !== ""
                    text: "Enter to copy"
                    color: Colors.text.secondary
                    font.pointSize: Colors.text.fontSize
                    font.family: Colors.text.fontFamily
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.calcResult !== ""
                cursorShape: Qt.PointingHandCursor
                onClicked: root.copyResult()
            }
        }

        Text {
            visible: root.count === 0 && !root.calcMode
            Layout.leftMargin: 8
            Layout.bottomMargin: 4
            text: root.clipMode ? "No clipboard entry" : "No application found"
            color: Colors.text.secondary
            font.pointSize: Colors.text.fontSize
            font.family: Colors.text.fontFamily
        }
    }
}
