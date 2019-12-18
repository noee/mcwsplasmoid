import QtQuick 2.9
import QtQuick.Controls 2.5

BaseAction {
    shuffle: false
    icon.name: 'media-playlist-append'
    text: i18n("Current List")
    onTriggered: {
        if (trackView.showingPlaylist)
            zoneView.currentPlayer.addPlaylist(mcws.playlists.currentID, shuffle)
        else
            add(trackView.mcwsQuery)
    }
}
