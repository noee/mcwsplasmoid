import QtQuick 2.15
import org.kde.plasma.components 3.0 as PComp
import '..'

PComp.ToolButton {
    action: player.play
    icon.name: model.state === PlayerState.Playing
                ? "media-playback-pause"
                : "media-playback-start"
    enabled: playingnowtracks > 0
}
