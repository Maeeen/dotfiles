import "root:/utils"
import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Hyprland

// FloatingWindow {
//
//     Button {
//         onClicked: {
//             root.select((root.selectedIndex + 1) % actualContent.children.length);
//         }
//     }
//
//     Rectangle {
//         x: 100
//         y: 100
//         id: root
//         color: Qt.rgba(0, 0, 0, .3)
//
//         property int selectedIndex: 0
//
//         clip: true
//         default property alias content: actualContent.data
//
//         function select(index) {
//             if (index >= 0 && index < actualContent.children.length) {
//                 selectedIndex = index;
//                 actualContent.x = -actualContent.children[index].x;
//             }
//         }
//
//         // implicitWidth: actualContent.children[index].implicitWidth
//         // implicitHeight: actualContent.children[index].implicitHeight
//         width: actualContent.children[selectedIndex].width
//         height: actualContent.children[selectedIndex].height
//         // anchors.fill: parent
//
//         RowLayout {
//             id: actualContent
//             x: actualContent.children[root.selectedIndex].x
//
//             width: actualContent.children[0].width
//             height: actualContent.children[0].height
//
//             Behavior on x {
//                 NumberAnimation {
//                     duration: 400
//                     easing.type: Easing.InOutQuad
//                 }
//             }
//
//             Text {
//                 text: "Hi"
//             }
//
//             Text {
//                 text: "Hi 2"
//             }
//         }
//     }
// }
//

Scope {
    ExclusionZoneBar {}
    Bar {}
}
