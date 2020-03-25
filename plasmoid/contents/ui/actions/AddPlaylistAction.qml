import QtQuick 2.9
import QtQuick.Controls 2.4

BaseAction {
    aText: 'Playlist: ' + mcws.playlists.currentName
    defaultIcon: 'media-playlist-append'
    method: 'add'
    enabled: mcws.playlists.currentIndex !== -1
    onTriggered: {
        event.queueCall(() => {
            zoneView.currentPlayer.addPlaylist(mcws.playlists.currentID, shuffle)
        })
    }
}
