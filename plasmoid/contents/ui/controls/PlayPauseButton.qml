import org.kde.plasma.components 2.0 as PlasmaComponents

PlasmaComponents.ToolButton {
    iconSource: model.state === mcws.statePlaying
                ? "media-playback-pause"
                : "media-playback-start"
    flat: false
    onClicked: mcws.play(index)
}
