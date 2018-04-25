import org.kde.plasma.components 2.0 as PlasmaComponents

PlasmaComponents.ToolButton {
    iconSource: "media-playback-stop"
    flat: plasmoid.configuration.flatButtons
    onClicked: mcws.stop(index)
}
