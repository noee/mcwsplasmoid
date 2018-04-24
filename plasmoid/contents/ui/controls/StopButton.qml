import org.kde.plasma.components 2.0 as PlasmaComponents

PlasmaComponents.ToolButton {
    iconSource: "media-playback-stop"
    flat: true
    onClicked: mcws.stop(index)
}
