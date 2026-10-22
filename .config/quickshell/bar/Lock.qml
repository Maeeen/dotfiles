import "root:/widgets"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Window

// Lock screen: the session lock on all screens, the password check and a preview window.
// Lock: `qs -c bar ipc call lock lock`. Preview in a window: `qs -c bar ipc call lock preview`.
Scope {
    id: root

    property string password: ""
    property bool failed: false
    property bool capsLock: false
    // True from a correct password until the copies below have drawn
    property bool unlocking: false
    property int copiesDrawn: 0
    // True while the lock screen fades out
    property bool fadeOut: false
    readonly property bool busy: pam.active

    function submit() {
        if (pam.active || unlocking || fadeOut || password === "")
            return;
        failed = false;
        pam.start();
    }

    function copyDrawn() {
        copiesDrawn++;
        if (copiesDrawn >= Quickshell.screens.length)
            removeLock();
    }

    function removeLock() {
        if (!unlocking)
            return;
        // fadeOut first, so the copy loader stays active
        fadeOut = true;
        unlocking = false;
        persist.locked = false;
    }

    function checkCapsLock() {
        capsProc.running = true;
    }

    // Keeps the lock when the config reloads
    PersistentProperties {
        id: persist
        reloadableId: "lockState"
        property bool locked: false
        property bool preview: false
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            persist.locked = true;
        }

        function preview(): void {
            persist.preview = !persist.preview;
        }
    }

    // Same PAM file as hyprlock
    PamContext {
        id: pam
        config: "hyprlock"
        onPamMessage: {
            if (responseRequired)
                respond(root.password);
        }
        onCompleted: result => {
            // On success the dots stay during the fade out; the timer below clears them
            if (result === PamResult.Success) {
                if (persist.preview) {
                    root.fadeOut = true;
                } else {
                    root.copiesDrawn = 0;
                    root.unlocking = true;
                }
            } else {
                root.password = "";
                root.failed = true;
            }
        }
    }

    // Hyprland shows black behind a lock surface, so the fade out cannot be on the lock.
    // A copy on an overlay layer draws under the lock, then the lock goes away and the copy fades out.
    // The copy is made only now: under the lock Hyprland asks for no new frames, so an older copy shows old content.

    // If a copy does not draw, do not stay locked
    Timer {
        running: root.unlocking
        interval: 500
        onTriggered: root.removeLock()
    }

    Timer {
        running: root.fadeOut
        interval: 300
        onTriggered: {
            root.password = "";
            persist.preview = false;
            root.fadeOut = false;
            root.failed = false;
        }
    }

    LazyLoader {
        active: root.unlocking || root.fadeOut && !persist.preview

        Variants {
            model: Quickshell.screens

            PanelWindow {
                required property var modelData
                screen: modelData
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                // Clicks go through during the fade out
                mask: Region {}
                WlrLayershell.layer: WlrLayer.Overlay
                // Not "quickshell", so the blur layer rule does not apply
                WlrLayershell.namespace: "quickshell-lock"

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                LockContent {
                    id: copy
                    anchors.fill: parent
                    lock: root
                    opacity: root.fadeOut ? 0 : 1

                    property bool drawn: false
                    Connections {
                        target: copy.Window.window
                        function onFrameSwapped() {
                            if (copy.drawn)
                                return;
                            copy.drawn = true;
                            root.copyDrawn();
                        }
                    }
                }
            }
        }
    }

    Process {
        id: capsProc
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.capsLock = JSON.parse(text).keyboards.some(k => k.capsLock)
        }
    }

    WlSessionLock {
        locked: persist.locked

        WlSessionLockSurface {
            color: "transparent"

            LockContent {
                anchors.fill: parent
                lock: root
            }
        }
    }

    LazyLoader {
        active: persist.preview

        FloatingWindow {
            title: "Lock preview"
            implicitWidth: 1280
            implicitHeight: 800
            color: "transparent"

            LockContent {
                anchors.fill: parent
                lock: root
                opacity: root.fadeOut ? 0 : 1
            }
        }
    }
}
