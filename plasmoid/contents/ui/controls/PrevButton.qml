import org.kde.plasma.components 2.0 as PlasmaComponents

PlasmaComponents.ToolButton {
    iconSource: "media-skip-backward"
    flat: false
    enabled: playingnowposition !== "0"
    onClicked: mcws.previous(index)
}
