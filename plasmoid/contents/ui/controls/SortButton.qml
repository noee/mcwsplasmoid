import QtQuick 2.8
import QtQuick.Controls 2.5
import '../models'

Item {
    id: sorter
    implicitWidth: button.width
    implicitHeight: button.height

    property bool showSort: true
    // sort menu is derived from fields in the searcher model
    // sort role stored in Searcher::sortField
    property Searcher target

    ToolButton {
        id: button
        icon.name: "playlist-sort"
        onClicked: sortMenu.popup()

        text: showSort
              ? sorter.target ? sorter.target.sortField : ''
              : ''
        hoverEnabled: true

        ToolTip.text: 'Sort Tracks'
        ToolTip.visible: hovered
        ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval

        Menu {
            id: sortMenu

            MenuItem {
                text: 'No Sort'
                checkable: true
                autoExclusive: true
                checked: sorter.target
                         ? sorter.target.sortField === ""
                         : true
                onTriggered: sorter.target.sortField = ""
            }

            Repeater {
                model: target ? target.mcwsFields : ''
                delegate: MenuItem {
                    text: field
                    visible: sortable
                    autoExclusive: true
                    checkable: true
                    checked: text === sorter.target.sortField
                    onTriggered: sorter.target.sortField = text
                }
            }

        }
    }

}
