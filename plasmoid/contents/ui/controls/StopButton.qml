import org.kde.plasma.components 3.0 as PlasmaComponents

PlasmaComponents.ToolButton {
    icon.name: "media-playback-stop"
    flat: true
    onClicked: mcws.stop(index)
}
