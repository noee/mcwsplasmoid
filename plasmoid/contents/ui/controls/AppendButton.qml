import QtQuick 2.8
import org.kde.plasma.components 3.0 as PComp

PComp.ToolButton {
    icon.name: 'media-playlist-append'
    property alias tipText: tt.text
    PComp.ToolTip { id: tt; text: 'Append to Playing Now' }
}
