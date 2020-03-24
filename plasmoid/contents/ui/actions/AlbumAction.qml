import QtQuick 2.9
import QtQuick.Controls 2.5

BaseAction {
    icon.name: 'media-album-cover'
    text: trackView.currentTrack ? album : ''
    onTriggered: {
        if (method !== '') {
            if (method === 'show')
                call[method]({'album': '[%1]'.arg(album)
                           ,'artist': '[%1]'.arg(artist)})
            else
                call[method]("album=[%1] and artist=[%2]"
                             .arg(album).arg(artist))
        }
    }
}
