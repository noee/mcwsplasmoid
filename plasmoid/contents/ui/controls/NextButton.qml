import QtQuick.Controls 2.5

ToolButton {
    icon.name: "media-skip-forward"
    enabled: nextfilekey !== "-1"
    onClicked: player.next()
}
