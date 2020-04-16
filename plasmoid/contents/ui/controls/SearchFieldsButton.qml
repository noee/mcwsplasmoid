import QtQuick 2.8
import QtQuick.Controls 2.5
import '../models'

Item {
    implicitWidth: button.width
    implicitHeight: button.height

    // fields menu is derived from fields in the searcher model
    property Searcher sourceModel

    Button {
        id: button
        icon.name: "question"
        onClicked: fieldsMenu.open()

        hoverEnabled: true

        ToolTip.text: 'Choose Search Fields'
        ToolTip.visible: hovered
        ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval

        Menu {
            id: fieldsMenu

            Repeater {
                model: sourceModel ? sourceModel.searchFieldActions : null
                delegate: MenuItem {
                    action: modelData
                }
            }

        }
    }

}
