import QtQuick 2.2
import QtQuick.Layouts 1.3
import Qt.labs.platform 1.0

Item {
    property alias chosenFont: fontDlg.font

    width: childrenRect.width
    height: childrenRect.height
    Layout.alignment: Qt.AlignVCenter

    Rectangle {
        height: 25
        width: 250
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: "The Quick Brown Lazy Fox"
            anchors.fill: parent
            font: fontDlg.font
        }


        FontDialog {
            id: fontDlg
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: fontDlg.open()
    }
}
