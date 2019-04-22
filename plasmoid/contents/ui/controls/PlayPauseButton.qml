import QtQuick.Controls 2.5
import '..'

ToolButton {
    icon.name: model.state === PlayerState.Playing
                ? "media-playback-pause"
                : "media-playback-start"
    enabled: playingnowtracks > 0
    onClicked: player.play()
}
