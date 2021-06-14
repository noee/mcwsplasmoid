import QtQuick 2.9
import QtQuick.Controls 2.4

BaseAction {
    aText: 'Playlist: ' + playlistView.currentName
    defaultIcon: 'media-playlist-append'
    method: 'add'
    enabled: playlistView.viewer.count > 0
    onTriggered: {
        event.queueCall(() => {
            zoneView.currentPlayer.addPlaylist(playlistView.currentID, shuffle)
        })
    }
}
