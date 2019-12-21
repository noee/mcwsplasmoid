import QtQuick 2.9
import QtQuick.Controls 2.4

Action {
    icon.name: 'query'
    enabled: mcws.playlists.currentIndex !== -1
    onTriggered: {
        event.queueCall(() => {
            mcws.playlists.trackModel.load()
            trackView.showPlaylist()
        })
    }
}
