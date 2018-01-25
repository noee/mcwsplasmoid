import org.kde.plasma.components 2.0 as PlasmaComponents

PlasmaComponents.ToolButton {
    iconSource: "media-skip-forward"
    enabled: nextfilekey !== "-1"
    flat: false
    onClicked: mcws.next(index)
}
