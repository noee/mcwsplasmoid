import QtQuick 2.9
import QtQuick.Controls 2.4

Action {
    text: "Add Track"
    icon.name: 'list-add'
    onTriggered: zoneView.currentPlayer.addTrack(trackView.currentTrack.key)
}
