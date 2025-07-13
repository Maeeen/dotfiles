pragma Singleton

import Quickshell.Services.Mpris
import Quickshell

Singleton {
    id: root

    property list<MprisPlayer> players: Mpris.players.values
    property MprisPlayer mainPlayer: pickPlayer(players)

    onPlayersChanged: {
        console.log("MusicState: Players changed, updating main player");

        const p = pickPlayer(players);
        if (p)
            mainPlayer = p;
    }

    function pickPlayer(players) {
        // Priority, pick one that plays
        const playing = players.filter(p => p.isPlaying);
        if (playing)
            return playing[0];
        const spotify = players.filter(p => p.identity == "Spotify");
        if (spotify)
            return spotify[0];
        return players[0] || null;
    }
}
