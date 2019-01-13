import org.kde.plasma.components 3.0 as PlasmaComponents
import '..'

PlasmaComponents.ToolButton {
    icon.name: model.state === PlayerState.Playing
                ? "media-playback-pause"
                : "media-playback-start"
    flat: true
    enabled: playingnowtracks > 0
    onClicked: player.play()
}
