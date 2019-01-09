import org.kde.plasma.components 3.0 as PlasmaComponents

PlasmaComponents.ToolButton {
    icon.name: "media-skip-backward"
    flat: true
    enabled: +playingnowposition > 0
    onClicked: mcws.previous(index)
}
