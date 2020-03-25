import QtQuick 2.9
import QtQuick.Controls 2.5

BaseAction {
    defaultIcon: 'view-media-artist'
    aText: trackView.currentTrack ? trackView.currentTrack.artist : ''
    onTriggered: {
        if (method !== '') {
            if (method === 'show')
                call[method]({ artist: '[%1]'.arg(trackView.currentTrack.artist) })
            else
                call[method]("artist=[%1]".arg(trackView.currentTrack.artist))
        }
    }
}
