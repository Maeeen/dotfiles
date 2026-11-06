import "root:/config"
import "root:/utils"
import Quickshell
import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts

// Settings of the bar: the theme, and its colors.
// A color changes with its hex field (Enter) or with the color picker (click the sample).
FloatingWindow {
    id: root
    title: "Bar settings"
    implicitWidth: 420
    implicitHeight: content.implicitHeight + 32
    // A fixed size: Hyprland makes such a window float, it does not tile it
    minimumSize: Qt.size(implicitWidth, implicitHeight)
    maximumSize: Qt.size(implicitWidth, implicitHeight)
    color: Colors.t(Theme.current.panel, 1)

    onClosed: Theme.settingsOpen = false

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        // The bar gradient, as a preview
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 8
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: Theme.current.barStart
                }
                GradientStop {
                    position: 1
                    color: Theme.current.barEnd
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 60
                height: 18
                radius: 9
                color: Colors.workspacePill

                Text {
                    anchors.centerIn: parent
                    text: Theme.name
                    color: Colors.workspaceNumber
                    font.pointSize: 9
                    font.bold: true
                    font.family: Colors.panelText.fontFamily
                }
            }
        }

        SectionTitle {
            text: "Theme"
        }

        // One button for each theme, with its gradient
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 6
            rowSpacing: 6

            Repeater {
                model: Theme.names

                Rectangle {
                    id: themeButton
                    required property string modelData
                    readonly property var colors: Object.assign({}, Theme.themes[modelData], Theme.overrides[modelData] ?? {})
                    readonly property bool selected: Theme.name === modelData

                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: 8
                    border.width: selected ? 2 : 0
                    border.color: Colors.panelText.color
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0
                            color: themeButton.colors.barStart
                        }
                        GradientStop {
                            position: 1
                            color: themeButton.colors.barEnd
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: themeButton.modelData
                        color: themeButton.colors.text
                        font.pointSize: Colors.panelText.fontSize
                        font.family: Colors.panelText.fontFamily
                        font.bold: themeButton.selected
                    }

                    HoverArea {
                        anchors.fill: parent
                        radius: parent.radius
                        onClicked: Theme.select(themeButton.modelData)
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8

            SectionTitle {
                Layout.fillWidth: true
                text: `Colors of ${Theme.name}`
            }

            // Only when the theme has changed colors
            Rectangle {
                visible: Theme.overrides[Theme.name] !== undefined
                implicitWidth: resetText.implicitWidth + 16
                implicitHeight: 22
                radius: 6
                color: Colors.workspaceCircle

                Text {
                    id: resetText
                    anchors.centerIn: parent
                    text: "Reset"
                    color: Colors.panelText.color
                    font.pointSize: Colors.panelText.fontSize - 1
                    font.family: Colors.panelText.fontFamily
                }

                HoverArea {
                    anchors.fill: parent
                    radius: parent.radius
                    onClicked: Theme.reset()
                }
            }
        }

        Repeater {
            model: Theme.colorNames

            RowLayout {
                id: colorRow
                required property var modelData
                readonly property string value: Theme.current[modelData.key]
                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: colorRow.modelData.label
                    color: Colors.panelText.color
                    font.pointSize: Colors.panelText.fontSize
                    font.family: Colors.panelText.fontFamily
                }

                // Hex field: Enter sets the color; a value that is not valid shows in the warning color
                Rectangle {
                    implicitWidth: 90
                    implicitHeight: 26
                    radius: 6
                    color: Colors.workspaceCircle

                    TextInput {
                        id: hex
                        readonly property bool valid: /^#[0-9a-fA-F]{6}$/.test(text)
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        text: colorRow.value
                        maximumLength: 7
                        color: valid ? Colors.panelText.color : Colors.panelText.warning
                        selectionColor: Colors.workspaceCircleActive
                        font.pointSize: Colors.panelText.fontSize
                        font.family: Colors.panelText.fontFamily
                        onAccepted: {
                            if (valid)
                                Theme.setColor(colorRow.modelData.key, text.toLowerCase());
                        }
                        // Back to the color in use when the field loses the focus
                        onActiveFocusChanged: {
                            if (!activeFocus)
                                text = Qt.binding(() => colorRow.value);
                        }
                    }
                }

                // Color sample: a click opens the color picker
                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: 13
                    color: colorRow.value
                    border.width: 1
                    border.color: Colors.workspaceCircleActive

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            picker.key = colorRow.modelData.key;
                            picker.selectedColor = colorRow.value;
                            picker.open();
                        }
                    }
                }
            }
        }
    }

    ColorDialog {
        id: picker
        property string key
        title: "Select a color"
        onAccepted: Theme.setColor(key, selectedColor.toString().slice(0, 7))
    }

    component SectionTitle: Text {
        color: Colors.panelText.secondary
        font.pointSize: Colors.panelText.fontSize
        font.family: Colors.panelText.fontFamily
        font.weight: Font.Medium
    }
}
