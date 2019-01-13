import org.kde.plasma.components 3.0 as PlasmaComponents

PlasmaComponents.ToolButton {
    icon.name: "media-skip-forward"
    enabled: nextfilekey !== "-1"
    flat: true
    onClicked: player.next()
}
