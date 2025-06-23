pragma Singleton

import Quickshell

Singleton {
    id: root

    property list<var> popups: []

    function open(popup) {
        console.log("Opening popup:", popup);
        if (!popups.includes(popup)) {
            popups = popups.concat([popup]);
        }
        console.log("Popups after opening:", popups);
    }

    function close(popup) {
        console.log("Closing popup:", popup);
        const index = popups.indexOf(popup);
        if (index !== -1) {
            popups = popups.slice(0, index).concat(popups.slice(index + 1));
        }
        console.log("Popups after closing:", popups);
    }
}
