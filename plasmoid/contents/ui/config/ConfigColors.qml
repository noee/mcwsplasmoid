import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.0

Item {
    id: colorSettings

    property alias cfg_listTextColor: listTextColorChoice.chosenColor
    property alias cfg_highlightColor: highlightColorChoice.chosenColor

    GroupBox {
        flat: true

        width: parent.width
        height: parent.height

        GridLayout {
            columns: 2
            anchors.left: parent.left
            anchors.leftMargin: units.largeSpacing

            Label{Layout.columnSpan: 2}
            Label {
                text: i18n("List Text:")
                Layout.alignment: Qt.AlignRight
            }
            ColorChoice { id: listTextColorChoice }

            Label {
                text: i18n("List Highlight:")
                Layout.alignment: Qt.AlignRight
            }
            ColorChoice { id: highlightColorChoice }
        }
    }
}
