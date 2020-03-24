import QtQuick 2.9
import QtQuick.Controls 2.5

BaseAction {
    icon.name: 'view-media-artist'
    text: trackView.currentTrack ? artist : ''
    onTriggered: {
        if (method !== '') {
            if (method === 'show')
                call[method]({ artist: '[%1]'.arg(artist) })
            else
                call[method]("artist=[%1]".arg(artist))
        }
    }
}
