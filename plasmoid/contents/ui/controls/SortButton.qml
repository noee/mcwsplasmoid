import QtQuick 2.8
import QtQuick.Controls 2.5
import Qt.labs.platform 1.0
import '../models'

Item {
    id: sorter
    implicitWidth: button.width
    implicitHeight: button.height

    property bool showSort: true
    property Searcher model

    // sort menu is derived from fields in the model
    // lazy load when model is set
    // undefined model clears the menu
    onModelChanged: {
        if (model === undefined) {
            for (var i=0, len=sortMenu.items.length; i<len ; ++i) {
                sortMenu.items[i].destroy(100)
            }
            sortMenu.clear()
        } else {
            if (sortMenu.items.length === 0) {
                model.mcwsSortFields.forEach(
                    (fld) => { sortMenu.addItem(mi.createObject(sortMenu, { text: i18n(fld) })) })
            }
            // each model constains it's "sort"
            // so initialize the menu after each model change
            for (let i=0, len=sortMenu.items.length; i<len ; ++i) {
                sortMenu.items[i].checked = sortMenu.items[i].text === model.sortField
            }
        }
    }

    Button {
        id: button
        icon.name: "playlist-sort"
        onClicked: sortMenu.open()

        text: showSort
              ? sorter.model ? sorter.model.sortField : ''
              : ''
        hoverEnabled: true

        ToolTip.text: 'Sort Tracks'
        ToolTip.visible: hovered
        ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval

        Menu {
            id: sortMenu

            MenuItemGroup {
                id: mg
                onTriggered: {
                    sorter.model.sortField = item.checked ? item.text : ''
                }
            }
        }
    }

    Component {
        id: mi
        MenuItem {
            group: mg
            checkable: true
        }
    }
}
