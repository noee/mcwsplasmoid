import QtQuick 2.15
import org.kde.plasma.components 3.0 as PComp

PComp.ToolButton {
    action: model.player.previous
    enabled: model.playingnowposition > 0
}
