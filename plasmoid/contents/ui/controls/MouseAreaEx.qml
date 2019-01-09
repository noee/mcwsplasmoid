import QtQuick 2.9
import QtQuick.Controls 2.4

MouseArea {
    property alias tipText: tt.text
    property alias tipShown: tt.visible

    hoverEnabled: true
    anchors.fill: parent

    ToolTip {
        id: tt
        visible: containsMouse
        delay: Qt.styleHints.mousePressAndHoldInterval
    }

}


