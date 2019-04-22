import QtQuick.Controls 2.5

ToolButton {
    icon.name: "media-skip-backward"
    enabled: playingnowposition > 0
    onClicked: player.previous()
}
