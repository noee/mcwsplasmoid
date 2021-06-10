import QtQuick 2.8
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.8 as Kirigami
import "../helpers"

ColumnLayout {
    property alias cfg_defaultFields: lm.outputStr

    // defn: { "field": "Name", "sortable": true, "searchable": true, "mandatory": true }
    ConfigListModel {
        id: lm
        configKey: 'defaultFields'
    }

    Component {
        id: itemDelegate

        Kirigami.SwipeListItem {
            id: swipelistItem

            onClicked: fields.currentIndex = index

            RowLayout {
                //FIXME: If not used within DelegateRecycler, item goes on top of the first item when clicked
                Kirigami.ListItemDragHandle {
                    implicitWidth: Kirigami.Units.iconSizes.medium
                    listItem: swipelistItem
                    listView: fields
                    onMoveRequested: lm.items.move(oldIndex, newIndex, 1)
                }

                Label {
                    text: field
                    Layout.fillWidth: true
                }

                CheckBox {
                    text: 'Sortable'
                    checked: sortable
                    onClicked: {
                        lm.items.setProperty(index, 'sortable', checked)
                        lm.items.save()
                    }
                }

                CheckBox {
                    text: 'Searchable'
                    checked: searchable
                    onClicked: {
                        lm.items.setProperty(index, 'searchable', checked)
                        lm.items.save()
                    }
                }


            }
            actions: [
                Kirigami.Action {
                    enabled: !mandatory
                    iconName: mandatory ? 'folder-locked' : 'delete'
                    onTriggered: lm.items.remove(index)
                }
            ]

        }
    }

    ListView {
        id: fields
        model: lm.items
        clip: true
        spacing: 0
        Layout.fillHeight: true
        Layout.fillWidth: true

        moveDisplaced: Transition {
            YAnimator {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }

        delegate: Kirigami.DelegateRecycler {
            width: fields.width
            sourceComponent: itemDelegate
        }
    }
}
