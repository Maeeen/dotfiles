pragma Singleton

import Quickshell

Singleton {
    id: root

    function getDesktopEntry(name: string, broad = false): DesktopEntry {
        name = name.toLowerCase().replace(/ /g, "-");

        return DesktopEntries.applications.values.find(a => {
            return a.id.toLowerCase() === name || a.name.replace(/ /g, "-").toLowerCase().indexOf(name) !== -1;
        }) ?? null;
    }

    function getAppIcon(name: string, fallback: string): string {
        const x = Quickshell.iconPath(getDesktopEntry(name)?.icon, fallback);
        return x;
    }

    function getPlayerIcon(player): string {
        if (player.identity && player.identity.length > 0) {
            return getAppIcon(player.identity, "quickshell", true);
        } else {
            return getAppIcon(player.desktopEntry, "quickshell", true);
        }
    }
}
