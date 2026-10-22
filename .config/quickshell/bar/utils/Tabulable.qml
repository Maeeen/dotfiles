import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "transparent"

    property var selectedIndex: 0

    clip: true

    default property alias content: actualContent.data

    // Bindings on selectedItem, so the size follows when a tab is added later (e.g. a new player)
    property real sImplicitWidth: selectedItem?.implicitWidth ?? 0
    property real sImplicitHeight: selectedItem?.implicitHeight ?? 0
    property real sWidth: selectedItem?.width ?? 0
    property real sHeight: selectedItem?.height ?? 0

    implicitWidth: sImplicitWidth
    implicitHeight: sImplicitHeight

    width: Math.min(100, sWidth)
    height: Math.min(100, sHeight)

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    // Repeaters are children too, and they reorder their delegates without a childrenChanged
    // signal, so indexing children directly can return the Repeater. Skip them.
    property Item selectedItem: Array.from(actualContent.children).filter(c => !(c instanceof Repeater))[selectedIndex] ?? null

    RowLayout {
        id: actualContent
        x: root.selectedItem ? -root.selectedItem.x : 0

        width: root.width
        height: root.height

        Behavior on x {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }
    }
}
