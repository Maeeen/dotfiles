import "root:/config"
import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Effects

// What the lock screen shows: blurred wallpaper, SBB clock, date, user name and password field.
Item {
    id: root
    required property var lock

    // Fade in when shown
    property bool shown: false
    Component.onCompleted: shown = true
    opacity: shown ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: 300
            easing.type: Easing.InOutQuad
        }
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: Config.lockWallpaper
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blur: 0.6
        blurMax: 48
        brightness: -0.3
    }

    Column {
        anchors.centerIn: parent
        spacing: 24

        SbbClock {
            anchors.horizontalCenter: parent.horizontalCenter
            size: Math.min(root.height * 0.42, 420)
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
            color: Colors.text.secondary
            font.family: Colors.text.fontFamily
            font.pixelSize: 22

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 16
            text: Quickshell.env("USER")
            color: Colors.text.color
            font.family: Colors.text.fontFamily
            font.pixelSize: 28
            font.bold: true
        }

        TextField {
            id: field
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300
            height: 56
            focus: true
            readOnly: root.lock.busy
            echoMode: TextInput.Password
            passwordCharacter: "●"
            horizontalAlignment: TextInput.AlignHCenter
            color: Colors.text.color
            font.family: Colors.text.fontFamily
            font.pixelSize: 18
            placeholderText: root.lock.failed ? "Authentication failed" : "Input Password…"
            placeholderTextColor: root.lock.failed ? Colors.text.danger : Colors.text.secondary

            text: root.lock.password
            onTextEdited: {
                root.lock.password = text;
                root.lock.failed = false;
            }
            onAccepted: root.lock.submit()
            Keys.onEscapePressed: root.lock.password = ""
            Keys.onPressed: root.lock.checkCapsLock()

            background: Rectangle {
                radius: height / 2
                color: Qt.rgba(0, 0, 0, 0.2)
                border.width: 2
                border.color: root.lock.busy ? "#cc8822" : root.lock.failed ? Colors.text.danger : Qt.rgba(1, 1, 1, 0.15)

                Behavior on border.color {
                    ColorAnimation {
                        duration: 200
                    }
                }
            }

            transform: Translate {
                id: shake
            }

            Connections {
                target: root.lock
                function onFailedChanged() {
                    if (root.lock.failed)
                        shakeAnim.restart();
                }
            }

            SequentialAnimation {
                id: shakeAnim
                loops: 2
                NumberAnimation {
                    target: shake
                    property: "x"
                    to: -10
                    duration: 50
                }
                NumberAnimation {
                    target: shake
                    property: "x"
                    to: 10
                    duration: 100
                }
                NumberAnimation {
                    target: shake
                    property: "x"
                    to: 0
                    duration: 50
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Caps Lock is on"
            color: Colors.text.warning
            font.family: Colors.text.fontFamily
            font.pixelSize: 14
            opacity: root.lock.capsLock ? 1 : 0
        }
    }
}
