import QtQuick 2.9
import QtQuick.Controls 2.5

BaseAction {
    icon.name: 'media-album-cover'
    text: track ? i18n(track.album) : ''
    onTriggered: {
        if (method !== '') {
            if (method === 'show')
                call[method]({'album': '[%1]'.arg(track.album)
                           ,'artist': '[%1]'.arg(track.artist)})
            else
                call[method]("album=[%1] and artist=[%2]".arg(track.album).arg(track.artist))
        }
    }
}
