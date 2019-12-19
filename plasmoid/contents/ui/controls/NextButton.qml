import QtQuick.Controls 2.5

ToolButton {
    action: player.next
    enabled: nextfilekey !== -1
}
