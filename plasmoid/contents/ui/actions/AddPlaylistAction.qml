import QtQuick 2.9
import QtQuick.Controls 2.4

BaseAction {
    text: 'Playlist: ' + mcws.playlists.currentName
    icon.name: 'media-playlist-append'
    enabled: mcws.playlists.currentIndex !== -1
    onTriggered: {
        event.queueCall(() => {
            zoneView.currentPlayer.addPlaylist(mcws.playlists.currentID, shuffle)
        })
    }
}
