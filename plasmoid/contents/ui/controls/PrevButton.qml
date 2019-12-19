import QtQuick.Controls 2.5

ToolButton {
    action: player.previous
    enabled: playingnowposition > 0
}
