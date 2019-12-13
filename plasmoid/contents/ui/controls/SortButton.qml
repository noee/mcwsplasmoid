import QtQuick 2.8
import QtQuick.Controls 2.5
import Qt.labs.platform 1.0
import '../helpers/utils.js' as Utils

Item {
    id: sorter
    implicitWidth: button.width
    implicitHeight: button.height

    property var model

    signal start()
    signal finish()

    // sort menu is derived from fields in the model
    onModelChanged: {
        // cleanup/clear the menu items
        for (var i=0; i < sortMenu.items.length; ++i)
            sortMenu.items[i].destroy()
        sortMenu.clear()

        // build the sort field menu, check the sort field menu item
        event.queueCall(() => {
                            if (model) {

                                model.sortBegin.connect(start)
                                model.sortDone.connect(finish)

                                model.mcwsSortFields.forEach(function(fld) {
                                    var i = mi.createObject(sortMenu, { text: i18n(fld) })
                                    if (Utils.toRoleName(fld) === model.sortField)
                                        i.checked = true
                                    sortMenu.addItem(i)
                                })
                            }
                        })
    }

    Button {
        id: button
        icon.name: "playlist-sort"
        onClicked: sortMenu.open()

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
