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

    onTargetChanged: {
        if (_sortMenu) {
            _sortMenu.destroy()
            _sortMenu = null
        }
    }

    property PComp.Menu _sortMenu

    onClicked: {
        if (!_sortMenu) {
            _sortMenu = menuComp.createObject(sorter)
            target.mcwsFields.forEach(f => {
                if (f.sortable)
                    _sortMenu.addItem(mi.createObject(sorter, {text: f.field}))
            })
        }
        _sortMenu.popup()
    }

    text: showSort
          ? sorter.target ? sorter.target.sortField : ''
          : ''
    hoverEnabled: true

    PComp.ToolTip {
        text: 'Sort Tracks'
    }

    Component {
        id: menuComp

        PComp.Menu {

            PComp.MenuItem {
                text: 'No Sort'
                checkable: true
                autoExclusive: true
                checked: sorter.target
                         ? sorter.target.sortField === ""
                         : true
                onTriggered: sorter.target.sortField = ""
            }
        }
    }

    Component {
        id: mi

        PComp.MenuItem {
            autoExclusive: true
            checkable: true
            checked: text === sorter.target.sortField
            onTriggered: sorter.target.sortField = text
        }
    }
}
