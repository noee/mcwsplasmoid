import QtQuick.Controls 2.5

ToolButton {
    action: player.stop
    enabled: playingnowtracks > 0
}
