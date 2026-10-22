import "root:/config"
import Quickshell

Variants {
    model: Quickshell.screens

    PanelWindow {
        property var modelData
        property var barHeight: Config.barHeight

        screen: modelData
        implicitHeight: barHeight

        anchors {
            top: true
            left: true
            right: true
        }
        
        mask: Region { }

        color: "transparent"
    }
}
