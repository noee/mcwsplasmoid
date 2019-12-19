import QtQuick 2.9
import QtQuick.Controls 2.5

BaseAction {
    icon.name: 'view-media-genre'
    text: track ? i18n(track.genre) : ''
    onTriggered: {
        if (method !== '') {
            if (method === 'show')
                call[method]({ genre: '[%1]'.arg(track.genre) })
            else
                call[method]("genre=[%1]".arg(track.genre))
        }
    }
}
