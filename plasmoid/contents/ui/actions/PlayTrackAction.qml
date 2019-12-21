import QtQuick 2.9
import QtQuick.Controls 2.4

Action {
    text: 'Play Track'
    icon.name: 'media-playback-start'
    onTriggered: {
        if (trackView.searchMode)
            zoneView.currentPlayer.playTrackByKey(trackView.currentTrack.key)
        else
            zoneView.currentPlayer.playTrack(trackView.viewer.currentIndex)
    }
}
