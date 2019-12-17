import QtQuick 2.8
import QtQuick.Controls 2.5
import '../models'

Item {
    id: sorter
    implicitWidth: button.width
    implicitHeight: button.height

    property bool showSort: true
    // sort menu is derived from fields in the searcher model
    property Searcher sourceModel

    Button {
        id: button
        icon.name: "playlist-sort"
        onClicked: sortMenu.open()

        text: showSort
              ? sorter.sourceModel ? sorter.sourceModel.sortField : ''
              : ''
        hoverEnabled: true

        ToolTip.text: 'Sort Tracks'
        ToolTip.visible: hovered
        ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval

        Menu {
            id: sortMenu

            Repeater {
                model: sourceModel ? sourceModel.sortActions : null
                delegate: MenuItem {
                    action: modelData
                    autoExclusive: true
                }
            }

        }
    }

}
