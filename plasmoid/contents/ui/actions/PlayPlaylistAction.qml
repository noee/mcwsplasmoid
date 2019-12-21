import QtQuick 2.9
import QtQuick.Controls 2.4

BaseAction {
    text: 'Playlist: ' + mcws.playlists.currentName
    icon.name: 'media-playback-start'
    enabled: mcws.playlists.currentIndex !== -1
    onTriggered: {
        event.queueCall(() => {
            zoneView.currentPlayer.playPlaylist(mcws.playlists.currentID, shuffle)
        })
    }
}
