import QtQuick 2.9
import QtQuick.Controls 2.5

BaseAction {
    icon.name: 'view-media-genre'
    text: trackView.currentTrack ? i18n(trackView.currentTrack.genre) : ''
    onTriggered: {
        if (method !== '') {
            if (method === 'show')
                call[method]({ genre: '[%1]'.arg(trackView.currentTrack.genre) })
            else
                call[method]("genre=[%1]".arg(trackView.currentTrack.genre))
        }
    }
}
