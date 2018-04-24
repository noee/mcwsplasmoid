import org.kde.plasma.components 2.0 as PlasmaComponents

PlasmaComponents.ToolButton {
    iconSource: "media-skip-backward"
    flat: true
    enabled: +playingnowposition > 0
    onClicked: mcws.previous(index)
}
