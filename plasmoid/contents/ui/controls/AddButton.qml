import QtQuick 2.8
import org.kde.plasma.components 3.0 as PComp

PComp.ToolButton {
    icon.name: 'playlist-queue'
    property alias tipText: tt.text
    PComp.ToolTip { id: tt; text: 'Add Next to Play' }
}
