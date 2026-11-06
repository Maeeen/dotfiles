import QtQuick

// Animation of the bar items when their width changes, so the items next to them slide instead of jumping
NumberAnimation {
    duration: 150
    easing.type: Easing.InOutQuad
}
