import QtQuick 2.2
import QtQuick.Layouts 1.3
import Qt.labs.platform 1.0

Item {
    property alias chosenColor: colorDlg.color

    width: childrenRect.width
    height: childrenRect.height
    Layout.alignment: Qt.AlignVCenter

    Rectangle {
        color: colorDlg.color
        height: 25
        width: height
        border {
            width: mouseArea.containsMouse ? 2 : .75
            color: Qt.darker(colorDlg.color, 1.5)
        }

        ColorDialog {
            id: colorDlg
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: colorDlg.open()
    }
}
