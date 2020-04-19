import QtQuick 2.9
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.8 as Kirigami

RowLayout {
    id: root
    property alias text: label.text
    property color textColor: Kirigami.Theme.textColor
    property color color: Kirigami.Theme.disabledTextColor
    property real size: 1
    property int borderWidth: 0

    Kirigami.Heading {
        id: label
        level: 3
        visible: text
        color: root.textColor
    }

    Rectangle {
        id: line
        Layout.preferredHeight: root.size
        Layout.fillWidth: true
        color: root.color
        border.width: root.borderWidth
    }
}

