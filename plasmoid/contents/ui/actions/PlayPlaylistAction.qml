import QtQuick 2.9
import QtQuick.Controls 2.4

BaseAction {
    aText: 'Playlist: "%1"'.arg(playlistView.currentName)
    method: 'play'
    enabled: playlistView.viewer.count > 0
    onTriggered: {
        event.queueCall(() => {
            zoneView.currentPlayer.playPlaylist(playlistView.currentID, shuffle)
            mainView.currentIndex = 1
        })
    }
}
