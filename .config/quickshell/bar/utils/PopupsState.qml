pragma Singleton

import Quickshell

Singleton {
    id: root

    property list<var> popups: []

    function open(popup) {
        if (!popups.includes(popup)) {
            popups = popups.concat([popup]);
        }
    }

    function close(popup) {
        const index = popups.indexOf(popup);
        if (index !== -1) {
            popups = popups.slice(0, index).concat(popups.slice(index + 1));
        }
    }
}
