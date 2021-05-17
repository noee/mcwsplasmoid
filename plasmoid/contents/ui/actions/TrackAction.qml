import QtQuick 2.9

BaseAction {
    aText: name ?? '<unknown>'
    onTriggered: {
        if (method === 'play') {
            if (trackView.searchMode)
                zoneView.currentPlayer.playTrackByKey(key)
            else
                zoneView.currentPlayer.playTrack(index)
        } else if (method === 'add') {
             zoneView.currentPlayer.addTrack(key)
        } else if (method === 'remove') {
             zoneView.currentPlayer.removeTrack(index)
        }
    }
}
