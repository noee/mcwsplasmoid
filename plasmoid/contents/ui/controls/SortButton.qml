import QtQuick 2.8
import org.kde.plasma.components 2.0 as PlasmaComponents
import Qt.labs.platform 1.0
import '../code/utils.js' as Utils

Item {
    id: sorter
    width: button.width
    height: button.height

    property var model
    property var onSortDone

    onModelChanged: {
        // cleanup/clear the menu items
        for (var i=0; i < sortMenu.items.length; ++i)
            sortMenu.items[i].destroy(500)
        sortMenu.clear()

        // add no sort option
        sortMenu.addItem(mi.createObject(sortMenu, { group: mg, text: i18n('No Sort') }))
        sortMenu.addItem(sep.createObject(sortMenu))

        // build the sort field menu, check the sort field menu item
        if (model) {
            var found = false
            model.mcwsSortFields.forEach(function(fld) {
                var i = mi.createObject(sortMenu, { group: mg, text: i18n(fld) })
                if (Utils.toRoleName(fld) === model.sortField)
                    i.checked = found = true
                sortMenu.addItem(i)
            })

            if (!found)
                sortMenu.items[0].checked = true
        }
    }

    PlasmaComponents.ToolButton {
        id: button
        iconSource: "sort-name"
        flat: false
        onClicked: sortMenu.open()
        anchors.fill: parent
    }

    Component {
        id: mi
        MenuItem {
            checkable: true
        }
    }
    Component {
        id: sep
        MenuSeparator {}
    }
    Menu {
        id: sortMenu

        MenuItemGroup {
            id: mg
            onTriggered: {
                sorter.model.sortField = item.text === 'No Sort' ? '' : Utils.toRoleName(item.text)

                if (typeof onSortDone === 'function')
                    onSortDone()
            }
        }
    }

}
