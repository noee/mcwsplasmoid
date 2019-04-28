import QtQuick.Controls 2.5

ToolButton {
    icon.name: "media-playback-stop"
    enabled: playingnowtracks > 0
    onClicked: player.stop()
}
