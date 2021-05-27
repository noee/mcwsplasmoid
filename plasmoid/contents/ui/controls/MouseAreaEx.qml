import QtQuick 2.9
import org.kde.plasma.components 3.0 as PComp

MouseArea {
    property alias tipText: tt.text
    property alias tipShown: tt.visible

    hoverEnabled: true
    anchors.fill: parent

    PComp.ToolTip {
        id: tt
        visible: text && containsMouse
        delay: Qt.styleHints.mousePressAndHoldInterval
    }

}


