import QtQuick 2.9
import QtQuick.Controls 2.4

Action {
    text: "Remove Track"
    icon.name: 'list-remove'
    onTriggered: {
        zoneView.currentPlayer.removeTrack(trackView.viewer.currentIndex)
    }
}
