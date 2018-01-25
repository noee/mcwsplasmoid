import org.kde.plasma.components 2.0 as PlasmaComponents

PlasmaComponents.ToolButton {
    iconSource: mute ? "player-volume-muted" : "player-volume"
    flat: false
    onClicked: mcws.toggleMute(index)
}
