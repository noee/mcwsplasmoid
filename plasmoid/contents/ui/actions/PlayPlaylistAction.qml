import QtQuick 2.9
import QtQuick.Controls 2.4

BaseAction {
    aText: 'Playlist: "%1"'.arg(mcws.playlists.currentName)
    method: 'play'
    enabled: mcws.playlists.currentIndex !== -1
    onTriggered: {
        event.queueCall(() => {
            zoneView.currentPlayer.playPlaylist(mcws.playlists.currentID, shuffle)
            mainView.currentIndex = 1
        })
    }
}
