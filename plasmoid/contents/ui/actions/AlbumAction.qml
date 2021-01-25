import QtQuick 2.9
import QtQuick.Controls 2.5

BaseAction {
    defaultIcon: 'media-album-cover'
    aText: album ?? '<unknown>'
    onTriggered: {
        if (method !== '') {
            if (method === 'show') {
                call[method]({'album': '[%1]'.arg(album)
                           ,'artist': '[%1]'.arg(artist)})
            } else if (method === 'play') {
                trkCmds.close()
                zoneView.currentPlayer.playAlbum(key)
            } else
                call[method]("album=[%1] and artist=[%2]"
                             .arg(album).arg(artist))
        }
    }
}
