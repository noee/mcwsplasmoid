import QtQuick 2.8
import org.kde.plasma.components 2.0 as PlasmaComponents
import Qt.labs.platform 1.0

Item {
    id: sorter
    width: button.width
    height: button.height

    property var model
    property var onSortDone

    onModelChanged: {
        sortMenu.clear()
        model.mcwsFieldList.forEach(function(fld) {
            sortMenu.addItem(mi.createObject(sortMenu, { text: i18n(fld) }))
        })
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
    Menu {
        id: sortMenu

        MenuItemGroup {
            items: sortMenu.items
            onTriggered: {
                sorter.model.sortField = item.text.replace(/ /g, '').toLowerCase()
                if (onSortDone)
                    onSortDone()
            }
        }
    }

}
