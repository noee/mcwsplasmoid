import QtQuick 2.9
import QtQuick.Controls 2.5

BaseAction {
    defaultIcon: 'media-album-cover'
    aText: trackView.currentTrack ? trackView.currentTrack.album : ''
    onTriggered: {
        if (method !== '') {
            if (method === 'show') {
                call[method]({'album': '[%1]'.arg(trackView.currentTrack.album)
                           ,'artist': '[%1]'.arg(trackView.currentTrack.artist)})
            } else if (method === 'play') {
                trkCmds.close()
                zoneView.currentPlayer.playAlbum(trackView.currentTrack.key)
            } else
                call[method]("album=[%1] and artist=[%2]"
                             .arg(trackView.currentTrack.album).arg(trackView.currentTrack.artist))
        }
    }
}
