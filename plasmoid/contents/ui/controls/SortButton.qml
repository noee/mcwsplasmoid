import QtQuick 2.12
import QtQuick.Controls 2.12
import org.kde.plasma.components 3.0 as PComp
import '../models'

PComp.ToolButton {
    id: sorter
    icon.name: "playlist-sort"

    property bool showSort: true
    // sort menu is derived from fields in the searcher model
    // sort role stored in Searcher::sortField
    property Searcher target

    onClicked: sortMenu.popup()

    text: showSort
          ? sorter.target ? sorter.target.sortField : ''
          : ''
    hoverEnabled: true

    ToolTip {
        text: 'Sort Tracks'
    }

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
