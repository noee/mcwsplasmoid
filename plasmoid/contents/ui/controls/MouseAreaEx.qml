import QtQuick 2.9
import QtQuick.Controls 2.4

MouseArea {
    property alias tipText: tt.text
    property alias tipShown: tt.visible

    hoverEnabled: true
    anchors.fill: parent

    ToolTip {
        id: tt
        visible: text && containsMouse
        delay: Qt.styleHints.mousePressAndHoldInterval

        contentItem: Text {
            text: tt.text
            font: tt.font
            color: theme.textColor
        }

        background: Rectangle {
            border.color: "#21be2b"
            color: theme.backgroundColor
        }
    }

}


