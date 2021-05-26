import QtQuick 2.15
import org.kde.plasma.components 3.0 as PComp

PComp.ToolButton {
    icon.name: "media-playback-start"
    property alias tipText: tt.text
    PComp.ToolTip { id: tt; text: 'Play Now' }
}
