import QtQuick 2.12
import QtQuick.Controls 2.12
import org.kde.plasma.components 3.0 as PComp

PComp.ToolButton {
    icon.name: 'search'
    property alias tipText: tt.text
    ToolTip { id: tt; text: 'Show Details' }
}
