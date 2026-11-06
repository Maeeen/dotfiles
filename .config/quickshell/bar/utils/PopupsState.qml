pragma Singleton

import Quickshell

Singleton {
    id: root

    // Initialize popups as a JavaScript object (dictionary)
    property var popups: ({})
    // Name of the screen where a popup has a text field (for example a password), "" when none.
    // The bar window of that screen takes the keyboard.
    property string keyboardScreen: ""

    function open(screen, popup) {
        if (!screen || !popup) {
            console.warn("PopupsState: open called with invalid parameters", screen, popup);
            return;
        }
        let current = root.popups[screen];
        if (!current) {
            current = [];
        }

        if (!current.includes(popup)) {
            current = current.concat([popup]);
        }

        // Important: trigger reactivity by replacing the array
        const newPopups = Object.assign({}, root.popups);
        newPopups[screen] = current;
        root.popups = newPopups;
    }

    function close(screen, popup) {
        if (!screen || !popup) {
            console.warn("PopupsState: close called with invalid parameters", screen, popup);
            return;
        }

        let current = root.popups[screen];
        if (!current) {
            return;
        }

        const index = current.indexOf(popup);
        if (index !== -1) {
            current = current.slice(0, index).concat(current.slice(index + 1));
        }

        const newPopups = Object.assign({}, root.popups);
        newPopups[screen] = current;
        root.popups = newPopups;
    }
}

