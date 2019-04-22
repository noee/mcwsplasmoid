import QtQuick.Controls 2.5

ToolButton {
    icon.name: "media-playback-stop"
    onClicked: player.stop()
}
